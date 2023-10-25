export DisjunctiveWeightedGraph

"""
    mutable struct DisjunctiveWeightedGraph{T<:Integer, U<:Real} <: AbstractGraph{T}

DisjunctiveWeightedGraph is a mutable struct that represents a disjunctive weighted graph. It contains two fields:
- conjunctiveGraph: a SimpleDirectedWeightedGraphAdj{T,U} representing the conjunctive graph.
- disjunctiveGraph: a SimpleDirectedWeightedGraphAdj{T,U} representing the disjunctive graph.

# Arguments
- `T::Type{<:Integer}`: The integer type of the vertices.
- `U::Type{<:Real}`: The real type of the weights.

# Fields
- `conjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}`: The conjunctive graph.
- `disjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}`: The disjunctive graph.

# Constructors
- `DisjunctiveWeightedGraph{T,U}(conjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}, disjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U})`: Constructs a new DisjunctiveWeightedGraph{T,U} with the given conjunctiveGraph and disjunctiveGraph.

# Examples
```jldoctest
    conjuctiveGraph = SimpleDirectedWeightedGraphAdj{Int,Int}([
        [SimpleDirectedWeightedEdge(1, 2, 1), SimpleDirectedWeightedEdge(1, 3, 1)],
        [SimpleDirectedWeightedEdge(2, 4, 1)],
        [SimpleDirectedWeightedEdge(3, 4, 1)],
        [SimpleDirectedWeightedEdge(4, 5, 1)]
    ])
    disjunctiveGraph = SimpleDirectedWeightedGraphAdj{Int,Int}([
        [SimpleDirectedWeightedEdge(1, 2, 1), SimpleDirectedWeightedEdge(1, 3, 1)],
        [SimpleDirectedWeightedEdge(2, 4, 1)],
        [SimpleDirectedWeightedEdge(3, 4, 1)],
        [SimpleDirectedWeightedEdge(4, 5, 1)]
    ])
    disjunctiveWeightedGraph = DisjunctiveWeightedGraph(conjuctiveGraph, disjunctiveGraph)
```
"""
mutable struct DisjunctiveWeightedGraph{T<:Integer, U<:Real} <: AbstractGraph{T}
    conjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}
    disjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}
    function DisjunctiveWeightedGraph{T,U}(
        conjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U},
        disjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}
    ) where {T<:Integer, U<:Real}
        length(conjunctiveGraph) == length(disjunctiveGraph) || throw(DimensionMismatch("conjunctiveGraph and disjunctiveGraph must have the same number of vertices"))
        new{T,U}(conjunctiveGraph, disjunctiveGraph)
    end
end

DisjunctiveWeightedGraph(conjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}, disjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}) where {T<:Integer, U<:Real} = DisjunctiveWeightedGraph{T,U}(conjunctiveGraph, disjunctiveGraph)

Base.length(graph::DisjunctiveWeightedGraph) = length(graph.conjunctiveGraph)

function Base.show(io::IO, graph::DisjunctiveWeightedGraph{T,U}) where {T<:Integer, U<:Real}
    println(io, "DisjunctiveWeightedGraph{", T, ", ", U, "}(")
    println(io, "conjunctiveGraph = ", graph.conjunctiveGraph)
    println(io, "disjunctiveGraph = ", graph.disjunctiveGraph)
    print(io, ")")
end

Graphs.inneighbors(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = [inneighbors(graph.conjunctiveGraph, v); inneighbors(graph.disjunctiveGraph, v)]

Graphs.outneighbors(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = [outneighbors(graph.conjunctiveGraph, v); outneighbors(graph.disjunctiveGraph, v)]

Graphs.neighbors(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = [neighbors(graph.conjunctiveGraph, v); neighbors(graph.disjunctiveGraph, v)]

inedges(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = [inedges(graph.conjunctiveGraph, v); inedges(graph.disjunctiveGraph, v)]

outedges(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = [outedges(graph.conjunctiveGraph, v); outedges(graph.disjunctiveGraph, v)]