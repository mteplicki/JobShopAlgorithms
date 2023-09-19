function generateReleaseTimes(graph::SimpleWeightedGraphAdj{Int, Int}, n_i::Vector{Int}, graphNodeToJob::Vector{Tuple{Int,Int}})
    rGraph = DAGpaths(graph, 1, :longest)
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

function generateSequence(p::Vector{Vector{Int}}, r::Vector{Vector{Int}}, n_i::Vector{Int}, machineJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::SimpleWeightedGraphAdj{Int, Int}, Cmax::Int64, i::Int)
    indices::Vector{Int} = [job[1] for job in machineJobs[i]]
    newP = [p[job[1]][job[2]] for job in machineJobs[i]]
    newD::Vector{Int} = []
    newR = [r[job[1]][job[2]] for job in machineJobs[i]]
    for job in machineJobs[i]
        d = DAGpaths(graph, jobToGraphNode[job[1]][job[2]], :longest)
        push!(newD, Cmax + p[job[1]][job[2]] - d[sum(n_i) + 2])
    end

    return SingleMachineReleaseLMax(newP,newR,newD, indices)
end

function fixDisjunctiveEdges(sequenceCandidate::Vector{Int}, machineWithJobs::Vector{Vector{Tuple{Int,Int}}}, jobToGraphNode::Vector{Vector{Int}}, graph::SimpleWeightedGraphAdj{Int, Int}, p::Vector{Vector{Int}}, fixMachine::Int64, machineFixedEdges::Vector{Vector{Tuple{Int,Int}}})
    for (job1, job2) in Iterators.zip(sequenceCandidate, Iterators.drop(sequenceCandidate, 1))
        i1, j1 = machineWithJobs[fixMachine][job1]
        i2, j2 = machineWithJobs[fixMachine][job2]
        add_edge!(graph, jobToGraphNode[i1][j1], jobToGraphNode[i2][j2], p[i1][j1])
        push!(machineFixedEdges[fixMachine], (jobToGraphNode[i1][j1],jobToGraphNode[i2][j2]))
    end
end