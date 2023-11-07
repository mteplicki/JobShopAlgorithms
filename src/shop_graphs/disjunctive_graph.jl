export DisjunctiveWeightedGraph

"""
    mutable struct DisjunctiveWeightedGraph{T<:Integer, U<:Real} <: AbstractGraph{T}

DisjunctiveWeightedGraph is a mutable struct that represents a disjunctive weighted graph. It contains two fields:
- conjunctiveGraph: a SimpleDirectedWeightedGraphAdj{T,U} representing the conjunctive graph.
- selection: a SimpleDirectedWeightedGraphAdj{T,U} representing the selection of disjunctive graph.

# Arguments
- `T::Type{<:Integer}`: The integer type of the vertices.
- `U::Type{<:Real}`: The real type of the weights.

# Fields
- `conjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}`: The conjunctive graph.
- `selection::SimpleDirectedWeightedGraphAdj{T,U}`: The selection of disjunctive graph.

# Constructors
- `DisjunctiveWeightedGraph{T,U}(conjunctiveGraph::SimpleDirectedWeightedGraphAdj{T,U}, selection::SimpleDirectedWeightedGraphAdj{T,U})`: Constructs a new DisjunctiveWeightedGraph{T,U} with the given conjunctiveGraph and selection.

# Examples
```jldoctest
    conjuctiveGraph = SimpleDirectedWeightedGraphAdj{Int,Int}([
        [SimpleDirectedWeightedEdge(1, 2, 1), SimpleDirectedWeightedEdge(1, 3, 1)],
        [SimpleDirectedWeightedEdge(2, 4, 1)],
        [SimpleDirectedWeightedEdge(3, 4, 1)],
        [SimpleDirectedWeightedEdge(4, 5, 1)]
    ])
    selection = SimpleDirectedWeightedGraphAdj{Int,Int}([
        [SimpleDirectedWeightedEdge(1, 2, 1), SimpleDirectedWeightedEdge(1, 3, 1)],
        [SimpleDirectedWeightedEdge(2, 4, 1)],
        [SimpleDirectedWeightedEdge(3, 4, 1)],
        [SimpleDirectedWeightedEdge(4, 5, 1)]
    ])
    disjunctiveWeightedGraph = DisjunctiveWeightedGraph(conjuctiveGraph, selection)
```
"""
mutable struct DisjunctiveWeightedGraph{T<:Integer, U<:Real} <: AbstractGraph{T}
    conjunctiveEdges::SimpleDiWeightedGraphAdj{T,U}
    selection::SimpleDiWeightedGraphAdj{T,U}
    function DisjunctiveWeightedGraph{T,U}(
        conjunctiveEdges::SimpleDiWeightedGraphAdj{T,U},
        selection::SimpleDiWeightedGraphAdj{T,U}
    ) where {T<:Integer, U<:Real}
        length(conjunctiveEdges) == length(conjunctiveEdges) || throw(DimensionMismatch("conjunctiveEdges and selection must have the same number of vertices"))
        new{T,U}(conjunctiveEdges, selection)
    end
end

DisjunctiveWeightedGraph(conjunctiveGraph::SimpleDiWeightedGraphAdj{T,U}, selection::SimpleDiWeightedGraphAdj{T,U}) where {T<:Integer, U<:Real} = DisjunctiveWeightedGraph{T,U}(conjunctiveGraph, selection)

Base.length(graph::DisjunctiveWeightedGraph) = length(graph.conjunctiveEdges)

function Base.show(io::IO, graph::DisjunctiveWeightedGraph{T,U}) where {T<:Integer, U<:Real}
    println(io, "DisjunctiveWeightedGraph{", T, ", ", U, "}(")
    println(io, "conjunctiveGraph = ", graph.conjunctiveEdges)
    println(io, "disjunctiveGraph = ", graph.selection)
    print(io, ")")
end

Graphs.inneighbors(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = Iterators.flatten((inneighbors(graph.conjunctiveEdges, v), inneighbors(graph.selection, v)))

Graphs.outneighbors(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = Iterators.flatten((outneighbors(graph.conjunctiveEdges, v), outneighbors(graph.selection, v)))

Graphs.neighbors(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = Iterators.flatten((neighbors(graph.conjunctiveEdges, v), neighbors(graph.selection, v)))

inedges(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = Iterators.flatten((inedges(graph.conjunctiveEdges, v), inedges(graph.selection, v)))

outedges(graph::DisjunctiveWeightedGraph{T,U}, v::T) where {T<:Integer, U<:Real} = Iterators.flatten((outedges(graph.conjunctiveEdges, v), outedges(graph.selection, v)))