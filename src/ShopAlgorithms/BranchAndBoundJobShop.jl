mutable struct ActiveScheduleNode
    Ω::Vector{Tuple{Int,Int}}
    lowerBound::Union{Int64, Nothing}
    graph::AbstractGraph
    scheduled::Dict{Tuple{Int64,Int64}, Bool}
    r::Vector{Vector{Int64}}
end

function generateActiveSchedules(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    jobToGraphNode::Vector{Vector{Int}} = [[0 for _ in 1:n_i[i]] for i in 1:n]
    graphNodeToJob::Vector{Tuple{Int,Int}} = [(0,0) for _ in 1:(sum(n_i) + 2)]
    machineJobs::Vector{Vector{Tuple{Int,Int}}} = [[] for _ in 1:m]
    
    counter = 2
    for i in 1:n
        for j in 1:n_i[i]
            jobToGraphNode[i][j] = counter
            graphNodeToJob[counter] = (i,j)
            push!(machineJobs[μ[i][j]], (i,j))
            counter += 1
        end
    end
    upperBound = typemax(Int64)
    selectedNode::Union{ActiveScheduleNode, Nothing} = nothing
    S = Stack{ActiveScheduleNode}()
    graph = SimpleWeightedGraphAdj(sum(n_i)+2, Int)
    
    for i in 1:n
        add_edge!(graph, 1, jobToGraphNode[i][1], 0)
        for j in 1:(n_i[i] - 1)
            add_edge!(graph, jobToGraphNode[i][j], jobToGraphNode[i][j+1], p[i][j])
        end
        add_edge!(graph, jobToGraphNode[i][n_i[i]], sum(n_i)+2, p[i][n_i[i]])
    end

    node = ActiveScheduleNode(
        [(i,1) for i=1:n], 
        nothing,
        graph,
        Dict{Tuple{Int64,Int64}, Bool}(),
        [[0 for _ in 1:a] for a in n_i]
        )

    node.r, rGraph = generateReleaseTimes(node.graph, n_i, graphNodeToJob)
    node.lowerBound = rGraph[sum(n_i)+2]
    push!(S, node)
    while !isempty(S)
        node = pop!(S)
        if isempty(node.Ω)
            if node.lowerBound == upperBound
                selectedNode = node
                break
            end
            if node.lowerBound < upperBound
                upperBound = node.lowerBound
                selectedNode = node
            end
            continue
        end

        minimum, index = findmin(a-> p[a[1]][a[2]] + node.r[a[1]][a[2]], node.Ω)
        i,j = node.Ω[index]
        i_star = μ[i][j]
        Ω_prim = filter(a->(node.r[a[1]][a[2]] < minimum && μ[a[1]][a[2]] == i_star), node.Ω)
        listOfNodes = []
        for selectedOperation in Ω_prim
            newNode = ActiveScheduleNode(
                filter(a->a != selectedOperation, node.Ω),
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
        sort!(listOfNodes, by = x->x.lowerBound)
        filter!(x-> x.lowerBound <= upperBound, listOfNodes)
        for nodeToPush in Iterators.reverse(listOfNodes)
            push!(S, nodeToPush)
        end
        
    end
    return (selectedNode.r, maximum(maximum.(selectedNode.r + p)))
end




