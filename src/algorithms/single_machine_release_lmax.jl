mutable struct JobData
    p::Int64
    r::Int64
    d::Int64
    index::Int64
    C::Union{Int64,Nothing}
end

mutable struct SingleMachineReleaseLMaxNode
    jobs::Vector{Int64}
    jobsOrdered::Vector{JobData}
    lowerBound::Union{Int64,Nothing}
    time::Union{Int64,Nothing}
end

"""
1|R_j|Lmax
"""
function single_machine_release_LMax(
    p::Vector{Int64},
    r::Vector{Int64},
    d::Vector{Int64}
)
    microruns = 0
    # algorytm Branch and Bound
    upperBound = typemax(Int64)
    minNode::Union{SingleMachineReleaseLMaxNode,Nothing} = nothing
    stack = SingleMachineReleaseLMaxNode[]
    node = SingleMachineReleaseLMaxNode([i for i in 1:length(p)], [], 0, 0)

    node.lowerBound = single_machine_release_LMax_pmtn([JobData(p[i], r[i], d[i], i, nothing) for i in node.jobs], node.jobsOrdered, node.time)
    microruns += 1
    push!(stack, node)
    while !isempty(stack)
        node = pop!(stack)

        if length(node.jobs) == 0
            # jeśli znaleziono węzeł końcowy, to sprawdzamy czy jego wartość jest mniejsza niż obecna górna granica algorytmu
            # jeśli tak, to aktualizujemy upperBound i zapisujemy ten węzeł jako najlepszy dotychczas znaleziony
            if node.lowerBound < upperBound
                upperBound = node.lowerBound
                minNode = node
            end
        elseif node.lowerBound < upperBound
            listToPush = []
            for i in node.jobs
                # tworzymy węzeł, w którym ustawiono jako kolejne zadanie i
                nodeCopy = SingleMachineReleaseLMaxNode(
                    [j for j in node.jobs if j != i],
                    [node.jobsOrdered; JobData(p[i], r[i], d[i], i, max(r[i], node.time) + p[i])],
                    nothing,
                    max(r[i], node.time) + p[i]
                )
                # jeśli r_i >= min{max(r_j, t) + p_j} to nie dodajemy do listy - intuicyjnie, jeśli jest spełniona ta równość
                # to wtedy przed zadaniem i można jeszcze wykonać jakieś zadanie j i nie pogorszyć rozwiązania
                if r[i] >= minimum([max(r[j], node.time) + p[j] for j in nodeCopy.jobs]; init=typemax(Int64))
                    continue
                end
                # obliczmy dolną granicę dla tego węzła, stosując algorytm 1|R_j,pmtn|Lmax
                nodeCopy.lowerBound = single_machine_release_LMax_pmtn([JobData(p[i], r[i], d[i], i, nothing) for i in nodeCopy.jobs], nodeCopy.jobsOrdered, nodeCopy.time)
                microruns += 1
                push!(listToPush, nodeCopy)
            end
            # filtrujemy listę węzłów do dodania, usuwamy te, które mają dolną granicę większą niż obecny upperBound
            filter!(x -> x.lowerBound < upperBound, listToPush)
            # sortujemy listę węzłów do dodania po dolnej granicy, zaczynamy od najbardziej obiecujących kandydatów
            sort!(listToPush, by=x -> x.lowerBound, rev=true)
            append!(stack, listToPush)
        end
    end
    return minNode.lowerBound, map(x -> x.index, minNode.jobsOrdered), microruns
end


"""
1|R_j,pmtn|Lmax\\
preemptive EDD
"""
function single_machine_release_LMax_pmtn(
    jobs::Vector{JobData},
    jobsOrdered::Vector{JobData},
    startTime::Int64=0
)::Int
    # algorytm 1|R_j,pmtn|Lmax, preemptive EDD (Earliest Due Date)

    # modyfikujemy r_i, tak aby r_i >= startTime (czyli żeby zadanie i nie zaczęło się wcześniej, niż poprzednie uporządkowane już zadania)
    for job in jobs
        job.r = max(job.r, startTime)
    end
    # kolejka priorytetowa, zawierająca wszystkie zadania, które jeszcze nie są dostępne (r_i > t), posortowane po r_i
    releaseQueue = PriorityQueue{JobData,Int}()
    for (i, job) in enumerate(jobs)
        enqueue!(releaseQueue, job => job.r)
    end
    # kolejka priorytetowa, zawierająca wszystkie zadania, które są dostępne i niewykonane do końca (r_i <= t), posortowane po d_i
    deadlineQueue = PriorityQueue{JobData,Int}()
    # t - aktualny czas
    t = startTime
    # ściągamy pierwsze zadanie z kolejki releaseQueue (pierwsze dostępne zadanie) i dodejemy je do kolejki deadlineQueue (już dostępnych zadań)
    firstJob = dequeuesafe!(releaseQueue)
    if firstJob ≢ nothing
        enqueue!(deadlineQueue, firstJob => firstJob.d)
    end
    while !isempty(deadlineQueue)
        jobToProceed = dequeue!(deadlineQueue)
        # flaga informująca, czy zadanie jobToProceed zostało przerwane przez jakieś inne zadanie,
        # które zostało dostępne w czasie wykonywania jobToProceed, a ma szybszy deadline
        jobPreempted = false
        time = max(t, jobToProceed.r)
        # ściągamy z kolejki releaseQueue wszystkie zadania, które są dostępne w czasie wykonywania jobToProceed
        pmtnJob = firstsafe(releaseQueue)
        while !jobPreempted && pmtnJob !== nothing && pmtnJob.r < time + jobToProceed.p
            pmtnJob = dequeue!(releaseQueue)
            # jeśli zadanie pmtnJob ma szybszy deadline niż jobToProceed, to przerwij wykonywanie jobToProceed i dodaj je do kolejki deadlineQueue
            if pmtnJob.d <= jobToProceed.d
                jobPreempted = true
                jobToProceed.p -= pmtnJob.r - time
                t = pmtnJob.r
                enqueue!(deadlineQueue, jobToProceed => jobToProceed.d)
                enqueue!(deadlineQueue, pmtnJob => pmtnJob.d)
            else
                # jeśli zadanie pmtnJob ma późniejszy deadline niż jobToProceed, to dodaj je do kolejki deadlineQueue
                enqueue!(deadlineQueue, pmtnJob => pmtnJob.d)
                pmtnJob = firstsafe(releaseQueue)
            end
        end
        # jeśli zadanie jobToProceed nie zostało przerwane, to wykonaj je do końca
        if !jobPreempted
            t += jobToProceed.p
            jobToProceed.C = t
        end
        # jeśli kolejka deadlineQueue jest pusta, a releaseQueue jeszcze nie jest pusta, to dodaj do deadlineQueue zadanie, które zostało dostępne jako pierwsze
        # taka sytuacja może wystąpić, jeśli w czasie wykonywania jobToProceed, nie było innych zadań dostępnych, a pojawiły się one dopiero po jego zakończeniu
        if isempty(deadlineQueue) && !isempty(releaseQueue)
            jobAfterProceeded = dequeue!(releaseQueue)
            enqueue!(deadlineQueue, jobAfterProceeded => jobAfterProceeded.d)
            while firstsafe(releaseQueue) !== nothing && firstsafe(releaseQueue).r == jobAfterProceeded.r
                jobToAdd = dequeue!(releaseQueue)
                enqueue!(deadlineQueue, jobToAdd => jobToAdd.d)
            end
        end
    end
    return max(maximum([job.C - job.d for job in jobsOrdered]; init=typemin(Int)), maximum([job.C - job.d for job in jobs]; init=typemin(Int)))
end

function test()
    result = single_machine_release_LMax([10, 3, 4], [0, 10, 10], [14, 17, 18])
    println(result)
end

# test()