function shiftingBottleneck(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    jobToGraphNode::Vector{Vector{Int}} = [[0 for _ in 1:n_i[i]] for i in 1:n]
    graphNodeToJob::Vector{Tuple{Int,Int}} = [(0,0) for _ in 1:(sum(n_i) + 2)]
    machineJobs::Vector{Vector{Tuple{Int,Int}}} = [[] for _ in 1:m]
    machineWithJobs::Vector{Vector{Tuple{Int,Int}}} = [[(0,0) for _ in 1:n] for _ in 1:m]
    machineFixedEdges::Vector{Vector{Tuple{Int,Int}}} = [[] for _ in 1:m]

    counter = 2
    for i in 1:n
        for j in 1:n_i[i]
            jobToGraphNode[i][j] = counter
            graphNodeToJob[counter] = (i,j)
            push!(machineJobs[μ[i][j]], (i,j))
            counter += 1
            machineWithJobs[μ[i][j]][i] = (i,j)
        end
    end

    graph = SimpleWeightedGraphAdj(sum(n_i)+2, Int)
    for i in 1:n
        add_edge!(graph, 1, jobToGraphNode[i][1], 0)
        for j in 1:(n_i[i] - 1)
            add_edge!(graph, jobToGraphNode[i][j], jobToGraphNode[i][j+1], p[i][j])
        end
        add_edge!(graph, jobToGraphNode[i][n_i[i]], sum(n_i)+2, p[i][n_i[i]])
    end

    r, rGraph = generateReleaseTimes(graph, n_i, graphNodeToJob)
    M_0 = Set{Int}() 
    M = Set{Int}([i for i in 1:m])
    Cmax = rGraph[sum(n_i)+2]   
    
    while M_0 ≠ M
        Lmax = typemin(Int64)
        k::Union{Int,Nothing} = nothing
        sequence::Union{Vector{Int},Nothing} = nothing
        for i in setdiff(M, M_0)
            LmaxCandidate, sequenceCandidate = generateSequence(p, r, n_i, machineJobs, jobToGraphNode, graph, Cmax, i)
            if LmaxCandidate >= Lmax
                Lmax = LmaxCandidate
                sequence = sequenceCandidate
                k = i
            end
        end
        M_0 = M_0 ∪ k
        Cmax += Lmax
        fixDisjunctiveEdges(sequence, machineWithJobs, jobToGraphNode, graph, p, k, machineFixedEdges)
        for fixMachine in setdiff(M_0, Set([k]))
            backUpGraph = deepcopy(graph)
            for (job1, job2) in machineFixedEdges[fixMachine]
                rem_edge!(graph, job1, job2)
            end
            
            r, rGraph = generateReleaseTimes(graph, n_i, graphNodeToJob)
            longestPath = rGraph[sum(n_i)+2]
            LmaxCandidate, sequenceCandidate = generateSequence(p, r, n_i, machineJobs, jobToGraphNode, graph, Cmax, fixMachine)
            if LmaxCandidate + longestPath >= Cmax
                graph = backUpGraph
            else
                empty!(machineFixedEdges[fixMachine])
                Cmax = LmaxCandidate + longestPath
                fixDisjunctiveEdges(sequenceCandidate, machineWithJobs, jobToGraphNode, graph, p, fixMachine, machineFixedEdges)
            end
        end
        r, rGraph = generateReleaseTimes(graph, n_i, graphNodeToJob)
    end
    Cmax = rGraph[sum(n_i)+2]
    return (r, Cmax)
end

