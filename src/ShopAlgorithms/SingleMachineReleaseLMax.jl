mutable struct JobData
    p::Int64
    r::Int64
    d::Int64
    index::Int64
    C::Union{Int64, Nothing}
end

mutable struct SingleMachineReleaseLMaxNode
    jobs::Vector{Int64}
    jobsOrdered::Vector{JobData}
    lowerBound::Union{Int64, Nothing}
    time::Union{Int64, Nothing}
end

"""
1|R_j|Lmax
"""
function SingleMachineReleaseLMax(
    p::Vector{Int64},
    r::Vector{Int64},
    d::Vector{Int64},
    indices::Union{Vector{Int64}, Nothing} = nothing
)
    if indices === nothing
        indices = [i for i in 1:length(p)]
    end
    upperBound = typemax(Int64)
    minNode::Union{SingleMachineReleaseLMaxNode, Nothing} = nothing
    stack = Stack{SingleMachineReleaseLMaxNode}()
    node = SingleMachineReleaseLMaxNode([i for i in 1:length(p)],[], 0,0)
    
    node.lowerBound = SingleMachineReleaseLMaxPmtn([JobData(p[i], r[i], d[i], i, nothing) for i in node.jobs], node.jobsOrdered, node.time)
    lowerBound = node.lowerBound
    push!(stack, node)
    while !isempty(stack)
        node = pop!(stack)
        if length(node.jobs) == 0 
            if node.lowerBound < upperBound
                upperBound = node.lowerBound
                minNode = node
            end
        elseif node.lowerBound <= upperBound
            listToPush = []
            for i in node.jobs
                nodeCopy = SingleMachineReleaseLMaxNode(
                    [j for j in node.jobs if j != i],
                    [node.jobsOrdered; JobData(p[i], r[i], d[i], i, max(r[i], node.time) + p[i])],
                    nothing,
                    max(r[i], node.time) + p[i]
                )
                if r[i] >= minimum([max(r[j], node.time) + p[j] for j in nodeCopy.jobs]; init = typemax(Int64))
                    continue
                end
                nodeCopy.lowerBound = SingleMachineReleaseLMaxPmtn([JobData(p[i], r[i], d[i], i, nothing) for i in nodeCopy.jobs], nodeCopy.jobsOrdered, nodeCopy.time)
                if nodeCopy.lowerBound < upperBound
                    push!(listToPush, nodeCopy)
                end
            end
            sort!(listToPush, by = x->x.lowerBound)
            for nodeToPush in listToPush
                push!(stack, nodeToPush)
            end
        end
    end
    return minNode.lowerBound, map(x->indices[x.index], minNode.jobsOrdered)
end

dequeuesafe!(queue::PriorityQueue{K, V}) where {K,V} = isempty(queue) ? nothing : dequeue!(queue)
firstsafe(queue::PriorityQueue{K, V}) where {K,V} = isempty(queue) ? nothing : first(first(queue))

"""
1|R_j,pmtn|Lmax\\
preemptive EDD
"""
function SingleMachineReleaseLMaxPmtn(
    jobs::Vector{JobData},
    jobsOrdered::Vector{JobData},
    startTime::Int64
)::Int
    for job in jobs
        job.r = max(job.r, startTime)
    end
    releaseQueue = PriorityQueue{JobData, Int}()
    deadlineQueue = PriorityQueue{JobData, Int}()
    for (i, job) in enumerate(jobs)
        enqueue!(releaseQueue, job=>job.r)
    end
    t = startTime
    firstJob = dequeuesafe!(releaseQueue)
    if firstJob ≢  nothing
        enqueue!(deadlineQueue, firstJob=>firstJob.d)
    end
    while !isempty(deadlineQueue)
        jobToProceed = dequeue!(deadlineQueue)
        jobPreempted = false
        time = max(t, jobToProceed.r)
        pmtnJob = firstsafe(releaseQueue)
        while !jobPreempted && pmtnJob !== nothing && pmtnJob.r < time + jobToProceed.p
            pmtnJob = dequeue!(releaseQueue)
            if pmtnJob.d <= jobToProceed.d
                jobPreempted = true
                jobToProceed.p -= pmtnJob.r - time
                t = pmtnJob.r
                enqueue!(deadlineQueue, jobToProceed=>jobToProceed.d)
                enqueue!(deadlineQueue, pmtnJob=>pmtnJob.d)
            else
                enqueue!(deadlineQueue, pmtnJob=>pmtnJob.d)
                pmtnJob = firstsafe(releaseQueue)
            end
        end
        if !jobPreempted
            t += jobToProceed.p
            jobToProceed.C = t
        end
        if isempty(deadlineQueue) && !isempty(releaseQueue)
            jobAfterProceeded = dequeue!(releaseQueue)
            enqueue!(deadlineQueue, jobAfterProceeded=>jobAfterProceeded.d)
            while firstsafe(releaseQueue) !== nothing && firstsafe(releaseQueue).r == jobAfterProceeded.r
                jobToAdd = dequeue!(releaseQueue)
                enqueue!(deadlineQueue, jobToAdd=>jobToAdd.d)
            end
        end
    end
    return max(maximum([job.C - job.d for job in jobsOrdered]; init = typemin(Int)),maximum([job.C - job.d for job in jobs]; init = typemin(Int)))
end

function test()
    result = SingleMachineReleaseLMax([10,3,4],[0,10,10],[14,17,18])
    println(result)
end

# test()