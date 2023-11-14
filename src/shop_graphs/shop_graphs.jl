"""
This module defines functions and types for working with graphs dedicated for Job Shop algortihms.
"""
module ShopGraphs
    using Graphs, DataStructures
    include("simple_weighted_graph_adj.jl")
    include("disjunctive_graph.jl")
    include("dag_paths.jl")
    
end