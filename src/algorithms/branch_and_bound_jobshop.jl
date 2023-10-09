export generate_active_schedules
import Graphs.add_edge!

mutable struct ActiveScheduleNode
    Ω::Vector{Tuple{Int,Int}}
    lowerBound::Union{Int64,Nothing}
    graph::AbstractGraph
    scheduled::Dict{Tuple{Int64,Int64},Bool}
    r::Vector{Vector{Int64}}
end

"""
    generate_active_schedules(instance::JobShopInstance; suppress_warnings::Bool = false)

Branch and Bound algorithm for the Job Shop Scheduling problem `J || Cmax` with no recirculation.

# Arguments
- `instance::JobShopInstance`: A job shop instance.
- `suppress_warnings::Bool=false`: If `true`, warnings will not be printed.

# Returns
- `ShopSchedule`: A ShopSchedule object representing the solution to the job shop problem.
"""
function generate_active_schedules(
   
    instance::JobShopInstance;
    suppress_warnings::Bool = false
)
    _ , timeSeconds, bytes = @timed begin 
    n, m, n_i, p, μ = instance.n, instance.m, instance.n_i, instance.p, instance.μ
    (job_recirculation()(instance) && !suppress_warnings) && @warn("The generate_active_schedules algorithm can only be used for job shop problems with no recirculation.")
    microruns = 0
    # algorytm Branch and Bound

    # pomocnicze tablice
    jobToGraphNode, graphNodeToJob, machineJobs, _ = generate_util_arrays(n, m, n_i, μ)
    upperBound = typemax(Int64)
    selectedNode::Union{ActiveScheduleNode,Nothing} = nothing
    S = Stack{ActiveScheduleNode}()
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
            if node.lowerBound <= upperBound
                upperBound = node.lowerBound
                selectedNode = node
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
            
            # poprawiamy dolną granicę, za pomocą algorytmu 1|R_j|Lmax dla każdej maszyny
            for machineNumber in 1:m
                LmaxCandidate, _ = generate_sequence(p, newNode.r, n_i, machineJobs, jobToGraphNode, newNode.graph, newNode.lowerBound, machineNumber)
                lowerBoundCandidate = max(newNode.lowerBound + LmaxCandidate, lowerBoundCandidate)
            end
            newNode.lowerBound = lowerBoundCandidate
            push!(listOfNodes, newNode)
        end
        # filtrujemy węzły, które mają dolną granicę większą niż obecna górna granica algorytmu
        # i sortujemy je po dolnej granicy, zaczynamy od najbardziej obiecujących kandydatów
        sort!(listOfNodes, by=x -> x.lowerBound)
        filter!(x -> x.lowerBound < upperBound, listOfNodes)
        skippedNodes += (length(Ω_prim) - length(listOfNodes))
        for nodeToPush in Iterators.reverse(listOfNodes)
            push!(S, nodeToPush)
        end
    end
    end
    return ShopSchedule(
        instance,
        selectedNode.r + p,
        maximum(maximum.(selectedNode.r + p)),
        Cmax_function;
        algorithm = "Branch and Bound",
        microruns = microruns,
        timeSeconds = timeSeconds,
        memoryBytes = bytes
    )
end

function generateΩ_prim(node::ActiveScheduleNode, p::Vector{Vector{Int}}, μ::Vector{Vector{Int}})
    minimum, index = findmin(a -> p[a[1]][a[2]] + node.r[a[1]][a[2]], node.Ω)
    i, j = node.Ω[index]
    i_star = μ[i][j]
    Ω_prim = filter(a -> (node.r[a[1]][a[2]] < minimum && μ[a[1]][a[2]] == i_star), node.Ω)
    return Ω_prim
end




