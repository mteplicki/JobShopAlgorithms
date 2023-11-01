import Graphs.add_edge!

export YIELD_TIME
const YIELD_TIME = 0.5

Base.sizehint!(queue::PriorityQueue{K,V}) where {K,V} = begin 
    sizehint!(queue.xs)
    sizehint!(queue.index)
end

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

@kwdef mutable struct ActiveScheduleNode
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
function generate_release_times(graph::AbstractGraph, n_i::Vector{Int}, graphNodeToJob::Vector{Tuple{Int,Int}})
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
function generate_sequence(instance::JobShopInstance, r::Vector{Vector{Int}}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::AbstractGraph, Cmax::Int64, i::Int, yield_ref)
    if length(machineJobs[i]) == 0
        throw(DimensionMismatch("Machine $i has no jobs assigned"))
    end
    p, n_i = instance.p, instance.n_i
    d = dag_paths(graph, sum(n_i) + 2, :longest; reversed = true)
    newP = Int64[p[job[1]][job[2]] for job in machineJobs[i]]
    newR = Int64[r[job[1]][job[2]] for job in machineJobs[i]]
    newD = Int64[Cmax + p[job[1]][job[2]] - d[jobToGraphNode[job[1]][job[2]]] for job in machineJobs[i]]
    Lmax, sequence, microruns = single_machine_release_LMax(newP,newR,newD, yield_ref)
    try_yield(yield_ref)
    return Lmax, map(x -> machineJobs[i][x], sequence), microruns
end

function generate_sequence_carlier(instance::JobShopInstance, r::Vector{Vector{Int}}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::AbstractGraph, i::Int, yield_ref; with_priority_queue::Bool = true, carlier_timeout::Union{Nothing,Float64} = nothing)
    if length(machineJobs[i]) == 0
        throw(DimensionMismatch("Machine $i has no jobs assigned"))
    end
    p, n_i = instance.p, instance.n_i
    d = dag_paths(graph, sum(n_i) + 2, :longest; reversed = true)
    newP = Int64[p[job[1]][job[2]] for job in machineJobs[i]]
    newR = Int64[r[job[1]][job[2]] for job in machineJobs[i]]
    newQ = Int64[d[jobToGraphNode[job[1]][job[2]]] - p[job[1]][job[2]] for job in machineJobs[i]]
    Cmax, sequence, microruns = carlier(newP,newR,newQ, yield_ref; with_priority_queue = with_priority_queue, carlier_timeout =carlier_timeout)
    try_yield(yield_ref)
    return Cmax, map(x -> machineJobs[i][x], sequence), microruns
end

function generate_sequence_pmtn(instance::JobShopInstance, r::Vector{Vector{Int}}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::AbstractGraph, Cmax::Int, i::Int, yield_ref)
    if length(machineJobs[i]) == 0
        throw(DimensionMismatch("Machine $i has no jobs assigned"))
    end
    p, n_i = instance.p, instance.n_i
    d = dag_paths(graph, sum(n_i) + 2, :longest; reversed = true)
    newP = [p[job[1]][job[2]] for job in machineJobs[i]]
    newR = [r[job[1]][job[2]] for job in machineJobs[i]]
    newD = [Cmax + p[job[1]][job[2]] - d[jobToGraphNode[job[1]][job[2]]] for job in machineJobs[i]]
    jobs = [JobData(newP[j], newR[j], newD[j], j, nothing) for j in 1:length(newP)]
    Lmax, _  = single_machine_release_LMax_pmtn(jobs, JobData[])
    try_yield(yield_ref)
    return Lmax, 1
end


function generate_sequence_dpc(instance:: JobShopInstance, r::Vector{Vector{Int}}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::AbstractGraph, i::Int, yield_ref; with_priority_queue::Bool = true, carlier_timeout::Union{Nothing,Float64} = nothing)
    if length(machineJobs[i]) == 0
        throw(DimensionMismatch("Machine $i has no jobs assigned"))
    end
    p, n_i = instance.p, instance.n_i
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
    Cmax, sequence, microruns = carlier_dpc(newP, newR, newQ, newDelay, yield_ref; with_priority_queue = with_priority_queue, carlier_timeout =carlier_timeout)
    return Cmax, map(x -> machineJobs[i][x], sequence), microruns
end

function generate_data(p::Vector{Vector{Int}}, r::Vector{Vector{Int}}, n_i::Vector{Int}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::AbstractGraph, Cmax::Int64, i::Int)
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
function fix_disjunctive_edges(sequence::Vector{Tuple{Int,Int}}, jobToGraphNode::Vector{Vector{Int}}, graph::AbstractGraph, p::Vector{Vector{Int}}, machine::Int64, machineFixedEdges::Vector{Vector{Tuple{Int,Int}}})
    for (job1, job2) in Iterators.zip(sequence, Iterators.drop(sequence, 1))
        i1, j1 = job1[1], job1[2]
        i2, j2 = job2[1], job2[2]
        if !(i1 == i2 && j1 == j2 - 1)
            add_edge!(graph, jobToGraphNode[i1][j1], jobToGraphNode[i2][j2], p[i1][j1])
            push!(machineFixedEdges[machine], (jobToGraphNode[i1][j1],jobToGraphNode[i2][j2]))
        end
    end
end
"""
Returns util arrays for given instance.
# Returns:
- Tuple `(jobToGraphNode, graphNodeToJob, machineJobs, machineWithJobs)`, where:
    - `jobToGraphNode::Vector{Vector{Int}}` - array of graph nodes for each job, i.e `jobToGraphNode[i][j]` is a graph node for job `i` and operation `j`
    - `graphNodeToJob::Vector{Tuple{Int,Int}}` - array of operations for each graph node, i.e `graphNodeToJob[a]=(i,j)` is a job and operation for graph node `a`
    - `machineJobs::Vector{Vector{Tuple{Int,Int}}}` - array of operations for each machine, i.e `machineJobs[μ]=[(i1,j1), (i2, j2)]` is a list of jobs for machine `μ`
    - `machineWithJobs::Vector{Vector{Vector{Tuple{Int,Int}}}} ` - array of operation for each machine and job, i.e `machineWithJobs[μ][i]=[(i,j1),(i,j2)]` is a job and operation for machine `μ` and job `i`
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
    graph = SimpleDiWeightedGraphAdj(sum(n_i)+2, Int)
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