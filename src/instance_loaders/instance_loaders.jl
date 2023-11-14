"""
Module for loading and generating random instances of the Shop Problem.
"""
module InstanceLoaders
    using ..ShopAlgorithms.ShopInstances
    include("random_instance_generator.jl")
    include("standard_loader.jl")
end