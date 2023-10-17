export dag_paths, topological_sort_util
using ..ShopAlgorithms

"""
    dag_paths(graph::SimpleWeightedGraphAdj{V,U}, source::V, type::Symbol) where {V<:Integer, U<:Real}

Returns all paths from the source vertex to all other vertices in a directed acyclic graph (DAG).

# Arguments
- `graph::SimpleWeightedGraphAdj{V,U}`: A directed acyclic graph.
- `source::V`: The source vertex.
- `type::Symbol`: The type of path to return. Possible values are `:shortest` and `:longest`.
- `reversed::Bool`: Whether to use the reversed graph.

# Returns
- `dist::Vector{V}`: A vector of distances from the source vertex to all other vertices.

# Throws
- `ArgumentError`: If the type is not `:shortest` or `:longest`, or if the graph is not a DAG.
"""
function dag_paths(graph::SimpleDirectedWeightedGraphAdj{V,U}, source::V, type::Symbol; reversed=false) where {V<:Integer, U<:Real} 
    
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
    edges = reversed ? graph.edges_transpose : graph.edges
    if reversed
        for i in length(graph.vertices):-1:1
            if !visited[i]
                topological_sort_util(graph, visited, pathVis, stack, i, reversed)
            end
        end
    else
        for i in 1:length(graph.vertices)
            if !visited[i]
                topological_sort_util(graph, visited, pathVis, stack, i, reversed)
            end
        end
    end

    dist[source] = 0

    while !isempty(stack)
        v = pop!(stack)
        for edge in edges[v]
            if type == :longest
                dist[edge.dst] = max(dist[edge.dst], dist[v] + edge.weight)
            elseif type == :shortest
                dist[edge.dst] = min(dist[edge.dst], dist[v] + edge.weight)
            end
        end
    end

    return dist
end

"""
    topological_sort_util(graph::SimpleWeightedGraphAdj{V,U}, visited::BitVector, pathVis::BitVector, stack::Stack{V}, v::V) where {V<:Integer, U<:Real}

A utility function used in topological sorting of a directed acyclic graph (DAG). This function recursively visits all the vertices adjacent to the given vertex `v` and adds them to the stack in topological order. It also detects cycles in the graph by keeping track of the visited vertices and the vertices in the current path.

# Arguments
- `graph::SimpleWeightedGraphAdj{V,U}`: The directed acyclic graph to be sorted.
- `visited::BitVector`: A bit vector to keep track of the visited vertices.
- `pathVis::BitVector`: A bit vector to keep track of the vertices in the current path.
- `stack::Stack{V}`: A stack to store the vertices in topological order.
- `v::V`: The vertex to be visited.
- `reversed::Bool`: Whether to use the reversed graph.

# Returns
- `nothing`

# Throws
- `ArgumentError`: If the graph is not a DAG.
"""
function topological_sort_util(graph::SimpleDirectedWeightedGraphAdj{V,U}, visited::BitVector, pathVis::BitVector, stack::Stack{V}, v::V, reversed::Bool) where {V<:Integer, U<:Real}
    visited[v] = true
    pathVis[v] = true
    edges = reversed ? graph.edges_transpose : graph.edges
    for edge in edges[v]
        if !visited[edge.dst]
            topological_sort_util(graph, visited, pathVis, stack, edge.dst, reversed)
        elseif pathVis[edge.dst]
            throw(ArgumentError("Graph is not a DAG"))
        end
    end
    pathVis[v] = false
    push!(stack, v)
end