module ShopInstances
    using DataFrames
    include("abstract_shop.jl")
    include("objective_functions.jl")
    include("job_shop_instance.jl")
    include("job_shop_instance_builder.jl")
    include("job_shop_schedule.jl")
    include("dataframes.jl")
end