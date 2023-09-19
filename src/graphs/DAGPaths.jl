# dodaj sortowanie topologiczne

function DAGpaths(graph::SimpleWeightedGraphAdj{V,U}, source::V, type::Symbol) where {V<:Integer, U<:Real} 
    
    if type == :longest
        dist = fill(typemin(V), length(graph.vertices))
    elseif type == :shortest
        dist = fill(typemax(V), length(graph.vertices))
    else
        throw(ArgumentError("type must be :longest or :shortest"))
    end
    visited = falses(length(graph.vertices))
    pathVis = falses(length(graph.vertices))
    stack = Stack{V}()
    for i in 1:length(graph.vertices)
        if !visited[i]
            topologicalSortUtil(graph, visited, pathVis, stack, i)
        end
    end

    dist[source] = 0

    while !isempty(stack)
        v = pop!(stack)
        for edge in graph.edges[v]
            if type == :longest
                dist[edge.dst] = max(dist[edge.dst], dist[v] + edge.weight)
            elseif type == :shortest
                dist[edge.dst] = min(dist[edge.dst], dist[v] + edge.weight)
            end
        end
    end

    

    return dist
end

function topologicalSortUtil(graph::SimpleWeightedGraphAdj{V,U}, visited::BitVector, pathVis::BitVector, stack::Stack{V}, v::V) where {V<:Integer, U<:Real}
    visited[v] = true
    pathVis[v] = true
    for edge in graph.edges[v]
        if !visited[edge.dst]
            topologicalSortUtil(graph, visited, pathVis, stack, edge.dst)
        elseif pathVis[edge.dst]
            throw(ArgumentError("Graph is not a DAG"))
        end
    end
    pathVis[v] = false
    push!(stack, v)
end

# function dfs(graph::SimpleWeightedGraphAdj{V,U}, dp::Vector{V}, visited::BitVector, v::V, type::Symbol) where {V<:Integer, U<:Real}
#     visited[v] = true
#     for edge in graph.edges[v]
#         if !visited[edge.dst]
#             dfs(graph, dp, visited, edge.dst, type)
#         end
#         if type == :longest
#             dp[v] = max(dp[v], dp[edge.dst] + edge.weight)
#         elseif type == :shortest
#             dp[v] = min(dp[v], dp[edge.dst] + edge.weight)
#         end
#     end
# end
