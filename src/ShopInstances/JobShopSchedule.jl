import Base: show

struct ShopSchedule
    instance::AbstractShop
    C::Vector{Vector{Int64}}
    objectiveValue::Int64
end

function Base.show(io::IO, instance::ShopSchedule)
    println(io, "C: $(instance.C)")
    println(io, "objectiveValue: $(instance.objectiveValue)")
end