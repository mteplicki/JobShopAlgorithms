mutable struct ActiveScheduleNode
    Ω::Vector{Tuple{Int,Int}}
    lowerBound::Union{Int64, Nothing}
    graph::AbstractGraph
    scheduled::Dict{Tuple{Int64,Int64}, Bool}
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
    r = [[0 for _ in 1:a] for a in n_i]
    
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
    lowerBound::Union{Int, Nothing} = nothing
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
        Dict{Tuple{Int64,Int64}, Bool}()
        )

    rGraph = DAGpaths(node.graph, 1, :longest)
    node.lowerBound = rGraph[sum(n_i)+2]
    for (index, value) in enumerate(rGraph)
        if index == 1 || index == sum(n_i)+2 
            continue
        end
        i, j = graphNodeToJob[index]
        r[i][j] = value
    end

    for machineNumber in 1:m
        newP = [p[job[1]][job[2]] for job in machineJobs[machineNumber]]
        newD::Vector{Int} = []
        newR = [r[job[1]][job[2]] for job in machineJobs[machineNumber]]
        for job in machineJobs[machineNumber]
            d = DAGpaths(node.graph, jobToGraphNode[job[1]][job[2]], :longest)
            push!(newD, d[sum(n_i)+2] - node.lowerBound - p[job[1]][job[2]])
        end
        node.lowerBound = min(node.lowerBound, SingleMachineReleaseLMax(newP,newR,newD))
    end

    #=
        dodaj upperBound i warunki końcowe
    =#
    push!(S, node)
    while !isempty(S)
        node = pop!(S)

        minimum, index = findmin(a-> p[a[1]][a[2]] + r[a[1]][a[2]], node.Ω)
        i_star = node.Ω[index][2]
        Ω_prim = filter(a->(r[a[1]][a[2]] < minimum && μ[a[1]][a[2]] == i_star), node.Ω)
        listOfNodes = []
        for selectedOperation in Ω_prim
            newNode = ActiveScheduleNode(
                filter(a->a != selectedOperation, node.Ω),
                nothing,
                deepcopy(node.graph),
                deepcopy(node.scheduled)
            )
            newNode.scheduled[selectedOperation] = true
            push!(newNode.Ω, (selectedOperation[1], selectedOperation[2] + 1))
        
            for operation in machineJobs[μ[selectedOperation[1]][selectedOperation[2]]]
                if !(get!(newNode.scheduled, operation, false))
                    add_edge!(newNode.graph, jobToGraphNode[selectedOperation[1]][selectedOperation[2]], jobToGraphNode[operation[1]][operation[2]], p[selectedOperation[1]][selectedOperation[2]])
                end
            end
            
            rGraph = DAGpaths(newNode.graph, 1, :longest)
            newNode.lowerBound = rGraph[sum(n_i)+2]
            for (index, value) in enumerate(rGraph)
                if index == 1 || index == sum(n_i)+2 
                    continue
                end
                i, j = graphNodeToJob[index]
                r[i][j] = value
            end
        
            for machineNumber in 1:m
                newP = [p[job[1]][job[2]] for job in machineJobs[machineNumber]]
                newD::Vector{Int} = []
                newR = [r[job[1]][job[2]] for job in machineJobs[machineNumber]]
                for job in machineJobs[machineNumber]
                    d = DAGpaths(newNode.graph, jobToGraphNode[job[1]][job[2]], :longest)
                    push!(newD, newNode.lowerBound + p[job[1]][job[2]] - d[sum(n_i) + 2])
                end
                lowerBoundCandidate = newNode.lowerBound + SingleMachineReleaseLMax(newP,newR,newD)
                newNode.lowerBound = min(newNode.lowerBound, lowerBoundCandidate)
            end
            push!(listOfNodes, newNode)
            
        end
        sort!(listOfNodes, by = x->-x.lowerBound)
        filter!(x-> x.lowerBound <= upperBound, listOfNodes)
        for nodeToPush in listOfNodes
            push!(S, nodeToPush)
        end
    end

    
    
end




