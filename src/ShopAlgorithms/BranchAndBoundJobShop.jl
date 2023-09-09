using DataStructures
using Graphs, SimpleWeightedGraphs

mutable struct Operation
    i::Int64
    j::Int64
    p::Int64
    r::Int64
end

mutable struct ActiveScheduleNode
    Ω::Vector{Operation}
    lowerBound::Union{Int64, Nothing}
    graph::SimpleGraph
    scheduled::Dict{Tuple{Int64,Int64}, Bool}
end

function generateActiveSchedules(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    jobToGraphNode = [[0 for _ in 1:n_i[i]] for i in 1:n]
    graphNodeToJob = [(0,0) for _ in 1:sum(n_i)]
    machineJobs = [[] for _ in 1:m]
    
    counter = 0
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

    r = DAGpaths(node.graph, 1, :longest)
    node.lowerBound = r[sum(n_i)+2]
    for machineNumber in 1:m
        newP = [p[jobToGraphNode[job[1]][job[2]]] for job in machineJobs[machineNumber]]
        # newD = [d[jobToGraphNode[job[1]][job[2]]] for job in machineJobs[machineNumber]]
        newD = []
        newR = [r[jobToGraphNode[job[1]][job[2]]] for job in machineJobs[machineNumber]]
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

        minimum, index = findmin(a->a.p + a.r, node.Ω)
        i_star = node.Ω[index].i
        Ω_prim = filter(a->(a.r < minimum && a.i == i_star), node.Ω)
        listOfNodes = []
        for selectedOperation in Ω_prim
            newNode = ActiveScheduleNode(
                filter(a->a != selectedOperation, node.Ω),
                nothing,
                deepcopy(node.graph),
                deepcopy(node.scheduled)
            )
            node.scheduled[selectedOperation] = true
        
            for operation in machineJobs[μ[selectedOperation[1]][selectedOperation[2]]]
                if !(operation in node.scheduled)
                    add_edge!(newNode.graph, jobToGraphNode[selectedOperation[1]][selectedOperation[2]], jobToGraphNode[operation[1]][operation[2]], p[selectedOperation[1]][selectedOperation[2]])
                end
            end
            
            newNode.lowerBound = node.lowerBound
            for machineNumber in 1:m
                r = DAGpaths(node.graph, 1, :longest)
                d = DAGpaths(node.graph, 1, :shortest)
                newP = [p[jobToGraphNode[job[1]][job[2]]] for job in machineJobs[machineNumber]]
                newR = [r[jobToGraphNode[job[1]][job[2]]] for job in machineJobs[machineNumber]]
                newD = [d[jobToGraphNode[job[1]][job[2]]] for job in machineJobs[machineNumber]]
                newNode.lowerBound = max(newNode.lowerBound, SingleMachineReleaseLMax(newP,newR,newD) + node.lowerBound)
            end
            
        end
        sort!(listOfNodes, by = x->-x.lowerBound)
        for nodeToPush in listOfNodes
            push!(S, nodeToPush)
        end
    end

    
    
end

function test()
    n = 3
    m = 4
    n_i = [3,4,3]
    p = [[10,8,4],[8,3,5,6],[4,7,3]]
    μ = [[1,2,3],[2,1,4,3],[1,2,4]]
    generateActiveSchedules(n,m,n_i,p,μ)
end




