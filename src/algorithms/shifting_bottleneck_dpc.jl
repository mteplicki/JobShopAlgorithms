export shiftingbottleneckdpc



"""
    shiftingbottleneckdpc(instance::JobShopInstance; yielding::Bool=false)

Solves the job shop scheduling `J || Cmax` problem with recirculation allowed using the Shifting Bottleneck algorithm with
Delayed Precedence Constraints algorithm. The solution of the problem is not guaranteed to be optimal.

# Arguments
- `instance::JobShopInstance`: An instance of the job shop scheduling problem.
- `yielding::Bool=false`: If `true`, the algorithm will yield after each iteration. This is useful for timeouting the algorithm.

# Returns
- An instance of the job shop scheduling problem in the format required by the `shiftingbottleneckdpc` function. The solution is not guaranteed to be optimal.
"""
function shiftingbottleneckdpc(instance::JobShopInstance; yielding::Bool = false)
    _ , timeSeconds, bytes = @timed begin 
    n, m, n_i, p, μ = instance.n, instance.m, instance.n_i, instance.p, instance.μ
    microruns = 0
    yield_ref = yielding ? Ref(time()) : nothing
    # generujemy pomocnicze tablice
    jobToGraphNode, graphNodeToJob, machineJobs, machineWithJobs = generate_util_arrays(n, m, n_i, μ)
    # zbiór krawędzi disjunktywnych, które zostały już ustalone dla maszyny `i`
    machineFixedEdges::Vector{Vector{Tuple{Int,Int}}} = [[] for _ in 1:m]

    graph = generate_conjuctive_graph(n, n_i, p, jobToGraphNode)

    r, rGraph = generate_release_times(graph, n_i, graphNodeToJob)
    # M_0 - zbiór maszyn, dla których ustalono już krawędzie disjunktywne
    M_0 = Set{Int}()
    # M - zbiór maszyn
    M = Set{Int}([i for i in 1:m])
    Cmax = rGraph[sum(n_i)+2]

    while M_0 ≠ M
        Cmax = typemin(Int64)
        k::Union{Int,Nothing} = nothing
        sequence::Union{Vector{Tuple{Int,Int}},Nothing} = nothing
        
        # dla każdej maszyny, dla której nie ustalono jeszcze krawędzi disjunktywnych
        # wybierz tę, dla której algorytm 1 | r_j | Lmax wskaże najdłuższy czas wykonania (Bottleneck)
        for i in setdiff(M, M_0)
            # println("M_0: $M_0, i: $i")
            try_yield(yield_ref)
            try
                CmaxCandidate, sequenceCandidate, add_microruns = generate_sequence_dpc(p, r, n_i, machineJobs, jobToGraphNode, graph, Cmax, i, yield_ref)
                microruns += add_microruns
                if CmaxCandidate >= Cmax
                    Cmax = CmaxCandidate
                    sequence = sequenceCandidate
                    k = i
                end
            catch error
                if error isa DimensionMismatch
                    continue
                else
                    rethrow()
                end
            end
        end
        if k === nothing
            M_0 = M
            continue
        end
        M_0 = M_0 ∪ k
        fix_disjunctive_edges(sequence, jobToGraphNode, graph, p, k, machineFixedEdges)
        # dla każdej maszyny, dla której ustalono już krawędzi disjunktywne
        # sprawdź, czy można lepiej je ustawić i zmniejszyć Cmax
        for fixMachine in setdiff(M_0, Set([k]))
            backUpGraph = deepcopy(graph)
            # println("fixMachine: $fixMachine")
            for (job1, job2) in machineFixedEdges[fixMachine]
                rem_edge!(graph, job1, job2)
            end
            try
                r, rGraph = generate_release_times(graph, n_i, graphNodeToJob)
                longestPath = rGraph[sum(n_i)+2]
                Cmaxcandidate, sequenceCandidate, add_microruns = generate_sequence_dpc(p, r, n_i, machineJobs, jobToGraphNode, graph, Cmax, fixMachine, yield_ref)
                microruns += add_microruns
                if Cmaxcandidate >= Cmax
                    graph = backUpGraph
                else
                    empty!(machineFixedEdges[fixMachine])
                    Cmax = Cmaxcandidate
                    fix_disjunctive_edges(sequenceCandidate, jobToGraphNode, graph, p, fixMachine, machineFixedEdges)
                end
            catch error
                if isa(error, DimensionMismatch)
                    graph = backUpGraph
                    continue
                else
                    rethrow()
                end
            end
        end
        # możliwe usprawnienia - być może nie trzeba obliczać za każdym razem Cmax, tylko polegać na wskazaniu algorytmu 1 | r_j | Lmax
        r, rGraph = generate_release_times(graph, n_i, graphNodeToJob)
        Cmax = rGraph[sum(n_i)+2]
    end
    Cmax = rGraph[sum(n_i)+2]
    end
    return ShopSchedule(
        instance,
        r + p,
        Cmax,
        Cmax_function;
        algorithm = "Shifting Bottleneck - DPC",
        memoryBytes = bytes,
        timeSeconds = timeSeconds,
        microruns = microruns
    )
end

