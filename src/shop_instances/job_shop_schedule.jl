export ShopSchedule, ShopResult, ShopError

abstract type ShopResult end

"""
    ShopError <: ShopResult

    ShopError(
        instance::AbstractShop,
        error::String,
        objectiveFunction::ObjectiveFunction;
        algorithm::String="",
        metadata::Dict{String, Any}=Dict{String, Any}(),
        date::DateTime=now()
    )

A struct representing an error result of a shop scheduling algorithm.

# Arguments
- `instance::AbstractShop`: The instance of the shop problem.
- `error::String`: The error message.
- `objectiveFunction::ObjectiveFunction`: The objective function used in the algorithm.
- `algorithm::String="": The name of the algorithm used.
- `metadata::Dict{String, Any}=Dict{String, Any}()`: Additional metadata about the result.
- `date::DateTime=now()`: The date and time when the result was obtained.

# Fields
- `instance::JobShopInstance`: The instance of the shop problem.
- `error::String`: The error message.
- `objectiveFunction::ObjectiveFunction`: The objective function used in the algorithm.
- `algorithm::String`: The name of the algorithm used.
- `date::DateTime`: The date and time when the result was obtained.
- `metadata::Dict{String, Any}`: Additional metadata about the result.
"""
struct ShopError <: ShopResult
    instance::JobShopInstance
    error::String
    objectiveFunction::ObjectiveFunction
    algorithm::String
    date::DateTime
    metadata::Dict{String, Any}
    function ShopError(
        instance::AbstractShop,
        error::String,
        objectiveFunction::ObjectiveFunction;
        algorithm::String="",
        metadata::Dict{String, Any}=Dict{String, Any}(),
        date::DateTime=now()
    )
        new(instance, error, objectiveFunction, algorithm, date, metadata)
    end
end

function Base.show(io::IO, instance::ShopError)
    println(io, "Shop error: $(instance.instance.name)")
    println(io, "error: $(instance.error)")
    println(io, "algorithm: $(instance.algorithm)")
    for (key, value) in instance.metadata
        println(io, "$key: $value")
    end
end

struct ShopSchedule <: ShopResult
    instance::JobShopInstance
    C::Vector{Vector{Int64}}
    objectiveValue::Int64
    objectiveFunction::ObjectiveFunction
    algorithm::String
    microruns::Int
    timeSeconds::Float64
    memoryBytes::Int
    metadata::Dict{String, Any}
    date::DateTime
    function ShopSchedule(
        instance::AbstractShop,
        C::Vector{Vector{Int64}},
        objectiveValue::Int64,
        objectiveFunction::ObjectiveFunction;
        algorithm::String="",
        microruns::Int=0,
        timeSeconds::Float64=0.0,
        memoryBytes::Int=0,
        metadata::Dict{String, Any}=Dict{String, Any}(),
        date::DateTime=now()
    )
        new(instance, C, objectiveValue, objectiveFunction, algorithm, microruns, timeSeconds, memoryBytes, metadata, date)
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
    for (key, value) in instance.metadata
        println(io, "$key: $value")
    end
end