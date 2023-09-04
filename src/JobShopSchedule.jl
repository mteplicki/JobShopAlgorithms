struct ShopSchedule
    instance::AbstractShop
    objectiveFunction::AbstractObjectiveFunction
    C::Array{Union{Int64,Nothing},2}
    objectiveValue::Int64
end