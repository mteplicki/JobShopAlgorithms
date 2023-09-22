export shiftingbottleneck

shiftingbottleneck(instance::JobShopInstance) = shiftingbottleneck(
    instance.n,
    instance.m,
    instance.n_i,
    instance.p,
    instance.μ
)

function shiftingbottleneck(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    # nonrepetitive
    all(sort(collect(Set(x))) == sort(x) for x in μ) || throw(ArgumentError("μ must be nonrepetitive"))

    jobToGraphNode, graphNodeToJob, machineJobs, machineWithJobs = generate_util_arrays(n, m, n_i, μ)
    machineFixedEdges::Vector{Vector{Tuple{Int,Int}}} = [[] for _ in 1:m]

    graph = generate_conjuctive_graph(n, n_i, p, jobToGraphNode)

    r, rGraph = generate_release_times(graph, n_i, graphNodeToJob)
    M_0 = Set{Int}()
    M = Set{Int}([i for i in 1:m])
    Cmax = rGraph[sum(n_i)+2]

    while M_0 ≠ M
        Lmax = typemin(Int64)
        k::Union{Int,Nothing} = nothing
        sequence::Union{Vector{Int},Nothing} = nothing
        for i in setdiff(M, M_0)
            LmaxCandidate, sequenceCandidate = generate_sequence(p, r, n_i, machineJobs, jobToGraphNode, graph, Cmax, i)
            if LmaxCandidate >= Lmax
                Lmax = LmaxCandidate
                sequence = sequenceCandidate
                k = i
            end
        end
        M_0 = M_0 ∪ k
        Cmax += Lmax
        fix_disjunctive_edges(sequence, machineWithJobs, jobToGraphNode, graph, p, k, machineFixedEdges)
        for fixMachine in setdiff(M_0, Set([k]))
            backUpGraph = deepcopy(graph)
            for (job1, job2) in machineFixedEdges[fixMachine]
                rem_edge!(graph, job1, job2)
            end

            r, rGraph = generate_release_times(graph, n_i, graphNodeToJob)
            longestPath = rGraph[sum(n_i)+2]
            LmaxCandidate, sequenceCandidate = generate_sequence(p, r, n_i, machineJobs, jobToGraphNode, graph, Cmax, fixMachine)
            if LmaxCandidate + longestPath >= Cmax
                graph = backUpGraph
            else
                empty!(machineFixedEdges[fixMachine])
                Cmax = LmaxCandidate + longestPath
                fix_disjunctive_edges(sequenceCandidate, machineWithJobs, jobToGraphNode, graph, p, fixMachine, machineFixedEdges)
            end
        end
        r, rGraph = generate_release_times(graph, n_i, graphNodeToJob)
    end
    Cmax = rGraph[sum(n_i)+2]
    return ShopSchedule(
        JobShopInstance(n, m, n_i, p, μ),
        r + p,
        Cmax
    )
end

