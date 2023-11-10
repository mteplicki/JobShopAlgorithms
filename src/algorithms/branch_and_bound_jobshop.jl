export branchandbound




"""
    branchandbound(
        instance::JobShopInstance;
        bounding_algorithm::Symbol=:no_pmtn,
        yielding::Bool=false,
        io_print_best_node::Union{IO, Nothing} = nothing
    )

Branch and Bound algorithm for the Job Shop Scheduling problem `J | rcrc | Cmax` with recirculation.

# Arguments
- `instance::JobShopInstance`: A job shop instance.
- `bounding_algorithm::Symbol=:no_pmtn`: Algorithm used to bound the lower bound of the solution. Possible values are `:no_pmtn` for `1 | r_j | Lmax` and `:pmtn` for `1 | r_j, pmtn | Lmax`. Default value is `:no_pmtn`.
- `yielding::Bool=false`: If `true`, the algorithm will yield after each iteration. This is useful for timeouting the algorithm.
- `io_print_best_node::Union{IO, Nothing} = nothing`: If not `nothing`, the algorithm will print the best node found so far to the given IO.
# Returns
- `ShopSchedule`: A ShopSchedule object representing the solution to the job shop problem.
"""
function branchandbound(
    instance::JobShopInstance;
    bounding_algorithm::Symbol=:no_pmtn,
    yielding::Bool = false,
    io_print_best_node::Union{IO, Nothing} = nothing
)
    _ , timeSeconds, bytes = @timed begin 

    # dane do statystyk
    n, m, n_i, p, μ = instance.n, instance.m, instance.n_i, instance.p, instance.μ
    microruns = 0
    yield_ref = yielding ? Ref(time()) : nothing
    skippedNodes = 0
    terminalNodes = 0
    nodesGenerated = 0
    metadata = Dict{String, Any}()
    start_time = time()
    algorithm_name = "Branch and Bound - " * (bounding_algorithm == :pmtn ? String("1|r_j, pmtn|Lmax") : String("1|R_j|Lmax"))

    # algorytm Branch and Bound
    # pomocnicze tablice
    if bounding_algorithm ≠ :pmtn && bounding_algorithm ≠ :no_pmtn
        throw(ArgumentError("bounding_algorithm must be either :pmtn or :no_pmtn"))
    end
    jobToGraphNode, graphNodeToJob, machineJobs, _ = generate_util_arrays(n, m, n_i, μ)
    upperBound = typemax(Int64)
    selectedNode::Union{ActiveScheduleNode,Nothing} = nothing
    S = Stack{ActiveScheduleNode}()
    conjuctiveGraph = generate_conjuctive_graph(n, n_i, p, jobToGraphNode)

    node = ActiveScheduleNode(
        [(i, 1) for i = 1:n],
        nothing,
        SimpleDiWeightedGraphAdj(sum(n_i) + 2, Int),
        Dict{Tuple{Int64,Int64},Bool}(),
        [[0 for _ in 1:a] for a in n_i]
    )
    nodesGenerated += 1

    disjunctiveGraph = DisjunctiveWeightedGraph(conjuctiveGraph, node.graph)
    node.r, rGraph = generate_release_times(disjunctiveGraph, n_i, graphNodeToJob)
    node.lowerBound = rGraph[sum(n_i)+2]
    push!(S, node)
    
    while !isempty(S)
        try_yield(yield_ref)
        node = pop!(S)
        if node.lowerBound >= upperBound
            skippedNodes += 1
            continue
        end
        # jeżli wszystkie operacje zostały zaplanowane, to sprawdzamy, czy wartość tego węzła jest mniejsza niż obecna górna granica algorytmu
        if isempty(node.Ω)
            terminalNodes += 1
            disjunctiveGraph = DisjunctiveWeightedGraph(conjuctiveGraph, node.graph)
            node.r, rGraph = generate_release_times(disjunctiveGraph, n_i, graphNodeToJob)
            makespan = rGraph[sum(n_i)+2]
            if makespan < upperBound
                upperBound = makespan
                selectedNode = node
                !isnothing(io_print_best_node) && println(io_print_best_node, "$(instance.name),$algorithm_name,$upperBound,$(time() - start_time),$(length(S)),$(terminalNodes),$(skippedNodes),$(selectedNode.r + p)")
            end
            continue
        end
        # wygeneruj zbiór Ω_prim, czyli zbiór operacji, które mogą być zaplanowane w tym węźle
        # najpierw obliczamy t(Ω) = min{r_ij + p_ij : (i,j) ∈ Ω}, i wybieramy maszynę i* dla której to minimum jest osiągane
        # następnie wybieramy zbiór Ω_prim = {(i,j) ∈ Ω : r_ij < t(Ω) ∧ μ_ij = i*}
        Ω_prim = generateΩ_prim(node, p, μ)
        listOfNodes = []
        for selectedOperation in Ω_prim
            newNode = ActiveScheduleNode(
                filter(a -> a != selectedOperation, node.Ω),
                node.lowerBound,
                deepcopy(node.graph),
                deepcopy(node.scheduled),
                deepcopy(node.r)
            )
            nodesGenerated += 1
            newNode.scheduled[selectedOperation] = true
            # jeśli są jeszcze następna operacja w tym samym zadaniu, to dodajemy ją do zbioru Ω
            if selectedOperation[2] < n_i[selectedOperation[1]]
                push!(newNode.Ω, (selectedOperation[1], selectedOperation[2] + 1))
            end
            
            # dodajemy krawędzie do grafu z selectedOperation do innych operacji z tej maszyny
            for operation in machineJobs[μ[selectedOperation[1]][selectedOperation[2]]]
                if !(get!(newNode.scheduled, operation, false))
                    add_edge!(newNode.graph, jobToGraphNode[selectedOperation[1]][selectedOperation[2]], jobToGraphNode[operation[1]][operation[2]], p[selectedOperation[1]][selectedOperation[2]])
                end
            end
            disjunctiveGraph = DisjunctiveWeightedGraph(conjuctiveGraph, newNode.graph)
            newNode.r, rGraph = generate_release_times(disjunctiveGraph, n_i, graphNodeToJob)
            path_from_sink = generate_paths_sink(disjunctiveGraph, n_i, graphNodeToJob)[1]
            longestPathLowerBound = rGraph[sum(n_i)+2]
            
            # obliczamy dolną granicę dla tego węzła, obliczając najdłuższą ścieżkę w grafie z źródła do ujścia
            newNode.lowerBound = max(newNode.lowerBound, longestPathLowerBound)
            lowerBoundCandidate = newNode.lowerBound
            
            # poprawiamy dolną granicę, za pomocą algorytmu 1|R_j|Lmax dla każdej maszyny
            # lub gdy machine_repetition == true, to za pomocą algorytmu 1|r_j, pmtn|Lmax
            for machineNumber in 1:m
                try
                    if bounding_algorithm == :pmtn
                        LmaxCandidate, _ = generate_sequence_pmtn(instance, newNode.r, path_from_sink, machineJobs, newNode.lowerBound, machineNumber, yield_ref)
                        microruns += 1
                    else
                        LmaxCandidate, _, new_microruns = generate_sequence(instance, newNode.r, path_from_sink, machineJobs, newNode.lowerBound, machineNumber, yield_ref)
                        microruns += new_microruns
                    end
                    lowerBoundCandidate = max(newNode.lowerBound + LmaxCandidate, lowerBoundCandidate)
                catch error
                    if error isa DimensionMismatch
                        continue
                    else
                        rethrow()
                    end
                end
            end
            newNode.lowerBound = lowerBoundCandidate
            push!(listOfNodes, newNode)
        end
        # filtrujemy węzły, które mają dolną granicę większą niż obecna górna granica algorytmu
        # i sortujemy je po dolnej granicy, zaczynamy od najbardziej obiecujących kandydatów
        filter!(x -> x.lowerBound < upperBound, listOfNodes)
        sort!(listOfNodes, by=x -> x.lowerBound, rev=true)
        skippedNodes += (length(Ω_prim) - length(listOfNodes))
        for newNode1 in listOfNodes
            push!(S, newNode1)
        end
    end
    metadata["nodesGenerated"] = nodesGenerated
    metadata["terminalNodes"] = terminalNodes
    metadata["skippedNodes"] = skippedNodes
    end
    return ShopSchedule(
        instance,
        selectedNode.r + p,
        maximum(maximum.(selectedNode.r + p)),
        Cmax_function;
        algorithm = algorithm_name,
        microruns = microruns,
        timeSeconds = timeSeconds,
        memoryBytes = bytes,
        metadata = metadata
    )
end






