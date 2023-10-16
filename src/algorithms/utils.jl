import Graphs.add_edge!

export YIELD_TIME
YIELD_TIME = 0.5

function try_yield(last_time::Union{Ref{Float64}, Nothing})
    if isnothing(last_time)
        return
    end
    if time() - last_time[] > YIELD_TIME
        # println("Yielding at $(time() - last_time[] )")
        yield()
        last_time[] = time()
    end
end

mutable struct ActiveScheduleNode
    Ω::Vector{Tuple{Int,Int}}
    lowerBound::Union{Int64,Nothing}
    graph::AbstractGraph
    scheduled::Dict{Tuple{Int64,Int64},Bool}
    r::Vector{Vector{Int64}}
end

function generateΩ_prim(node::ActiveScheduleNode, p::Vector{Vector{Int}}, μ::Vector{Vector{Int}})
    minimum, index = findmin(a -> p[a[1]][a[2]] + node.r[a[1]][a[2]], node.Ω)
    i, j = node.Ω[index]
    i_star = μ[i][j]
    Ω_prim = filter(a -> (node.r[a[1]][a[2]] < minimum && μ[a[1]][a[2]] == i_star), node.Ω)
    return Ω_prim
end

""" 
generates a release times for a given disjunctive graph
"""
function generate_release_times(graph::SimpleWeightedGraphAdj{Int, Int}, n_i::Vector{Int}, graphNodeToJob::Vector{Tuple{Int,Int}})
    rGraph = dag_paths(graph, 1, :longest)
    r = [[0 for _ in 1:a] for a in n_i]
    for (index, value) in enumerate(rGraph)
        if index == 1 || index == sum(n_i)+2 
            continue
        end
        i, j = graphNodeToJob[index]
        r[i][j] = value 
    end 
    return r, rGraph
end

"""
    Generate a sequence of jobs on a given machine, with a 1|r_j|Lmax criterion
"""
function generate_sequence(p::Vector{Vector{Int}}, r::Vector{Vector{Int}}, n_i::Vector{Int}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::SimpleWeightedGraphAdj{Int, Int}, Cmax::Int64, i::Int, yield_ref)
    newP = [p[job[1]][job[2]] for job in machineJobs[i]]
    newD::Vector{Int} = []
    newR = [r[job[1]][job[2]] for job in machineJobs[i]]
    for job in machineJobs[i]
        d = dag_paths(graph, jobToGraphNode[job[1]][job[2]], :longest)
        
        push!(newD, Cmax + p[job[1]][job[2]] - d[sum(n_i) + 2])
    end
    Lmax, sequence, microruns = single_machine_release_LMax(newP,newR,newD, yield_ref)
    try_yield(yield_ref)
    return Lmax, map(x -> machineJobs[i][x], sequence), microruns
end

function generate_sequence_pmtn(p::Vector{Vector{Int}}, r::Vector{Vector{Int}}, n_i::Vector{Int}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::SimpleWeightedGraphAdj{Int, Int}, Cmax::Int64, i::Int, yield_ref)
    newP = [p[job[1]][job[2]] for job in machineJobs[i]]
    newD::Vector{Int} = []
    newR = [r[job[1]][job[2]] for job in machineJobs[i]]
    for job in machineJobs[i]
        d = dag_paths(graph, jobToGraphNode[job[1]][job[2]], :longest)
        
        push!(newD, Cmax + p[job[1]][job[2]] - d[sum(n_i) + 2])
    end
    jobs = [JobData(newP[j], newR[j], newD[j], j, nothing) for j in 1:length(newP)]
    Lmax = single_machine_release_LMax_pmtn(jobs, JobData[])
    try_yield(yield_ref)
    return Lmax, 1
end


function generate_sequence_dpc(p::Vector{Vector{Int}}, r::Vector{Vector{Int}}, n_i::Vector{Int}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::SimpleWeightedGraphAdj{Int, Int}, Cmax::Int64, i::Int, yield_ref)
    newP = [p[job[1]][job[2]] for job in machineJobs[i]]
    newQ::Vector{Int} = []
    newR = [r[job[1]][job[2]] for job in machineJobs[i]]
    newDelay::Matrix{Int} = [0 for _ in 1:length(machineJobs[i]), _ in 1:length(machineJobs[i])]
    for (a, job) in enumerate(machineJobs[i])
        d = dag_paths(graph, jobToGraphNode[job[1]][job[2]], :longest)
        push!(newQ, d[sum(n_i) + 2] - p[job[1]][job[2]])
        for (b, job2) in enumerate(machineJobs[i])
            newDelay[a, b] = d[jobToGraphNode[job2[1]][job2[2]]]
        end
    end
    Cmax, sequence, microruns = dpc_sequence(newP, newR, newQ, newDelay, yield_ref)
    return Cmax, map(x -> machineJobs[i][x], sequence), microruns
end

function generate_data(p::Vector{Vector{Int}}, r::Vector{Vector{Int}}, n_i::Vector{Int}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::SimpleWeightedGraphAdj{Int, Int}, Cmax::Int64, i::Int)
    newP = [p[job[1]][job[2]] for job in machineJobs[i]]
    newQ::Vector{Int} = []
    newD::Vector{Int} = []
    newR = [r[job[1]][job[2]] for job in machineJobs[i]]
    newDelay::Matrix{Int} = [0 for _ in 1:length(machineJobs[i]), _ in 1:length(machineJobs[i])]
    for (a, job) in enumerate(machineJobs[i])
        d = dag_paths(graph, jobToGraphNode[job[1]][job[2]], :longest)
        push!(newQ, d[sum(n_i) + 2] - p[job[1]][job[2]])
        push!(newD, Cmax + p[job[1]][job[2]] - d[sum(n_i) + 2])
        for (b, job2) in enumerate(machineJobs[i])
            newDelay[a, b] = d[jobToGraphNode[job2[1]][job2[2]]]
        end
    end
    return newP, newR, newQ, newD, newDelay
end

"""
    Fix a disjunctive edges with a given sequence of jobs on a given machine
"""
function fix_disjunctive_edges(sequence::Vector{Tuple{Int,Int}}, jobToGraphNode::Vector{Vector{Int}}, graph::SimpleWeightedGraphAdj{Int, Int}, p::Vector{Vector{Int}}, machine::Int64, machineFixedEdges::Vector{Vector{Tuple{Int,Int}}})
    for (job1, job2) in Iterators.zip(sequence, Iterators.drop(sequence, 1))
        i1, j1 = job1[1], job1[2]
        i2, j2 = job2[1], job2[2]
        add_edge!(graph, jobToGraphNode[i1][j1], jobToGraphNode[i2][j2], p[i1][j1])
        push!(machineFixedEdges[machine], (jobToGraphNode[i1][j1],jobToGraphNode[i2][j2]))
    end
end
"""
Returns util arrays for given instance.
# Returns:
- Tuple `(jobToGraphNode, graphNodeToJob, machineJobs, machineWithJobs)`, where:
    - `jobToGraphNode::Vector{Vector{Int}}` - array of graph nodes for each job, i.e `jobToGraphNode[i][j]` is a graph node for job `i` and operation `j`
    - `graphNodeToJob::Vector{Tuple{Int,Int}}` - array of operations for each graph node, i.e `graphNodeToJob[a]=(i,j)` is a job and operation for graph node `a`
    - `machineJobs::Vector{Vector{Tuple{Int,Int}}}` - array of operations for each machine, i.e `machineJobs[μ]=[(i1,j1), (i2, j2)]` is a list of jobs for machine `μ`
    - `machineWithJobs::Vector{Vector{Vector{Tuple{Int,Int}}}} ` - array of operation for each machine and job, i.e `machineWithJobs[μ][i]=(i,j)` is a job and operation for machine `μ` and job `i`
"""
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

"""
Returns a graph with only conjuctive edges
"""
function generate_conjuctive_graph(n::Int, n_i::Vector{Int}, p::Vector{Vector{Int}}, jobToGraphNode::Vector{Vector{Int}})
    graph = SimpleWeightedGraphAdj(sum(n_i)+2, Int)
    for i in 1:n
        add_edge!(graph, 1, jobToGraphNode[i][1], 0)
        for j in 1:(n_i[i] - 1)
            add_edge!(graph, jobToGraphNode[i][j], jobToGraphNode[i][j+1], p[i][j])
        end
        add_edge!(graph, jobToGraphNode[i][n_i[i]], sum(n_i)+2, p[i][n_i[i]])
    end
    return graph
end

"""
Safe dequeue function. If queue is empty, returns nothing instead of throwing an error.
"""
dequeuesafe!(queue::PriorityQueue{K,V}) where {K,V} = isempty(queue) ? nothing : dequeue!(queue)

"""
Safe first function. If queue is empty, returns nothing instead of throwing an error.
"""
firstsafe(queue::PriorityQueue{K,V}) where {K,V} = isempty(queue) ? nothing : first(first(queue))