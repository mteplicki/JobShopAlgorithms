import Base.getindex
import Graphs: add_edge!, add_vertex!
# import Graphs: add_edge!, rem_edge!, AbstractGraph, AbstractEdge, has_edge, has_vertex, add_vertex!
export SimpleDiWeightedGraphAdj, DiWeightedEdge

"""
    mutable struct DiWeightedEdge{T<:Integer, U<:Real} <: AbstractEdge{T}

        DiWeightedEdge is a mutable struct that represents a weighted edge in a graph. It contains the source vertex, destination vertex, and weight of the edge.

# Arguments
- `src::T`: The source vertex of the edge.
- `dst::T`: The destination vertex of the edge.
- `weight::U`: The weight of the edge.

# Type parameters
- `T<:Integer`: The type of the vertices.
- `U<:Real`: The type of the weight.
"""
mutable struct DiWeightedEdge{T<:Integer, U<:Real} <: AbstractEdge{T}
    src::T
    dst::T
    weight::U
end

function Base.show(io::IO, edge::DiWeightedEdge{T,U}) where {T<:Integer, U<:Real}
    print(io, "DiWeightedEdge(", edge.src, ", ", edge.dst, ", ", edge.weight, ")")
end

"""
    SimpleDiWeightedGraphAdj{T<:Integer, U<:Real}

A simple directed weighted graph implementation using an adjacency list representation.

# Fields
- `edges::Vector{Vector{DiWeightedEdge{T,U}}}`: A vector of out edges represented as a vector of `DiWeightedEdge{T,U}`.
- `edges_transpose::Vector{Vector{DiWeightedEdge{T,U}}}`: A vector of in edges represented as a vector of `DiWeightedEdge{T,U}`.

# Constructors
- `SimpleDiWeightedGraphAdj{T,U}(edges::Vector{Vector{DiWeightedEdge{T,U}}})`: Constructs a new `SimpleDiWeightedGraphAdj{T,U}` object with the given vertices and edges.

"""
mutable struct SimpleDiWeightedGraphAdj{T<:Integer, U<:Real} <: AbstractGraph{T}
    edges::Vector{Vector{DiWeightedEdge{T,U}}}
    edges_reversed::Vector{Vector{DiWeightedEdge{T,U}}}
    function SimpleDiWeightedGraphAdj{T,U}(
        edges::Vector{Vector{DiWeightedEdge{T,U}}}
    ) where {T<:Integer, U<:Real}
        edges_transpose = [DiWeightedEdge{T,U}[] for _ in 1:length(edges)]
        for vertex in 1:length(edges)
            for edge in edges[vertex]
                push!(edges_transpose[edge.dst], DiWeightedEdge(edge.dst, edge.src, edge.weight))
            end
        end
        new{T,U}(edges, edges_transpose)
    end
end

function Base.show(io::IO, graph::SimpleDiWeightedGraphAdj{T,U}) where {T<:Integer, U<:Real}
    println(io, "SimpleDiWeightedGraphAdj{", T, ", ", U, "}(")
    print(io, "    edges = [\n")
    for vertex in 1:length(graph.edges)
        print(io, "        ")
        show(io, graph.edges[vertex])
        print(io, "\n")
    end
    print(io, "    ]\n")
    print(io, ")")
end

function SimpleDiWeightedGraphAdj(n::T, ::Type{U}) where {T<:Integer, U<:Real}
    edges::Vector{Vector{DiWeightedEdge{T,U}}} = [DiWeightedEdge{T,U}[] for _ in 1:n]
    SimpleDiWeightedGraphAdj{T,U}(edges)
end
function SimpleDiWeightedGraphAdj(edges::Vector{Vector{DiWeightedEdge{T,U}}}) where {T<:Integer, U<:Real}
    SimpleDiWeightedGraphAdj{T,U}(edges)
end

function Graphs.add_edge!(graph::SimpleDiWeightedGraphAdj{T,U}, src::T, dst::T, weight::U) where {T<:Integer, U<:Real}
    push!(graph.edges[src], DiWeightedEdge(src, dst, weight))
    push!(graph.edges_reversed[dst], DiWeightedEdge(dst, src, weight))
end

function Graphs.add_edge!(graph::SimpleDiWeightedGraphAdj, edge::DiWeightedEdge{T,U}) where {T<:Integer, U<:Real} 
    push!(graph.edges[edge.src], edge)
    push!(graph.edges_reversed[edge.dst], DiWeightedEdge(edge.dst, edge.src, edge.weight))
end

Graphs.has_edge(graph::SimpleDiWeightedGraphAdj, src::T, dst::T) where {T<:Integer} = any(x -> x.dst == dst, graph.edges[src])

function Graphs.rem_edge!(graph::SimpleDiWeightedGraphAdj, src::T, dst::T) where {T<:Integer}
    filter!(x -> x.dst ≠ dst, graph.edges[src])
    filter!(x -> x.dst ≠ src, graph.edges_reversed[dst])
end

Graphs.has_vertex(graph::SimpleDiWeightedGraphAdj, v::T) where {T<:Integer} = v ∈ 1:length(graph.edges)

Graphs.add_vertex!(graph::SimpleDiWeightedGraphAdj{T,U}) where {T<:Integer, U<:Real} = begin
    resize!(graph.edges, length(graph.edges) + 1)
    resize!(graph.edges_reversed, length(graph.edges_reversed) + 1)
    graph.edges[length(graph.edges)+1] = DiWeightedEdge{T,U}[]
    graph.edges_reversed[length(graph.edges_reversed)+1] = DiWeightedEdge{T,U}[]
end 

inedges(graph::SimpleDiWeightedGraphAdj, v::T) where {T<:Integer} = graph.edges_reversed[v]
outedges(graph::SimpleDiWeightedGraphAdj, v::T) where {T<:Integer} = graph.edges[v]

Graphs.outneighbors(graph::SimpleDiWeightedGraphAdj, v::T) where {T<:Integer} = (edge.dst for edge in graph.edges[v])
Graphs.inneighbors(graph::SimpleDiWeightedGraphAdj, v::T) where {T<:Integer} = (edge.dst for edge in graph.edges_reversed[v])

Base.length(graph::SimpleDiWeightedGraphAdj) = length(graph.edges)

function Base.getindex(graph::SimpleDiWeightedGraphAdj, i::Integer, j::Integer, ::Val{:weight})
    for edge in graph.edges[i]
        if edge.dst == j
            return edge.weight
        end
    end
    return nothing
end 




