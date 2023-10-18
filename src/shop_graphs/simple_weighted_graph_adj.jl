import Base.getindex
import Graphs: add_edge!, add_vertex!
# import Graphs: add_edge!, rem_edge!, AbstractGraph, AbstractEdge, has_edge, has_vertex, add_vertex!
export SimpleDirectedWeightedGraphAdj, SimpleDirectedWeightedEdge

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
mutable struct SimpleDirectedWeightedEdge{T<:Integer, U<:Real} <: AbstractEdge{T}
    src::T
    dst::T
    weight::U
end

function Base.show(io::IO, edge::SimpleDirectedWeightedEdge{T,U}) where {T<:Integer, U<:Real}
    print(io, "SimpleDirectedWeightedEdge(", edge.src, ", ", edge.dst, ", ", edge.weight, ")")
end

"""
    SimpleWeightedGraphAdj{T<:Integer, U<:Real}

A simple directed weighted graph implementation using an adjacency list representation.

# Fields
- `vertices::Vector{T}`: A vector of vertices of type `T`.
- `edges::Vector{Vector{SimpleWeightedEdge{T,U}}}`: A vector of edges represented as a vector of `SimpleWeightedEdge{T,U}`.

# Constructors
- `SimpleWeightedGraphAdj{T,U}(vertices::Vector{T}, edges::Vector{Vector{SimpleWeightedEdge{T,U}}})`: Constructs a new `SimpleWeightedGraphAdj{T,U}` object with the given vertices and edges.

"""
mutable struct SimpleDirectedWeightedGraphAdj{T<:Integer, U<:Real} <: AbstractGraph{T}
    vertices::Vector{T}
    edges::Vector{Vector{SimpleDirectedWeightedEdge{T,U}}}
    edges_transpose::Vector{Vector{SimpleDirectedWeightedEdge{T,U}}}
    function SimpleDirectedWeightedGraphAdj{T,U}(
        vertices::Vector{T},
        edges::Vector{Vector{SimpleDirectedWeightedEdge{T,U}}}
    ) where {T<:Integer, U<:Real}
        isequal(length(vertices), length(edges)) || error("Edge vector does not have the same size as vertices vector")
        for vertex in vertices
            for edge in edges[vertex]
                if !(edge.src ∈ vertices && edge.dst ∈ vertices)
                    error("Edge source or destination is not in the vertices vector")
                end
            end
        end
        edges_transpose = [SimpleDirectedWeightedEdge{T,U}[] for _ in vertices]
        for vertex in vertices
            for edge in edges[vertex]
                push!(edges_transpose[edge.dst], SimpleDirectedWeightedEdge(edge.dst, edge.src, edge.weight))
            end
        end



        new{T,U}(vertices, edges, edges_transpose)
    end
end

function Base.show(io::IO, graph::SimpleDirectedWeightedGraphAdj{T,U}) where {T<:Integer, U<:Real}
    println(io, "SimpleDirectedWeightedGraphAdj{", T, ", ", U, "}(")
    print(io, "    vertices = ", graph.vertices, "\n")
    print(io, "    edges = [\n")
    for vertex in graph.vertices
        print(io, "        ")
        show(io, graph.edges[vertex])
        print(io, "\n")
    end
    print(io, "    ]\n")
    print(io, ")")
end

function SimpleDirectedWeightedGraphAdj(n::T, ::Type{U}) where {T<:Integer, U<:Real}
    vertices = [i for i in 1:n]
    edges::Vector{Vector{SimpleDirectedWeightedEdge{T,U}}} = [[] for _ in 1:n]
    SimpleDirectedWeightedGraphAdj{T,U}(vertices, edges)
end
function SimpleDirectedWeightedGraphAdj(n::T, edges::Vector{Vector{SimpleDirectedWeightedEdge{T,U}}}) where {T<:Integer, U<:Real}
    vertices = [i for i in 1:n]
    SimpleDirectedWeightedGraphAdj{T,U}(vertices, edges)
end

function Graphs.add_edge!(graph::SimpleDirectedWeightedGraphAdj{T,U}, src::T, dst::T, weight::U) where {T<:Integer, U<:Real}
    push!(graph.edges[src], SimpleDirectedWeightedEdge(src, dst, weight))
    push!(graph.edges_transpose[dst], SimpleDirectedWeightedEdge(dst, src, weight))
end

function Graphs.add_edge!(graph::SimpleDirectedWeightedGraphAdj, edge::SimpleDirectedWeightedEdge{T,U}) where {T<:Integer, U<:Real} 
    push!(graph.edges[edge.src], edge)
    push!(graph.edges_transpose[edge.dst], SimpleDirectedWeightedEdge(edge.dst, edge.src, edge.weight))
end

Graphs.has_edge(graph::SimpleDirectedWeightedGraphAdj, src::T, dst::T) where {T<:Integer} = any(x -> x.dst == dst, graph.edges[src])

function Graphs.rem_edge!(graph::SimpleDirectedWeightedGraphAdj, src::T, dst::T) where {T<:Integer}
    filter!(x -> x.dst ≠ dst, graph.edges[src])
    filter!(x -> x.dst ≠ src, graph.edges_transpose[dst])
end

Graphs.has_vertex(graph::SimpleDirectedWeightedGraphAdj, v::T) where {T<:Integer} = v ∈ graph.vertices

Graphs.add_vertex!(graph::SimpleDirectedWeightedGraphAdj, v::T) where {T<:Integer} = push!(graph.vertices, v)

Graphs.outneighbors(graph::SimpleDirectedWeightedGraphAdj, v::T) where {T<:Integer} = [edge.dst for edge in graph.edges[v]]
Graphs.inneighbors(graph::SimpleDirectedWeightedGraphAdj, v::T) where {T<:Integer} = [edge.dst for edge in graph.edges_transpose[v]]

function Base.getindex(graph::SimpleDirectedWeightedGraphAdj, i::Integer, j::Integer, ::Val{:weight})
    for edge in graph.edges[i]
        if edge.dst == j
            return edge.weight
        end
    end
    return nothing
end 




