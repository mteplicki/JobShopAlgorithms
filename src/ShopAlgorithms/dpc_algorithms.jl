export schrage, dpc_sequence


using DataStructures
"""
Safe dequeue function. If queue is empty, returns nothing instead of throwing an error.
"""
dequeuesafe!(queue::PriorityQueue{K,V}) where {K,V} = isempty(queue) ? nothing : dequeue!(queue)

"""
Safe first function. If queue is empty, returns nothing instead of throwing an error.
"""
firstsafe(queue::PriorityQueue{K,V}) where {K,V} = isempty(queue) ? nothing : first(first(queue))

function schrage(p::Vector{Int}, r::Vector{Int}, q::Vector{Int}, delay::Matrix{Int})
    size(p,1) == size(r,1) == size(q,1) == size(delay, 1) == size(delay, 2) || throw(ArgumentError("p, r, q and delay must have the same size"))
    r_prim = copy(r)
    rQueue = PriorityQueue{Int, Int}()
    qQueue = PriorityQueue{Int, Int}(Base.Order.Reverse)
    n = length(p)
    for i in 1:n
        enqueue!(rQueue, i=>r_prim[i])
    end
    i, _ = first(rQueue)
    t = r_prim[i]
    U::Vector{Int} = []
    otherJobs = Set(collect(1:n))
    artificialCriticalJobs::Vector{Vector{Int}} = [[] for _ in 1:(n+1)]
    criticalJobs::Vector{Vector{Int}} = [[] for _ in 1:(n+1)]
    lastCriticalJob::Union{Int,Nothing} = nothing
    S = [0 for _ in 1:n+1]
    sizehint!(U, n)
    while length(U) != n
        while firstsafe(rQueue) !== nothing && r_prim[firstsafe(rQueue)] <= t
            jobToAdd = dequeue!(rQueue)
            enqueue!(qQueue, jobToAdd => q[jobToAdd])
        end
        scheduleJob = dequeue!(qQueue)
        while r_prim[scheduleJob] > t
            enqueue!(rQueue, scheduleJob => r_prim[scheduleJob])
            scheduleJob = dequeue!(qQueue)
        end
        push!(U, scheduleJob)
        delete!(otherJobs, scheduleJob)
        S[scheduleJob] = t
        if lastCriticalJob !== nothing
            push!(criticalJobs[scheduleJob], lastCriticalJob)
        end
        if S[n+1] < S[scheduleJob] + q[scheduleJob] + p[scheduleJob]
            S[n+1] = S[scheduleJob] + q[scheduleJob] + p[scheduleJob]
            empty!(criticalJobs[n+1])
            push!(criticalJobs[n+1], scheduleJob)
        elseif S[n+1] == S[scheduleJob] + q[scheduleJob] + p[scheduleJob]
            push!(criticalJobs[n+1], scheduleJob)
        end
        for job in otherJobs
            if delay[scheduleJob,job] > 0 && r_prim[job] < t + delay[scheduleJob,job]
                r_prim[job] = t + delay[scheduleJob,job]
                empty!(artificialCriticalJobs[job])
                push!(artificialCriticalJobs[job], scheduleJob)
            elseif delay[scheduleJob,job] > 0 && r_prim[job] == t + delay[scheduleJob,job] && r_prim[job] != r[job]
                push!(artificialCriticalJobs[job], scheduleJob)
            end
        end
        if S[scheduleJob] + p[scheduleJob] >= minimum(job -> r_prim[job], otherJobs; init=typemax(Int))
            lastCriticalJob = scheduleJob
            t = S[scheduleJob] + p[scheduleJob]
        else
            lastCriticalJob = nothing
            t = minimum(job -> r_prim[job], otherJobs; init=typemax(Int))
        end
    end
    real_paths, artificial_paths = reconstruct_paths_schrange(n, criticalJobs, artificialCriticalJobs)
    return (U=U, S=S, real_paths=real_paths, artificial_paths=artificial_paths, Cmax = S[n+1])
end

function reconstruct_paths_schrange(n, criticalJobs, artificialCriticalJobs)
    real_paths = Vector{Vector{Int}}()
    real_paths_candidates = Vector{Vector{Int}}()
    artificial_paths = Vector{Vector{Int}}()
    artificial_paths_candidates = Vector{Vector{Int}}()
    push!(real_paths_candidates, [n+1])
    while !isempty(real_paths_candidates)
        path = pop!(real_paths_candidates)
        if criticalJobs[path[1]] == []
            push!(real_paths, path[1:end-1])
        else
            for job in criticalJobs[path[1]]
                pushfirst!(real_paths_candidates, [job; path])
            end
        end
        for job in artificialCriticalJobs[path[1]]
            pushfirst!(artificial_paths_candidates, [job])
        end
    end
    while !isempty(artificial_paths_candidates)
        path = pop!(artificial_paths_candidates)
        if criticalJobs[path[1]] == []
            push!(artificial_paths, path)
        else
            for job in criticalJobs[path[1]]
                pushfirst!(artificial_paths_candidates, [job; path])
            end
        end
        for job in artificialCriticalJobs[path[1]]
            pushfirst!(artificial_paths_candidates, [job])
        end
    end
    return real_paths, artificial_paths
end

struct DPCNode
    r::Vector{Int}
    q::Vector{Int}
    p::Vector{Int}
    delay::Vector{Vector{Int}}
    lowerBound::Int
end

h(J::Vector{Int}, r::Vector{Int}, q::Vector{Int}, p::Vector{Int}) = minimum(j->r[j], J) + sum(j->p[j], J) + minimum(j->q[j], J)

function dpc_sequence(p::Vector{Int}, r::Vector{Int}, q::Vector{Int}, delay::Vector{Vector{Int}})
    N = PriorityQueue{DPCNode, Int}

    schrage_result = schrage(p, r, q, delay)
    path_with_Jc = critical_path_with_jc(schrage_result, p, r, q, delay)
    J_c = path_with_Jc.J_c
    node = DPCNode(r, q, p, delay, h(path_with_Jc.path, r, q, p))
    while J_c ≠ 0
        delay1 = copy(node.delay)
        
    end

    

end

function critical_path_with_jc(schrage_result::NamedTuple, p::Vector{Int}, r::Vector{Int}, q::Vector{Int}, delay::Vector{Vector{Int}})
    Cmax = schrage_result.Cmax
    J_c = 0
    path_with_Jc::Union{Vector{Int},Nothing} = nothing
    path_type::Union{Symbol,Nothing} = nothing
    while J_c == 0 && !isempty(schrage_result.artificial_paths)
        path = pop!(schrage_result.artificial_paths)
        p = path[end]
        c = length(path) - 1
        for job in Iterators.drop(Iterators.reverse(path), 1)
            if delay[job, p] <= 0 && < Cmax - r[p] - p[p]
                J_c = c
                path_with_Jc = path[c+1:end]
                path_type = :artificial
                break
            end
            c -= 1
        end
    end
    if J_c == 0
        while J_c == 0 && !isempty(schrage_result.real_paths)
            path = pop!(schrage_result.real_paths)
            p = path[end]
            c = length(path) - 1
            for job in Iterators.drop(Iterators.reverse(path), 1)
                if q[job] < q[p] 
                    J_c = c
                    # do poprawienia
                    path_with_Jc = path[c+1:end]
                    path_type = :real
                    break
                end
                c -= 1
            end
        end
    end
    return (J_c=J_c, path=path_with_Jc, type=path_type)
end

function test_schrage()
    r = [0, 2, 5, 8, 10, 15]
    p = [4, 4, 2, 1, 3, 2]
    q = [9, 10, 13, 6, 7, 6]
    delay = [0 for _ in 1:6, _ in 1:6]
    delay[3,5] = 5
    println(schrage(p, r, q, delay))
end

test_schrage()