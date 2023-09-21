abstract type JobShopFileSpecification end

struct StandardSpecification <: JobShopFileSpecification
    instance::JobShopInstance
end

struct TaillardSpecification <: JobShopFileSpecification
    instance::JobShopInstance
end

function Base.read(data::IO, ::Type{StandardSpecification})
    n, m = parse.(Int,split(readline(data)))
    μ = Vector{Vector{Int}}()
    p = Vector{Vector{Int}}()
    for _ in 1:n
        list = parse.(Int,split(readline(data)))
        μ_i = list[(1:length(list)) .% 2 .== 1]
        μ_i .+= 1
        p_i = list[(1:length(list)) .% 2 .== 0]
        push!(μ, μ_i)
        push!(p, p_i)
    end
    n_i = map(length, μ)
    return JobShopInstance(n, m, n_i, p, μ)
end

function Base.read(data::IO, ::Type{TaillardSpecification})
    n, m = parse.(Int,split(readline(data)))
    μ = Vector{Vector{Int}}()
    p = Vector{Vector{Int}}()
    lines = readlines(data)
    pLines = lines[1:n]
    μLines = lines[n+1:2n]
    p = [parse.(Int,split(line)) for line in pLines]
    μ = [parse.(Int,split(line)) for line in μLines]
    n_i = map(length, μ)
    return JobShopInstance(n, m, n_i, p, μ)
end

Base.read(filename::AbstractString, ::Type{T}) where {T <: JobShopFileSpecification} = open(filename) do data
    read(data, T)
end

function Base.write(data::IO, specification::StandardSpecification)
    instance = specification.instance
    println(data, "$(instance.n) $(instance.m)")
    for (μ_i, p_i) in zip(instance.μ, instance.p)
        list = zeros(Int, length(p_i)*2 )
        list[(1:length(list)) .% 2 .== 1] .= (μ_i .- 1)
        list[(1:length(list)) .% 2 .== 0] .= p_i
        println(data, join(list, " "))
    end
    return data
end

function Base.write(data::IO, specification::TaillardSpecification)
    instance = specification.instance
    println(data, "$(instance.n) $(instance.m)")
    println(data, join(join.(instance.p, " "), "\n"))
    println(data, join(join.(instance.μ, " "), "\n"))
    return data
end

Base.write(filename::AbstractString, specification::T) where {T <: JobShopFileSpecification} = open(filename, "w") do data
    write(data, specification)
end

