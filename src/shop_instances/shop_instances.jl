"""
This module contains the implementation of various job shop instances, as well as the necessary functions and
types to work with them. 
"""
module ShopInstances
    using DataFrames, Dates
    include("abstract_shop.jl")
    include("objective_functions.jl")
    include("job_shop_instance.jl")
    include("job_shop_schedule.jl")
    include("dataframes.jl")
    include("utils.jl")
end