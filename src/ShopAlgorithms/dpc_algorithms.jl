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

function objective(schedule::Vector, p, r, q, delay)
    S = [0 for _ in 1:length(p)+1]
    S[schedule[1]] = r[schedule[1]]
    for (job1, job2) in Iterators.zip(schedule, Iterators.drop(schedule, 1))
        S[job2] = max(S[job1] + p[job1], r[job2], maximum([S[i] + delay[i, job2] for i in 1:job1 if delay[i, job2] > 0]; init=0))
    end
    return maximum(S[job] + p[job] + q[job] for job in schedule)
end

function objective2(p, r, q, delay)
    n = length(p)
    S = [0 for _ in 1:n+1]
    S[1] = r[1]
    for (job1, job2) in Iterators.zip(1:n, Iterators.drop(1:n, 1))
        S[job2] = max(S[job1] + p[job1], r[job2], maximum([S[i] + delay[i, job2] for i in 1:job1 if delay[i, job2] > 0]; init=0))
    end
    return maximum(S[job] + p[job] + q[job] for job in 1:n)
end

function check_sequence(schedule::Vector, p, r, n_i, graph, jobToGraphNode)
    newP = [p[job[1]][job[2]] for job in schedule]
    newQ::Vector{Int} = []
    newR = [r[job[1]][job[2]] for job in schedule]
    delay = [0 for _ in 1:length(schedule), _ in 1:length(schedule)]
    for (a, job) in enumerate(schedule)
        d = dag_paths(graph, jobToGraphNode[job[1]][job[2]], :longest)
        push!(newQ, d[sum(n_i) + 2] - p[job[1]][job[2]])
        for (b, job2) in enumerate(schedule)
            delay[a, b] = d[jobToGraphNode[job2[1]][job2[2]]]
        end
    end
    return objective2(newP, newR, newQ, delay)
end

function dpc_sequence(p::Vector{Int}, r::Vector{Int}, q::Vector{Int}, delay::Matrix{Int})
    bestResult::Union{SchrageResult,Nothing} = nothing
    N = PriorityQueue{DPCNode, Int}()
    map!(x->max(0,x), delay, delay)

    schrage_result::SchrageResult = schrage(p, r, q, delay)
    Cmax = objective(schrage_result.U, p, r, q, delay)
    path_with_Jc::PathWithJc = critical_path_with_jc(schrage_result, p, r, q, delay)
    J_c = path_with_Jc.J_c
    P = path_with_Jc.p
    node = DPCNode(r, q, p, delay, h(path_with_Jc.J, r, q, p))
    f = node.lowerBound
    F = Cmax
    bestResult = schrage_result
    while J_c ≠ 0
        if path_with_Jc.type == :artificial
            #println("artificial")
            # J_c before J_P
            node1 = deepcopy(node)
            node1.delay[J_c, P] = node1.p[J_c]
            modifiedDelay1 = [(J_c, P)]
            update_times!(node1, path_with_Jc, f; modifiedDelay=modifiedDelay1)
            node1.lowerBound = max(f,h([path_with_Jc.J; path_with_Jc.J_c], node1.r, node.q, p))
            test_feasibility(node1.p, node1.r, node1.q, node1.delay) || throw(ArgumentError("node1 is not feasible"))
            node1.lowerBound < F && enqueue!(N, node1, node1.lowerBound)

            # J_c after all jobs of J
            node2 = deepcopy(node)
            modifiedDelay2 = NTuple{2,Int}[]
            for k in path_with_Jc.J
                node2.delay[k, J_c] = node2.p[k]
                push!(modifiedDelay2, (k, J_c))
            end
            update_times!(node2, path_with_Jc, f; modifiedDelay=modifiedDelay2)
            node2.lowerBound = max(f,h([path_with_Jc.J; path_with_Jc.J_c], node2.r, node.q, p))
            test_feasibility(node2.p, node2.r, node2.q, node2.delay) || throw(ArgumentError("node2 is not feasible"))
            node2.lowerBound < F && enqueue!(N, node2, node2.lowerBound)
        else # real path
            #println("real")
            #before all jobs of J
            node1 = deepcopy(node)
            node1.q[J_c] = max(node1.q[J_c], sum(j->node1.p[j], path_with_Jc.J) + q[P])
            modifiedQ1 = [J_c]

            modifiedDelay1 = NTuple{2,Int}[]
            for k in path_with_Jc.J
                node1.delay[J_c, k] = node1.p[J_c]
                push!(modifiedDelay1, (J_c, k))
            end
            update_times!(node1, path_with_Jc, f; modifiedQ=modifiedQ1, modifiedDelay=modifiedDelay1)
            node1.lowerBound = max(f,h([path_with_Jc.J; path_with_Jc.J_c], node1.r, node.q, p))
            test_feasibility(node1.p, node1.r, node1.q, node1.delay) || throw(ArgumentError("node1 is not feasible"))
            node1.lowerBound < F && enqueue!(N, node1, node1.lowerBound)

            # after all job in J
            node2 = deepcopy(node)
            node2.r[J_c] = max(node2.r[J_c], minimum(j->node2.r[j], path_with_Jc.J) + sum(j->node2.p[j], path_with_Jc.J))
            modifiedR2 = [J_c]

            modifiedDelay2 = NTuple{2,Int}[]
            for k in path_with_Jc.J
                node2.delay[k, J_c] = node2.p[k]
                push!(modifiedDelay2, (k, J_c))
            end
            update_times!(node2, path_with_Jc, f; modifiedR=modifiedR2, modifiedDelay=modifiedDelay2)
            node2.lowerBound = max(f,h([path_with_Jc.J; path_with_Jc.J_c], node2.r, node.q, p))
            test_feasibility(node2.p, node2.r, node2.q, node2.delay) || throw(ArgumentError("node2 is not feasible"))
            node2.lowerBound < F && enqueue!(N, node2, node2.lowerBound)
        end
        J_c = 0
        f_γ = 0
        while J_c == 0 && !isempty(N) && F > f_γ
            node = dequeue!(N)
            
            schrage_result = schrage(node.p, node.r, node.q, node.delay)
            # if schrage_result.U[1:10] == [10,14,13,7,8,1,6,12,11,5]
            #     println("debug2")
            #     # println("node.q=$(node.q), node.r=$(node.r), node.q=$(node.q), node.delay=$(node.delay)")
            # end
            Cmax = objective(schrage_result.U, p, r, q, delay)
            path_with_Jc = critical_path_with_jc(schrage_result, node.p, node.r, node.q, node.delay)
            J_c = path_with_Jc.J_c
            P = path_with_Jc.p
            f_γ = node.lowerBound
            f = max(f_γ, h(path_with_Jc.J, node.r, node.q, p))
            #println("f_γ=$f_γ, f=$f, F=$F, J_c=$J_c, J=$(path_with_Jc.J), P=$P, result=$(schrage_result.U), Cmax=$(schrage_result.Cmax), type=$(path_with_Jc.type)")
            if Cmax < F
                bestResult = schrage_result
                F = Cmax
                # if path_with_Jc.type == :last 
                #     return (bestResult.Cmax, bestResult.U)
                # end 
            end
        end
    end
    return (F, bestResult.U)
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

function update_times!(node::DPCNode, path_with_Jc::PathWithJc, f; modifiedDelay::Vector{NTuple{2,Int}}=NTuple{2,Int}[], modifiedR::Vector{Int}=Int[], modifiedQ::Vector{Int}=Int[])
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
    
    return node
end

function critical_path_with_jc(schrage_result::SchrageResult, p::Vector{Int}, r::Vector{Int}, q::Vector{Int}, delay::Matrix{Int})
    Cmax = schrage_result.Cmax
    J_c = 0
    J::Union{Vector{Int},Nothing} = nothing
    allPaths = [schrage_result.real_paths; schrage_result.artificial_paths]
    sort_by = x -> findfirst(==(x.J[end]), schrage_result.U)
    sort!(allPaths, by = sort_by)
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
    # p = [18, 13, 14, 16, 19, 11, 15, 9, 17, 12, 15, 15, 7, 17]
    # r = [52, 150, 177, 175, 124, 84, 21, 38, 128, 0, 106, 93, 11, 0]
    # q = [34, 40, 8, 0, 43, 58, 160, 145, 0, 184, 20, 0, 176, 179]
    # d = [174, 168, 200, 208, 165, 150, 48, 63, 208, 24, 188, 208, 32, 29]
    # delay = [0 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 0 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 0 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 0 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 0 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 0 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 120 153 145 67 62 0 -9223372036854775770 104 -9223372036854775808 82 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 99 132 124 -9223372036854775684 41 -9223372036854775787 0 83 -9223372036854775808 61 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 0 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 141 174 166 -9223372036854775684 83 -9223372036854775787 -9223372036854775770 125 0 103 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 0 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 0 -9223372036854775797 -9223372036854775808; -9223372036854775756 125 152 150 99 -9223372036854775724 -9223372036854775787 -9223372036854775770 103 -9223372036854775808 81 -9223372036854775715 0 -9223372036854775808; -9223372036854775756 141 174 166 88 83 -9223372036854775787 -9223372036854775770 125 -9223372036854775808 103 -9223372036854775715 -9223372036854775797 0]
    # println(dpc_sequence(p, r, q, delay))
    # println(objective(#=[10, 14, 13, 7, 8, 1, 6, 12, 11, 5, 2, 9, 3, 4]=#[10, 14, 13, 7, 8, 1, 12, 6, 5, 9, 2, 11, 3, 4], p, r, q, delay))

    p = [18, 13, 14, 16, 19, 11, 15, 9, 17, 12, 15, 15, 7, 17]
    r = [52, 150, 177, 175, 124, 84, 21, 38, 128, 0, 106, 93, 11, 0]
    q = [34, 40, 8, 0, 43, 58, 160, 145, 0, 184, 20, 0, 176, 179]
    delay = [0 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 0 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 0 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 0 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 0 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 0 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 120 153 145 67 62 0 -9223372036854775770 104 -9223372036854775808 82 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 99 132 124 -9223372036854775684 41 -9223372036854775787 0 83 -9223372036854775808 61 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 0 -9223372036854775808 -9223372036854775702 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 141 174 166 -9223372036854775684 83 -9223372036854775787 -9223372036854775770 125 0 103 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 0 -9223372036854775715 -9223372036854775797 -9223372036854775808; -9223372036854775756 -9223372036854775658 -9223372036854775631 -9223372036854775633 -9223372036854775684 -9223372036854775724 -9223372036854775787 -9223372036854775770 -9223372036854775680 -9223372036854775808 -9223372036854775702 0 -9223372036854775797 -9223372036854775808; -9223372036854775756 125 152 150 99 -9223372036854775724 -9223372036854775787 -9223372036854775770 103 -9223372036854775808 81 -9223372036854775715 0 -9223372036854775808; -9223372036854775756 141 174 166 88 83 -9223372036854775787 -9223372036854775770 125 -9223372036854775808 103 -9223372036854775715 -9223372036854775797 0]
    println(dpc_sequence(p, r, q, delay))
    println(objective(#=[10, 14, 13, 7, 8, 1, 6, 12, 11, 5, 2, 9, 3, 4]=#[10, 14, 13, 7, 8, 1, 12, 6, 5, 9, 2, 11, 3, 4], p, r, q, delay))

end

# test_schrage()

