export branchandbound_carlier




"""
    branchandbound_carlier(
        instance::JobShopInstance;
        yielding::Bool = false,
        with_dpc::Bool = false,
        with_priority_queue::Bool = false,
        io_print_best_node::Union{IO, Nothing} = nothing,
        heuristic_UB::Bool = false
    )

Branch and Bound algorithm for the Job Shop Scheduling problem `J || Cmax` with no recirculation.

# Arguments
- `instance::JobShopInstance`: A job shop instance.
- `yielding::Bool=false`: If `true`, the algorithm will yield after each iteration. This is useful for timeouting the algorithm.
- `with_dpc::Bool=true`: If `true`, the algorithm will use the DPC algorithm to find the longest path in the graph. Otherwise, the algorithm will use the Carlier algorithm.
- `with_priority_queue::Bool=true`: If `true`, the algorithm will use a priority queue to find the node in Carlier algorithm. Otherwise, it will use a simple stack.
- `io_print_best_node::Union{IO, Nothing} = nothing`: If not `nothing`, the algorithm will print the best node found so far to the given IO.
- `heuristic_UB::Bool=false`: If `true`, the algorithm will use the Shifting Bottleneck algorithm to find the upper bound of the solution.
# Returns
- `ShopSchedule`: A ShopSchedule object representing the solution to the job shop problem.
"""
function branchandbound_carlier(
    instance::JobShopInstance;
    yielding::Bool = false,
    with_dpc::Bool = false,
    with_priority_queue::Bool = false,
    io_print_best_node::Union{IO, Nothing} = nothing,
    heuristic_UB::Bool = false
)
    _ , timeSeconds, bytes = @timed begin 

    # dane do statystyk
    yield_ref = yielding ? Ref(time()) : nothing
    microruns = 0
    metadata = Dict{String, Any}()
    start_time = time()
    algorithm_name = "Branch and Bound" * (with_dpc ? " - DPC" : " - Carlier") * (with_priority_queue ? "" : " with stack") * (with_heuristic_UB ? " with heuristic UB" : "")
    skippedNodes = 0
    terminalNodes = 0
    nodesGenerated = 0

    # algorytm Branch and Bound
    # pomocnicze tablice
    n, m, n_i, p, μ = instance.n, instance.m, instance.n_i, instance.p, instance.μ
    jobToGraphNode, graphNodeToJob, machineJobs, _ = generate_util_arrays(n, m, n_i, μ)
    upperBound = typemax(Int64)
    if heuristic_UB
        result = if job_recirculation()(instance)
            shiftingbottleneckcarlier(instance; yielding = yielding, with_dpc = false, with_priority_queue = with_priority_queue)
        else
            shiftingbottleneckcarlier(instance; yielding = yielding, with_dpc = true, with_priority_queue = with_priority_queue)
        end
        if result isa ShopSchedule
            upperBound = result.objectiveValue
        else
            metadata["calculatedUBerror"] = true
        end
    end
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

    

    test = -9
    while !isempty(S)
        node = pop!(S)


        try_yield(yield_ref)
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
        if node.lowerBound >= upperBound
            skippedNodes += 1
            continue
        end
        # wygeneruj zbiór Ω_prim, czyli zbiór operacji, które mogą być zaplanowane w tym węźle
        # najpierw obliczamy t(Ω) = min{r_ij + p_ij : (i,j) ∈ Ω}, i wybieramy maszynę i* dla której to minimum jest osiągane
        # następnie wybieramy zbiór Ω_prim = {(i,j) ∈ Ω : r_ij < t(Ω) ∧ μ_ij = i*}
        Ω_prim = generateΩ_prim(node, p, μ)
        listOfNodes = []
        for selectedOperation in Ω_prim
            nodesGenerated += 1
            newNode = ActiveScheduleNode(
                filter(a -> a != selectedOperation, node.Ω),
                node.lowerBound,
                deepcopy(node.graph),
                deepcopy(node.scheduled),
                deepcopy(node.r)
            )
            newNode.scheduled[selectedOperation] = true
            # jeśli są jeszcze następna operacja w tym samym zadaniu, to dodajemy ją do zbioru Ω
            if selectedOperation[2] < n_i[selectedOperation[1]]
                push!(newNode.Ω, (selectedOperation[1], selectedOperation[2] + 1))
            end
            try_yield(yield_ref)
            
            # dodajemy krawędzie do grafu z selectedOperation do innych operacji z tej maszyny
            for operation in machineJobs[μ[selectedOperation[1]][selectedOperation[2]]]
                if !(get!(newNode.scheduled, operation, false))
                    add_edge!(newNode.graph, jobToGraphNode[selectedOperation[1]][selectedOperation[2]], jobToGraphNode[operation[1]][operation[2]], p[selectedOperation[1]][selectedOperation[2]])
                end
            end
            disjunctiveGraph = DisjunctiveWeightedGraph(conjuctiveGraph, newNode.graph)
            newNode.r, rGraph = generate_release_times(disjunctiveGraph, n_i, graphNodeToJob)
            path_from_sink = if with_dpc
                nothing
            else
                generate_paths_sink(disjunctiveGraph, n_i, graphNodeToJob)[1]
            end
            longestPathLowerBound = rGraph[sum(n_i)+2]
            # obliczamy dolną granicę dla tego węzła, obliczając najdłuższą ścieżkę w grafie z źródła do ujścia
            newNode.lowerBound = max(newNode.lowerBound, longestPathLowerBound)
            lowerBoundCandidate = newNode.lowerBound
            
            # poprawiamy dolną granicę, za pomocą algorytmu DPC
            
            for machineNumber in 1:m
                try
                    if with_dpc
                        CmaxCandidate, _, new_microruns = generate_sequence_dpc(instance, newNode.r, machineJobs, jobToGraphNode, disjunctiveGraph, machineNumber, yield_ref; with_priority_queue = with_priority_queue)
                        microruns += new_microruns
                    else
                        CmaxCandidate, _, new_microruns = generate_sequence_carlier(instance, newNode.r, path_from_sink, machineJobs, machineNumber, yield_ref; with_priority_queue = with_priority_queue)
                        microruns += new_microruns
                    end
                    lowerBoundCandidate = max(CmaxCandidate, lowerBoundCandidate)
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
        algorithm = "Branch and Bound" * (with_dpc ? " - DPC" : " - Carlier") * (with_priority_queue ? "" : " with stack"),
        microruns = microruns,
        timeSeconds = timeSeconds,
        memoryBytes = bytes,
        metadata = metadata
    )
end






