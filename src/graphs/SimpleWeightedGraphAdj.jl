using Graphs
import Base.getindex
import Graphs: add_edge!, rem_edge!, AbstractGraph, AbstractEdge, has_edge, has_vertex, add_vertex!
export SimpleWeightedGraphAdj

mutable struct SimpleWeightedEdge{T<:Integer, U<:Real} <: AbstractEdge{T}
    src::T
    dst::T
    weight::U
end

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




