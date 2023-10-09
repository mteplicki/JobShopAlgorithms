import Base.getindex
import Graphs: add_edge!, add_vertex!
# import Graphs: add_edge!, rem_edge!, AbstractGraph, AbstractEdge, has_edge, has_vertex, add_vertex!
export SimpleWeightedGraphAdj, SimpleWeightedEdge

"""
    mutable struct SimpleWeightedEdge{T<:Integer, U<:Real} <: AbstractEdge{T}

SimpleWeightedEdge is a mutable struct that represents a weighted edge in a graph. It contains the source vertex, destination vertex, and weight of the edge.

# Arguments
- `src::T`: The source vertex of the edge.
- `dst::T`: The destination vertex of the edge.
- `weight::U`: The weight of the edge.

# Type parameters
- `T<:Integer`: The type of the vertices.
- `U<:Real`: The type of the weight.

"""
mutable struct SimpleWeightedEdge{T<:Integer, U<:Real} <: AbstractEdge{T}
    src::T
    dst::T
    weight::U
end

"""
    SimpleWeightedGraphAdj{T<:Integer, U<:Real}

A simple weighted graph implementation using an adjacency list representation.

# Fields
- `vertices::Vector{T}`: A vector of vertices of type `T`.
- `edges::Vector{Vector{SimpleWeightedEdge{T,U}}}`: A vector of edges represented as a vector of `SimpleWeightedEdge{T,U}`.

# Constructors
- `SimpleWeightedGraphAdj{T,U}(vertices::Vector{T}, edges::Vector{Vector{SimpleWeightedEdge{T,U}}})`: Constructs a new `SimpleWeightedGraphAdj{T,U}` object with the given vertices and edges.

"""
mutable struct SimpleWeightedGraphAdj{T<:Integer, U<:Real} <: AbstractGraph{T}
    vertices::Vector{T}
    edges::Vector{Vector{SimpleWeightedEdge{T,U}}}
    function SimpleWeightedGraphAdj{T,U}(
        vertices::Vector{T},
        edges::Vector{Vector{SimpleWeightedEdge{T,U}}}
    ) where {T<:Integer, U<:Real}
        isequal(length(vertices), length(edges)) || error("Edge vector does not have the same size as vertices vector")
        new{T,U}(vertices, edges)
    end
end

function SimpleWeightedGraphAdj(n::T, ::Type{U}) where {T<:Integer, U<:Real}
    vertices = [i for i in 1:n]
    edges::Vector{Vector{SimpleWeightedEdge{T,U}}} = [[] for _ in 1:n]
    SimpleWeightedGraphAdj{T,U}(vertices, edges)
end
function SimpleWeightedGraphAdj(n::T, edges::Vector{Vector{SimpleWeightedEdge{T,U}}}) where {T<:Integer, U<:Real}
    vertices = [i for i in 1:n]
    SimpleWeightedGraphAdj{T,U}(vertices, edges)
end

function Graphs.add_edge!(graph::SimpleWeightedGraphAdj{T,U}, src::T, dst::T, weight::U) where {T<:Integer, U<:Real}
    push!(graph.edges[src], SimpleWeightedEdge(src, dst, weight))
end

Graphs.add_edge!(graph::SimpleWeightedGraphAdj, edge::SimpleWeightedEdge{T,U}) where {T<:Integer, U<:Real} = push!(graph.edges[edge.src], edge)

Graphs.has_edge(graph::SimpleWeightedGraphAdj, src::T, dst::T) where {T<:Integer} = any(x -> x.dst == dst, graph.edges[src])

Graphs.rem_edge!(graph::SimpleWeightedGraphAdj, src::T, dst::T) where {T<:Integer} = filter!(x -> x.dst ≠ dst, graph.edges[src])

Graphs.has_vertex(graph::SimpleWeightedGraphAdj, v::T) where {T<:Integer} = v ∈ graph.vertices

Graphs.add_vertex!(graph::SimpleWeightedGraphAdj, v::T) where {T<:Integer} = push!(graph.vertices, v)

function Base.getindex(graph::SimpleWeightedGraphAdj, i::Integer, j::Integer, ::Val{:weight})
    for edge in graph.edges[i]
        if edge.dst == j
            return edge.weight
        end
    end
    return nothing
end 




