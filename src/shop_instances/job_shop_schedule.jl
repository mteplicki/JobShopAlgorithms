export ShopSchedule

struct ShopSchedule
    instance::JobShopInstance
    C::Vector{Vector{Int64}}
    objectiveValue::Int64
    objectiveFunction::ObjectiveFunction
    algorithm::String
    microruns::Int
    timeSeconds::Float64
    memoryBytes::Int
    function ShopSchedule(
        instance::AbstractShop,
        C::Vector{Vector{Int64}},
        objectiveValue::Int64,
        objectiveFunction::ObjectiveFunction;
        algorithm::String="",
        microruns::Int=0,
        timeSeconds::Float64=0.0,
        memoryBytes::Int=0
    )
        new(instance, C, objectiveValue, objectiveFunction, algorithm, microruns, timeSeconds, memoryBytes)
    end
end

function Base.show(io::IO, instance::ShopSchedule)
    println(io, "Shop schedule: $(instance.instance.name)")
    println(io, "C: $(instance.C)")
    println(io, "objectiveValue: $(instance.objectiveValue)")
    println(io, "objectiveFunction: $(instance.objectiveFunction)")
    println(io, "algorithm: $(instance.algorithm)")
    println(io, "microruns: $(instance.microruns)")
    println(io, "timeSeconds: $(instance.timeSeconds)")
    println(io, "memoryBytes: $(instance.memoryBytes)")
end