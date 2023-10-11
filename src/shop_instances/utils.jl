export check_feasability

function generate_util_arrays(n, m, n_i, μ)
    jobToGraphNode::Vector{Vector{Int}} = [[0 for _ in 1:n_i[i]] for i in 1:n]
    graphNodeToJob::Vector{Tuple{Int,Int}} = [(0,0) for _ in 1:(sum(n_i) + 2)]
    machineJobs::Vector{Vector{Tuple{Int,Int}}} = [[] for _ in 1:m]
    machineWithJobs::Vector{Vector{Vector{Tuple{Int,Int}}}} = [[[] for _ in 1:n] for _ in 1:m]

    counter = 2
    for i in 1:n
        for j in 1:n_i[i]
            jobToGraphNode[i][j] = counter
            graphNodeToJob[counter] = (i,j)
            push!(machineJobs[μ[i][j]], (i,j))
            counter += 1
            push!(machineWithJobs[μ[i][j]][i], (i,j))
        end
    end
    return jobToGraphNode, graphNodeToJob, machineJobs, machineWithJobs
end

function check_feasability(schedule::ShopSchedule)
    _, _ , machine_jobs, _ = generate_util_arrays(schedule.instance.n, schedule.instance.m, schedule.instance.n_i, schedule.instance.μ)
    for machine in 1:schedule.instance.m
        for job1 in machine_jobs[machine]
            for job2 in machine_jobs[machine]
                if schedule.C[job1[1]][job1[2]] > (schedule.C[job2[1]][job2[2]] - schedule.instance.p[job2[1]][job2[2]]) && schedule.C[job1[1]][job1[2]] < schedule.C[job2[1]][job2[2]]
                    @error "Feasability check failed: job $(job1[1]) operation $(job1[2]) is executed on machine $(machine) between job $(job2[1]) operation $(job2[2])"
                    return false
                end
            end
        end
    end
    for job in 1:schedule.instance.n
        for operation in 1:schedule.instance.n_i[job]
            for operation_prim in 1:(operation-1)
                if schedule.C[job][operation] - schedule.instance.p[job][operation]  < schedule.C[job][operation_prim] 
                    @error "Feasability check failed: job $(job) operation $(operation) is executed before operation $(operation_prim)"
                    return false
                end
            end
        end
    end
    return true
    
end