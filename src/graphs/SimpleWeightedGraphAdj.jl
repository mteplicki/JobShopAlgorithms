using Graphs
import Base.getindex, Graphs.add_edge!

mutable struct SimpleWeightedEdge{T<:Integer, U<:Real} <: AbstractEdge{T}
    src::T
    dst::T
    weight::U

end

mutable struct SimpleWeightedGraphAdj{T<:Integer, U<:Real} <: AbstractGraph{T}
    vertices::Vector{T}
    edges::Vector{Vector{SimpleWeightedEdge{T,U}}}
    
end

function Graphs.add_edge!(graph::SimpleWeightedGraphAdj{T,U}, src::T, dst::T, weight::U) where {T<:Integer, U<:Real}
    push!(graph.edges[src], SimpleWeightedEdge(src, dst, weight))
end

Graphs.add_edge!(graph::SimpleWeightedGraphAdj, edge::SimpleWeightedEdge{T,U}) where {T<:Integer, U<:Real} = push!(graph.edges[edge.src], edge)



rem_edge!(graph::SimpleWeightedGraphAdj, src::T, dst::T) where {T<:Integer} = filter!(x -> x.dst != dst, graph.edges[src])



function Base.getindex(graph::SimpleWeightedGraphAdj, i::Integer, j::Integer, ::Val{:weight})
    for edge in graph.edges[i]
        if edge.dst == j
            return edge.weight
        end
    end
    return nothing
end 

function SimpleWeightedGraphAdj(n::T, ::Type{U}) where {T<:Integer, U<:Real}
    vertices = [i for i in 1:n]
    edges::Vector{Vector{SimpleWeightedEdge{T,U}}} = []
    SimpleWeightedGraphAdj{T,U}(vertices, edges)
end

function SimpleWeightedGraphAdj(n::T, edges::Vector{Vector{SimpleWeightedEdge{T,U}}}) where {T<:Integer, U<:Real}
    vertices = [i for i in 1:n]
    SimpleWeightedGraphAdj{T,U}(vertices, edges)
end



