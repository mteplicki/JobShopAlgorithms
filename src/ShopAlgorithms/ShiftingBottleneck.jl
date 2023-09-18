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
    machineWithJobs::Vector{Vector{Int}} = [[(0,0) for _ in 1:n_i[i]] for i in 1:n]

    counter = 2
    for i in 1:n
        for j in 1:n_i[i]
            jobToGraphNode[i][j] = counter
            graphNodeToJob[counter] = (i,j)
            push!(machineJobs[μ[i][j]], (i,j))
            counter += 1
            machineWithJobs[μ[i][j]][j] = (i,j)
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
    rGraph = DAGpaths(graph, 1, :longest)
    r = [[0 for _ in 1:a] for a in n_i]
    for (index, value) in enumerate(rGraph)
        if index == 1 || index == sum(n_i)+2 
            continue
        end
        i, j = graphNodeToJob[index]
        r[i][j] = value 
    end 


    M_0 = Set{Int}() 
    M = Set{Int}([i for i in 1:m])
    Cmax = rGraph[sum(n_i)+2]
    Lmax = typemin(Int64)
    k::Union{Int,Nothing} = nothing
    sequence::Union{Vector,Nothing} = nothing
    while M_0 ≠ M

        for i in setdiff(M, M_0)
            newP = [p[job[1]][job[2]] for job in machineJobs[i]]
            newD::Vector{Int} = []
            newR = [r[job[1]][job[2]] for job in machineJobs[i]]
            for job in machineJobs[i]
                d = DAGpaths(graph, jobToGraphNode[job[1]][job[2]], :longest)
                push!(newD, Cmax + p[job[1]][job[2]] - d[sum(n_i) + 2])
            end

            LmaxCandidate, sequenceCandidate = SingleMachineReleaseLMax(newP,newR,newD)
            if LmaxCandidate > Lmax
                Lmax = LmaxCandidate
                sequence = sequenceCandidate
                k = i
            end
        end
        M_0 = M_0 ∪ k
        Cmax += Lmax
        for (job1, job2) in Iterators.zip(sequence, Iterators.drop(sequence, 1))
            add_edge!(Graph, jobToGraphNode
        end
    end



end