export shiftingbottleneck

"""
    shiftingbottleneck(instance::JobShopInstance;suppress_warnings::Bool = false)

Solves the job shop scheduling `J || Cmax` problem with no job recirculation using the Shifting Bottleneck algorithm. The solution of the problem 
is not guaranteed to be optimal. Also, not every instance of the problem can be solved using this algorithm.

# Arguments
- `instance::JobShopInstance`: An instance of the job shop scheduling problem.

# Returns
- `ShopSchedule`: A ShopSchedule object representing the solution to the job shop problem.
- `suppress_warnings`: If `true`, warnings will not be printed.

# Throws 
- `ArgumentError`: If `μ` is not nonrepetitive, or if during processing of the instance, in the graph 
occurs a cycle of fixed disjunctive edges.

"""
function shiftingbottleneck(
    instance::JobShopInstance;
    suppress_warnings::Bool = false
)
    _ , timeSeconds, bytes = @timed begin 
    n, m, n_i, p, μ = instance.n, instance.m, instance.n_i, instance.p, instance.μ
    (job_recirculation()(instance) && !suppress_warnings) && @warn("The shiftingbottleneck algorithm can only be used for job shop problems with no recirculation.")
    microruns = 0
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
        Lmax = typemin(Int64)
        k::Union{Int,Nothing} = nothing
        sequence::Union{Vector{Tuple{Int,Int}},Nothing} = nothing
        # dla każdej maszyny, dla której nie ustalono jeszcze krawędzi disjunktywnych
        # wybierz tę, dla której algorytm 1 | r_j | Lmax wskaże najdłuższy czas wykonania (Bottleneck)
        for i in setdiff(M, M_0)
            LmaxCandidate, sequenceCandidate, add_microruns = generate_sequence(p, r, n_i, machineJobs, jobToGraphNode, graph, Cmax, i)          
            microruns += add_microruns
            if LmaxCandidate >= Lmax
                Lmax = LmaxCandidate
                sequence = sequenceCandidate
                k = i
            end
        end
        M_0 = M_0 ∪ k
        Cmax += Lmax
        fix_disjunctive_edges(sequence, jobToGraphNode, graph, p, k, machineFixedEdges)
        # dla każdej maszyny, dla której ustalono już krawędzi disjunktywne
        # sprawdź, czy można lepiej je ustawić i zmniejszyć Cmax
        for fixMachine in setdiff(M_0, Set([k]))
            backUpGraph = deepcopy(graph)
            for (job1, job2) in machineFixedEdges[fixMachine]
                rem_edge!(graph, job1, job2)
            end

            r, rGraph = generate_release_times(graph, n_i, graphNodeToJob)
            longestPath = rGraph[sum(n_i)+2]
            LmaxCandidate, sequenceCandidate, add_microruns = generate_sequence(p, r, n_i, machineJobs, jobToGraphNode, graph, Cmax, fixMachine)
            microruns += add_microruns
            if LmaxCandidate + longestPath >= Cmax
                graph = backUpGraph
            else
                empty!(machineFixedEdges[fixMachine])
                Cmax = LmaxCandidate + longestPath
                fix_disjunctive_edges(sequenceCandidate, jobToGraphNode, graph, p, fixMachine, machineFixedEdges)
            end
        end
        r, rGraph = generate_release_times(graph, n_i, graphNodeToJob)
        # możliwe usprawnienia - być może nie trzeba obliczać za każdym razem Cmax, tylko polegać na wskazaniu algorytmu 1 | r_j | Lmax
        Cmax = rGraph[sum(n_i)+2]
    end
    Cmax = rGraph[sum(n_i)+2]
    end
    return ShopSchedule(
        instance,
        r + p,
        Cmax,
        Cmax_function;
        microruns = microruns,
        algorithm = "Shifting Bottleneck",
        timeSeconds = timeSeconds,
        memoryBytes = bytes
    )
end

