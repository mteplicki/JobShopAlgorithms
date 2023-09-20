mutable struct ActiveScheduleNode
    Ω::Vector{Tuple{Int,Int}}
    lowerBound::Union{Int64,Nothing}
    graph::AbstractGraph
    scheduled::Dict{Tuple{Int64,Int64},Bool}
    r::Vector{Vector{Int64}}
end

generateActiveSchedules(instance::JobShopInstance) = generateActiveSchedules(instance.n, instance.m, instance.n_i, instance.p, instance.μ)

function generateActiveSchedules(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    # nonrepetitive
    all(sort(collect(Set(x))) == sort(x) for x in μ) || throw(ArgumentError("μ must be nonrepetitive"))

    jobToGraphNode, graphNodeToJob, machineJobs, _ = generateUtilArrays(n, m, n_i, μ)
    upperBound = typemax(Int64)
    selectedNode::Union{ActiveScheduleNode,Nothing} = nothing
    S = Stack{ActiveScheduleNode}()
    graph = generateConjuctiveGraph(n, n_i, p, jobToGraphNode)

    node = ActiveScheduleNode(
        [(i, 1) for i = 1:n],
        nothing,
        graph,
        Dict{Tuple{Int64,Int64},Bool}(),
        [[0 for _ in 1:a] for a in n_i]
    )

    node.r, rGraph = generateReleaseTimes(node.graph, n_i, graphNodeToJob)
    node.lowerBound = rGraph[sum(n_i)+2]
    push!(S, node)
    while !isempty(S)
        node = pop!(S)
        if isempty(node.Ω)
            if node.lowerBound < upperBound
                upperBound = node.lowerBound
                selectedNode = node
            end
            continue
        end

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
            if selectedOperation[2] < n_i[selectedOperation[1]]
                push!(newNode.Ω, (selectedOperation[1], selectedOperation[2] + 1))
            end

            for operation in machineJobs[μ[selectedOperation[1]][selectedOperation[2]]]
                if !(get!(newNode.scheduled, operation, false))
                    add_edge!(newNode.graph, jobToGraphNode[selectedOperation[1]][selectedOperation[2]], jobToGraphNode[operation[1]][operation[2]], p[selectedOperation[1]][selectedOperation[2]])
                end
            end
            newNode.r, rGraph = generateReleaseTimes(newNode.graph, n_i, graphNodeToJob)
            longestPathLowerBound = rGraph[sum(n_i)+2]
            newNode.lowerBound = max(newNode.lowerBound, longestPathLowerBound)
            lowerBoundCandidate = newNode.lowerBound
            for machineNumber in 1:m
                LmaxCandidate, _ = generateSequence(p, newNode.r, n_i, machineJobs, jobToGraphNode, newNode.graph, newNode.lowerBound, machineNumber)
                lowerBoundCandidate = max(newNode.lowerBound + LmaxCandidate, lowerBoundCandidate)
            end
            newNode.lowerBound = lowerBoundCandidate
            push!(listOfNodes, newNode)
        end
        sort!(listOfNodes, by=x -> x.lowerBound)
        filter!(x -> x.lowerBound ≤ upperBound, listOfNodes)
        for nodeToPush in Iterators.reverse(listOfNodes)
            push!(S, nodeToPush)
        end

    end
    return ShopSchedule(
        JobShopInstance(n, m, n_i, p, μ),
        selectedNode.r + p,
        maximum(maximum.(selectedNode.r + p))
    )
end

function generateΩ_prim(node::ActiveScheduleNode, p::Vector{Vector{Int}}, μ::Vector{Vector{Int}})
    minimum, index = findmin(a -> p[a[1]][a[2]] + node.r[a[1]][a[2]], node.Ω)
    i, j = node.Ω[index]
    i_star = μ[i][j]
    Ω_prim = filter(a -> (node.r[a[1]][a[2]] < minimum && μ[a[1]][a[2]] == i_star), node.Ω)
    return Ω_prim
end




