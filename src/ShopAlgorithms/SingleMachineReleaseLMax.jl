using DataStructures

struct SingleMachineReleaseLMaxNode
    jobs::Vector{Int64}
    jobsOrdered::Vector{Int64}
    lowerBound::Union{Int64, Nothing}
end

mutable struct JobData
    p::Int64
    r::Int64
    d::Int64
    C::Union{Int64, Nothing}
end

lightCopy(job::JobData)::JobData = JobData(job.p, job.r, job.d, nothing)

"""
1|R_j|Lmax
"""
function SingleMachineReleaseLMax(
    p::Vector{Int64},
    r::Vector{Int64},
    d::Vector{Int64}
)
    upperBound = typemax(Int64)
    minNode::Union{SingleMachineReleaseLMaxNode, Nothing} = nothing
    stack = Stack{SingleMachineReleaseLMaxNode}()
    node = SingleMachineReleaseLMaxNode([JobData(p[i], r[i], d[i], nothing) for i in 1:length(p)],[], 0)
    
    node.lowerBound = SingleMachineReleaseLMaxPmtn(map(lightCopy, node.jobs), map(lightCopy, node.jobsOrdered), 0)
    lowerBound = node.lowerBound
    push!(stack, node)
    while !isempty(stack)
        node = pop!(stack)
        if length(node.jobs) == 1
            node.jobsOrdered = [node.jobsOrdered; node.jobs]
            node.jobs = []
            node.lowerBound = SingleMachineReleaseLMaxPmtn(map(lightCopy, node.jobs), map(lightCopy, node.jobsOrdered), 0)
            if node.lowerBound == upperBound
                minNode = node
                break
            end
            if node.lowerBound < upperBound
                upperBound = node.lowerBound
                minNode = node
            end
        else
            listToPush = []
            for i in 1:length(node.jobs)
                nodeCopy = SingleMachineReleaseLMaxNode(
                    [node.jobs[j] for j in 1:length(node.jobs) if j != i],
                    [node.jobsOrdered; node.jobs[i]],
                    nothing
                )
                nodeCopy.lowerBound = SingleMachineReleaseLMaxPmtn(map(lightCopy, nodeCopy.jobs), map(lightCopy, nodeCopy.jobsOrdered), 0)
                if nodeCopy.lowerBound < upperBound
                    push!(listToPush, nodeCopy)
                end
            end
            sort!(listToPush, by = x->-x.lowerBound)
            for nodeToPush in listToPush
                push!(stack, nodeToPush)
            end
        end
    end
    return minNode.lowerBound
end

"""
1|R_j,pmtn|Lmax\\
preemptive EDD
"""
function SingleMachineReleaseLMaxPmtn(
    jobs::Vector{JobData},
    jobsOrdered::Vector{Int64},
    startTime::Int64
)::Int
    for job in jobs
        job.r = max(job.r, startTime)
    end
    releaseQueue = PriorityQueue{Int64, JobData}()
    deadlineQueue = PriorityQueue{Int64, JobData}()
    for (i, job) in enumerate(jobs)
        enqueue!(releaseQueue, job.r=>job)
        enqueue!(deadlineQueue, job.d=>job)
    end
    t = 0
    while !isempty(deadlineQueue)
        _, dJob = first(deadlineQueue)
        dequeue!(deadlineQueue)
        t = max(t, dJob.r)
        jobPreempted = false

        if !isempty(releaseQueue)
            _, rJob = first(releaseQueue)
            dequeue!(releaseQueue)
            while rJob.r <= t + dJob.p
                if rJob.d < dJob.d
                    dJob.p -= rJob.r - t
                    enqueue!(deadlineQueue, dJob.d=>dJob)
                    t = rJob.r
                    jobPreempted = true
                    break
                end
            end
        end

        if !jobPreempted
            t += dJob.p
            dJob.C = t
        end
    end
    return max(maximum([job.C - job.d for job in jobsOrdered]),maximum([job.C - job.d for job in jobs]))
end