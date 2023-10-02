# using DataStructures

# """
# Safe dequeue function. If queue is empty, returns nothing instead of throwing an error.
# """
# dequeuesafe!(queue::PriorityQueue{K,V}) where {K,V} = isempty(queue) ? nothing : dequeue!(queue)

# """
# Safe first function. If queue is empty, returns nothing instead of throwing an error.
# """
# firstsafe(queue::PriorityQueue{K,V}) where {K,V} = isempty(queue) ? nothing : first(first(queue))

mutable struct DPCNode
    r::Vector{Int}
    q::Vector{Int}
    p::Vector{Int}
    delay::Matrix{Int}
    lowerBound::Int
end

struct Path
    J::Vector{Int}
    type::Symbol
end

Base.:(==)(p1::Path, p2::Path) = p1.J == p2.J && p1.type == p2.type

struct SchrageResult
    U::Vector{Int}
    S::Vector{Int}
    real_paths::Vector{Path}
    artificial_paths::Vector{Path}
    Cmax::Int
end

struct PathWithJc
    J_c::Int
    p::Int
    J::Vector{Int}
    type::Symbol
end
"""
Schrage algorithm is a heuristic algorithm used in Carlier modified branch and bound algorithm.
"""
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
        jobs = collect(otherJobs)
        jobsLessThanT = filter(job -> r_prim[job] <= t, jobs)
        scheduleJob = jobsLessThanT[findmax(job -> q[job], jobsLessThanT)[2]]
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
    return SchrageResult(U, S, real_paths, artificial_paths, S[n+1])
end

function reconstruct_paths_schrange(n, criticalJobs, artificialCriticalJobs)
    real_paths = Set{Path}()
    real_paths_candidates = Vector{Vector{Int}}()
    artificial_paths = Set{Path}()
    artificial_paths_candidates = Vector{Vector{Int}}()
    push!(real_paths_candidates, [n+1])
    while !isempty(real_paths_candidates)
        path = pop!(real_paths_candidates)
        if criticalJobs[path[1]] == []
            push!(real_paths, Path(path[1:end-1], :real))
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
            push!(artificial_paths, Path(path, :artificial))
        else
            for job in criticalJobs[path[1]]
                pushfirst!(artificial_paths_candidates, [job; path])
            end
        end
        for job in artificialCriticalJobs[path[1]]
            pushfirst!(artificial_paths_candidates, [job])
        end
    end
    return collect(real_paths), collect(artificial_paths)
end

h(J::Vector{Int}, r::Vector{Int}, q::Vector{Int}, p::Vector{Int}) = minimum(j->r[j], J) + sum(j->p[j], J) + minimum(j->q[j], J)

function dpc_sequence(p::Vector{Int}, r::Vector{Int}, q::Vector{Int}, delay::Matrix{Int})
    bestResult::Union{SchrageResult,Nothing} = nothing
    N = PriorityQueue{DPCNode, Int}()

    schrage_result::SchrageResult = schrage(p, r, q, delay)
    path_with_Jc::PathWithJc = critical_path_with_jc(schrage_result, p, r, q, delay)
    J_c = path_with_Jc.J_c
    P = path_with_Jc.p
    node = DPCNode(r, q, p, delay, h(path_with_Jc.J, r, q, p))
    f = node.lowerBound
    F = schrage_result.Cmax
    bestResult = schrage_result
    while J_c ≠ 0
        if path_with_Jc.type == :artificial
            node1 = deepcopy(node)
            node1.delay[J_c, P] = node1.p[J_c]
            modifiedDelay1 = [(J_c, P)]
            update_node!(node1, path_with_Jc, f; modifiedDelay=modifiedDelay1)
            test_feasibility(node1.p, node1.r, node1.q, node1.delay) || throw(ArgumentError("node1 is not feasible"))
            node1.lowerBound < F && enqueue!(N, node1, node1.lowerBound)

            node2 = deepcopy(node)
            modifiedDelay2 = NTuple{2,Int}[]
            for k in path_with_Jc.J
                node2.delay[k, J_c] = node2.p[k]
                push!(modifiedDelay2, (k, J_c))
            end
            update_node!(node2, path_with_Jc, f; modifiedDelay=modifiedDelay2)
            test_feasibility(node2.p, node2.r, node2.q, node2.delay) || throw(ArgumentError("node2 is not feasible"))
            node2.lowerBound < F && enqueue!(N, node2, node2.lowerBound)
        else
            node1 = deepcopy(node)
            node1.q[J_c] = max(node1.q[J_c], sum(j->node1.p[j], path_with_Jc.J) + node1.q[P])
            modifiedQ1 = [J_c]
            update_node!(node1, path_with_Jc, f; modifiedQ=modifiedQ1)
            test_feasibility(node1.p, node1.r, node1.q, node1.delay) || throw(ArgumentError("node1 is not feasible"))
            node1.lowerBound < F && enqueue!(N, node1, node1.lowerBound)

            node2 = deepcopy(node)
            node2.r[J_c] = max(node2.r[J_c], minimum(j->node2.r[j], path_with_Jc.J) + sum(j->node2.p[j], path_with_Jc.J))
            modifiedR2 = [J_c]
            update_node!(node2, path_with_Jc, f; modifiedR=modifiedR2)
            test_feasibility(node2.p, node2.r, node2.q, node2.delay) || throw(ArgumentError("node2 is not feasible"))
            node2.lowerBound < F && enqueue!(N, node2, node2.lowerBound)
        end
        J_c = 0
        f_γ = 0
        while J_c == 0 && !isempty(N) && F > f_γ
            node = dequeue!(N)
            schrage_result = schrage(node.p, node.r, node.q, node.delay)
            path_with_Jc = critical_path_with_jc(schrage_result, node.p, node.r, node.q, node.delay)
            J_c = path_with_Jc.J_c
            P = path_with_Jc.p
            f_γ = node.lowerBound
            f = max(f_γ, h(path_with_Jc.J, node.r, node.q, node.p))
            if schrage_result.U == [8, 9, 5, 6, 1, 7, 10, 2, 3, 4] && F == 972
            end
            if schrage_result.Cmax < F
                bestResult = schrage_result
                F = schrage_result.Cmax
                if path_with_Jc.type == :last 
                    return (bestResult.Cmax, bestResult.U)
                end 
            end
        end
    end
    return (bestResult.Cmax, bestResult.U)
end

function test_feasibility(p::Vector{Int}, r::Vector{Int}, q::Vector{Int}, delay::Matrix{Int})
    n = length(p)
    for i in 1:n
        for k in 1:n
            for j in 1:n
                if delay[i,k] > 0 && delay[k,j] > 0 && delay[i,j] < delay[i,k] + delay[k,j]
                    println("i=$i, k=$k, j=$j, delay[i,k]=$(delay[i,k]), delay[k,j]=$(delay[k,j]), delay[i,j]=$(delay[i,j])")
                    return false
                end
            end
        end
    end
    for i in 1:n
        for j in 1:n
            if delay[i,j] > 0 && r[j] < r[i] + delay[i,j]
                println("i=$i, j=$j, r[i]=$(r[i]), r[j]=$(r[j]), delay[i,j]=$(delay[i,j])")
                return false
            end
            if delay[i,j] > 0 && q[i] < q[j] + p[j] + delay[i,j] - p[i]
                println("i=$i, j=$j, q[i]=$(q[i]), q[j]=$(q[j]), p[j]=$(p[j]), p[i]=$(p[i]), delay[i,j]=$(delay[i,j])")
                return false
            end
        end
    end
    return true
end

function update_node!(node::DPCNode, path_with_Jc::PathWithJc, f; modifiedDelay::Vector{NTuple{2,Int}}=NTuple{2,Int}[], modifiedR::Vector{Int}=Int[], modifiedQ::Vector{Int}=Int[])
    p, r, q, delay = node.p, node.r, node.q, node.delay
    n = length(p)
    while !isempty(modifiedDelay)
        i, k = popfirst!(modifiedDelay)
        for j in axes(delay, 1)
            if delay[i, j] > 0 && delay[j, k] > 0 && delay[i, k] < delay[i, j] + delay[j, k]
                delay[i, k] = delay[i, j] + delay[j, k]
            end
        end
        if delay[i, k] > 0
            
            for j in axes(delay, 1)
                if delay[k, j] > 0 && delay[i, j] < delay[i, k] + delay[k, j]
                    delay[i, j] = delay[i, k] + delay[k, j]
                    push!(modifiedDelay, (i, j))
                end
            end
            for j in axes(delay,1)
                if delay[j,i] > 0 && delay[j,k] < delay[j,i] + delay[i,k]
                    delay[j,k] = delay[j,i] + delay[i,k]
                    push!(modifiedDelay, (j,k))
                end
            end
            if r[k] < r[i] + delay[i, k]
                r[k] = r[i] + delay[i, k]
                push!(modifiedR, k)
            end
            if q[i] < q[k] + p[k] + delay[i, k] - p[i]
                q[i] = q[k] + p[k] + delay[i, k] - p[i]
                push!(modifiedQ, i)
            end
        end
    end
    while !isempty(modifiedR)
        i = popfirst!(modifiedR)
        for j in axes(delay, 1)
            if delay[i, j] > 0 && r[j] < r[i] + delay[i, j]
                r[j] = r[i] + delay[i, j]
                push!(modifiedR, j)
            end
        end
    end
    while !isempty(modifiedQ)
        j = popfirst!(modifiedQ)
        for i in axes(delay, 1)
            if delay[i, j] > 0 && q[i] < q[j] + p[j] + delay[i, j] - p[i]
                q[i] = q[j] + p[j] + delay[i, j] - p[i]
                push!(modifiedQ, i)
            end
        end
    end
    node.lowerBound = max(f,h([path_with_Jc.J; path_with_Jc.J_c], r, q, p))
    return node
end

function critical_path_with_jc(schrage_result::SchrageResult, p::Vector{Int}, r::Vector{Int}, q::Vector{Int}, delay::Matrix{Int})
    Cmax = schrage_result.Cmax
    J_c = 0
    J::Union{Vector{Int},Nothing} = nothing
    allPaths = [schrage_result.real_paths; schrage_result.artificial_paths]
    sort_by = x -> findfirst(==(x.J[end]), schrage_result.U)
    sort!(allPaths, by = sort_by, rev = true)
    path_type::Union{Symbol,Nothing} = nothing
    while J_c == 0 && !isempty(allPaths)
        path = popfirst!(allPaths)
        if path.type == :artificial
            P = path.J[end]
            c = length(path.J) - 1
            for job in Iterators.drop(Iterators.reverse(path.J), 1)
                if delay[job, P] <= 0 && q[job] + p[job] < Cmax - r[P] - p[P]
                    J_c = job
                    J = path.J[c+1:end]
                    path_type = :artificial
                    break
                end
                c -= 1
            end
        else
            P = path.J[end]
            c = length(path.J) - 1
            for job in Iterators.drop(Iterators.reverse(path.J), 1)
                if q[job] < q[P] 
                    J_c = job
                    J = path.J[c+1:end]
                    path_type = :real
                    break
                end
                c -= 1
            end
        end
    end
    if J_c == 0
        return PathWithJc(0, length(p), collect(1:length(p)), :last)
    end
    return PathWithJc(J_c, J[end], J, path_type)
end



function test_schrage()
    # r = [0, 2, 5, 8, 10, 15]
    # p = [4, 4, 2, 1, 3, 2]
    # q = [9, 10, 13, 6, 7, 6]
    # delay = [0 for _ in 1:6, _ in 1:6]
    # delay[3,5] = 5
    # println(dpc_sequence(p, r, q, delay))
    # 23

    # r = [3,0]
    # p = [1,1]
    # q = [0,3]
    # delay = [0 0; 0 0]
    # delay[2,1] = 3
    # println(dpc_sequence(p, r, q, delay))
    # 4

    # r = [614, 594, 460, 612, 309, 442, 583, 287, 317, 615]
    # p = [11, 46, 10, 43, 61, 52, 21, 74, 51, 47]
    # q = [290, 142, 414, 0, 429, 358, 293, 451, 538, 212]
    # delay = [typemin(Int) for _ in 1:10, _ in 1:10]
    # for i in 1:10
    #     delay[i,i] = 0
    # end
    # println(dpc_sequence(p, r, q, delay))
    # 932

    # r = [35, 54, 5, 39, 57, 11]
    # p = [7, 4, 4, 3, 1, 3]
    # q = [9, 0, 51, 18, 0, 33]
    # delay = [0 for _ in 1:6, _ in 1:6]
    # delay[3,1] = 30
    # delay[3,2] = 49
    # delay[6,2] = 32
    # delay[3,4] = 34
    # delay[3,5] = 52
    # delay[6,5] = 35
    # println(dpc_sequence(p, r, q, delay))
    # 60

    # p = [9, 90, 74, 95, 14, 84, 13, 31, 85, 61]
    # q = [386, 417, 376, 730, 736, 560, 346, 822, 416, 381]
    # r = [520, 375, 371, 81, 0, 0, 502, 0, 368, 455]
    # delay = [0 for _ in 1:10, _ in 1:10]
    # delay[:,1] = [0, -9223372036854775288, -9223372036854775288, 401, 326, 249, -9223372036854775288, 429, -9223372036854775288, -9223372036854775288]
    # delay[:,2] = [-9223372036854775433, 0, -9223372036854775433, 294, 219, -9223372036854775433, -9223372036854775433, 322, -9223372036854775433, -9223372036854775433]
    # delay[:,3] = [-9223372036854775437, -9223372036854775437, 0, 290, 215, -9223372036854775437, -9223372036854775437, 318, -9223372036854775437, -9223372036854775437]
    # delay[:,4] = [-9223372036854775727, -9223372036854775727, -9223372036854775727, 0, -9223372036854775727, -9223372036854775727, -9223372036854775727, -9223372036854775727, -9223372036854775727, -9223372036854775727]
    # delay[:,5] = [-9223372036854775727, -9223372036854775727, -9223372036854775727, 0, -9223372036854775727, -9223372036854775727, -9223372036854775727, -9223372036854775727, -9223372036854775727, -9223372036854775727]
    # delay[:,6] = [-9223372036854775808, -9223372036854775808, -9223372036854775808, -9223372036854775808, -9223372036854775808, 0, -9223372036854775808, -9223372036854775808, -9223372036854775808, -9223372036854775808]
    # delay[:,7] = [-9223372036854775306, -9223372036854775306, -9223372036854775306, 421, 346, -9223372036854775306, 0, 449, -9223372036854775306, -9223372036854775306]
    # delay[:,8] = [-9223372036854775808, -9223372036854775808, -9223372036854775808, -9223372036854775808, -9223372036854775808, -9223372036854775808, -9223372036854775808, 0, -9223372036854775808, -9223372036854775808]
    # delay[:,9] = [-9223372036854775440, -9223372036854775440, -9223372036854775440, -9223372036854775440, -9223372036854775440, -9223372036854775440, -9223372036854775440, -9223372036854775440, 0, -9223372036854775440]
    # delay[:,10] = [-9223372036854775353, -9223372036854775353, -9223372036854775353, 373, 298, 184, -9223372036854775353, 401, -9223372036854775353, 0]
    # println(dpc_sequence(p, r, q, delay))
    # 1063

    p = [11, 46, 10, 43, 61, 52, 21, 74, 51, 47]
    r = [614, 681, 697, 707, 172, 311, 648, 218, 226, 683]
    q = [331, 176, 188, 0, 586, 546, 269, 590, 672, 187]
    delay = [0 for _ in 1:10, _ in 1:10]
    delay[:,1] = [0, -9223372036854775194, -9223372036854775194, -9223372036854775194, -9223372036854775194, -9223372036854775194, -9223372036854775194, -9223372036854775194, 381, -9223372036854775194]
    delay[:,2] = [-9223372036854775127, 0, -9223372036854775127, -9223372036854775127, -9223372036854775127, -9223372036854775127, -9223372036854775127, -9223372036854775127, 455, -9223372036854775127]
    delay[:,3] = [-9223372036854775111, -9223372036854775111, 0, -9223372036854775111, 398, 349, -9223372036854775111, 415, 460, -9223372036854775111]
    delay[:,4] = [-9223372036854775101, -9223372036854775101, -9223372036854775101, 0, -9223372036854775101, -9223372036854775101, -9223372036854775101, -9223372036854775101, 481, -9223372036854775101]
    delay[:,5] = [-9223372036854775636, -9223372036854775636, -9223372036854775636, -9223372036854775636, 0, -9223372036854775636, -9223372036854775636, -9223372036854775636, -9223372036854775636, -9223372036854775636]
    delay[:,6] = [-9223372036854775497, -9223372036854775497, -9223372036854775497, -9223372036854775497, -9223372036854775497, 0, -9223372036854775497, -9223372036854775497, -9223372036854775497, -9223372036854775497]
    delay[:,7] = [-9223372036854775160, -9223372036854775160, -9223372036854775160, -9223372036854775160, -9223372036854775160, -9223372036854775160, 0, -9223372036854775160, 415, -9223372036854775160]
    delay[:,8] = [-9223372036854775590, -9223372036854775590, -9223372036854775590, -9223372036854775590, -9223372036854775590, -9223372036854775590, -9223372036854775590, 0, -9223372036854775590, -9223372036854775590]
    delay[:,9] = [-9223372036854775582, -9223372036854775582, -9223372036854775582, -9223372036854775582, -9223372036854775582, -9223372036854775582, -9223372036854775582, -9223372036854775582, 0, -9223372036854775582]
    delay[:,10] = [-9223372036854775125, -9223372036854775125, -9223372036854775125, -9223372036854775125, 384, 335, -9223372036854775125, 401, 434, 0]
    println(dpc_sequence(p, r, q, delay))
    972
end

# test_schrage()

