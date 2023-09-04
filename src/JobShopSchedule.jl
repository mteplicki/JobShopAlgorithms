struct JobShopSchedule
    instance::AbstractShop
    objectiveFunction::Function
    C::Array{Union{Int64,Nothing},2}
    objectiveValue::Int64
end