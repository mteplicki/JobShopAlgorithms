export generate_active_schedules_dpc




"""
    generate_active_schedules(instance::JobShopInstance; suppress_warnings::Bool = false)

Branch and Bound algorithm for the Job Shop Scheduling problem `J || Cmax` with no recirculation.

# Arguments
- `instance::JobShopInstance`: A job shop instance.
- `suppress_warnings::Bool=false`: If `true`, warnings will not be printed.

# Returns
- `ShopSchedule`: A ShopSchedule object representing the solution to the job shop problem.
"""
function generate_active_schedules_dpc(
    instance::JobShopInstance;

)
    _ , timeSeconds, bytes = @timed begin 
    n, m, n_i, p, μ = instance.n, instance.m, instance.n_i, instance.p, instance.μ
    microruns = 0
    # algorytm Branch and Bound
    # pomocnicze tablice
    jobToGraphNode, graphNodeToJob, machineJobs, _ = generate_util_arrays(n, m, n_i, μ)
    upperBound = typemax(Int64)
    selectedNode::Union{ActiveScheduleNode,Nothing} = nothing
    S = ActiveScheduleNode[]
    graph = generate_conjuctive_graph(n, n_i, p, jobToGraphNode)

    node = ActiveScheduleNode(
        [(i, 1) for i = 1:n],
        nothing,
        graph,
        Dict{Tuple{Int64,Int64},Bool}(),
        [[0 for _ in 1:a] for a in n_i]
    )

    node.r, rGraph = generate_release_times(node.graph, n_i, graphNodeToJob)
    node.lowerBound = rGraph[sum(n_i)+2]
    push!(S, node)
    skippedNodes = 0
    terminalNodes = 0
    while !isempty(S)
        node = pop!(S)
        # jeżli wszystkie operacje zostały zaplanowane, to sprawdzamy, czy wartość tego węzła jest mniejsza niż obecna górna granica algorytmu
        if isempty(node.Ω)
            terminalNodes += 1
            # println("terminal node, lowerBound: $(node.lowerBound), upperBound: $upperBound")
            node.r, rGraph = generate_release_times(node.graph, n_i, graphNodeToJob)
            makespan = rGraph[sum(n_i)+2]
            if makespan < upperBound
                upperBound = makespan
                selectedNode = node
            end
            continue
        end
        if node.lowerBound >= upperBound
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
            newNode.r, rGraph = generate_release_times(newNode.graph, n_i, graphNodeToJob)
            longestPathLowerBound = rGraph[sum(n_i)+2]
            # obliczamy dolną granicę dla tego węzła, obliczając najdłuższą ścieżkę w grafie z źródła do ujścia
            newNode.lowerBound = max(newNode.lowerBound, longestPathLowerBound)
            lowerBoundCandidate = newNode.lowerBound
            
            # poprawiamy dolną granicę, za pomocą algorytmu DPC
            for machineNumber in 1:m
                Cmaxcandidate, _ , new_microruns = generate_sequence_dpc(p, newNode.r, n_i, machineJobs, jobToGraphNode, newNode.graph, newNode.lowerBound, machineNumber)
                println("Cmaxcandidate: $Cmaxcandidate, lowerBoundCandidate: $lowerBoundCandidate, machineNumber: $machineNumber")
                microruns += new_microruns
                lowerBoundCandidate = max(Cmaxcandidate, lowerBoundCandidate)
            end
            newNode.lowerBound = lowerBoundCandidate
            push!(listOfNodes, newNode)
        end
        # filtrujemy węzły, które mają dolną granicę większą niż obecna górna granica algorytmu
        # i sortujemy je po dolnej granicy, zaczynamy od najbardziej obiecujących kandydatów
        filter!(x -> x.lowerBound < upperBound, listOfNodes)
        sort!(listOfNodes, by=x -> x.lowerBound, rev=true)
        skippedNodes += (length(Ω_prim) - length(listOfNodes))
        append!(S, listOfNodes)
    end
    end
    return ShopSchedule(
        instance,
        selectedNode.r + p,
        maximum(maximum.(selectedNode.r + p)),
        Cmax_function;
        algorithm = "Branch and Bound - DPC",
        microruns = microruns,
        timeSeconds = timeSeconds,
        memoryBytes = bytes
    )
end






