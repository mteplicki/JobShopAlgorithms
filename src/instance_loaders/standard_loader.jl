export JobShopFileSpecification, StandardSpecification, TaillardSpecification

"""
    abstract type JobShopFileSpecification

Abstract type representing a file specification for a job shop problem instance.
"""
abstract type JobShopFileSpecification end

"""
    StandardSpecification <: JobShopFileSpecification

A struct that represents a standard job shop instance specification.
Standard instances are specified in the following format:

```text
n m
μ_11 p_11 μ_12 p_12 ... μ_1n_1 p_1n_1
μ_21 p_21 μ_22 p_22 ... μ_2n_2 p_2n_2
...
μ_m1 p_m1 μ_m2 p_m2 ... μ_mn_m p_mn_m
```

where `n` is the number of jobs, `m` is the number of machines, `p_ij` is the processing time of job `i` on machine `j`, and `μ_ij` is the machine number of the `j`th operation of job `i`, starting from 0.


# Fields
- `instance::JobShopInstance`: A job shop instance.

# Examples
```jldoctest
julia> instance = JobShopInstance(3, 2, [2, 2, 2], [[1, 2], [2, 1], [1, 2]], [[1, 2], [2, 1], [1, 2]])
JobShopInstance(3, 2, [2, 2, 2], [[1, 2], [2, 1], [1, 2]], [[1, 2], [2, 1], [1, 2]])
julia> specification = StandardSpecification(instance)
StandardSpecification(JobShopInstance(3, 2, [2, 2, 2], [[1, 2], [2, 1], [1, 2]], [[1, 2], [2, 1], [1, 2]]))
julia> write("test.txt", specification);
julia> read("test.txt", StandardSpecification)
StandardSpecification(JobShopInstance(3, 2, [2, 2, 2], [[1, 2], [2, 1], [1, 2]], [[1, 2], [2, 1], [1, 2]]))
```

"""
struct StandardSpecification <: JobShopFileSpecification
    instance::JobShopInstance
end

"""
    TaillardSpecification <: JobShopFileSpecification

A struct that represents a Taillard instance specification for the Job Shop Problem.
Taillard instances are specified in the following format:

```text
n m
p_11 p_12 ... p_1n_1
p_21 p_22 ... p_2n_2
...
p_m1 p_m2 ... p_mn_m
μ_11 μ_12 ... μ_1n_1
μ_21 μ_22 ... μ_2n_2
...
μ_m1 μ_m2 ... μ_mn_m
```

where `n` is the number of jobs, `m` is the number of machines, `p_ij` is the processing time of job `i` on machine `j`, and `μ_ij` is the machine number of the `j`th operation of job `i`.


# Fields
- `instance::JobShopInstance`: A JobShopInstance object representing the instance.

# Examples
```jldoctest
julia> instance = JobShopInstance(3, 2, [2, 2, 2], [[1, 2], [2, 1], [1, 2]], [[1, 2], [2, 1], [1, 2]])
JobShopInstance(3, 2, [2, 2, 2], [[1, 2], [2, 1], [1, 2]], [[1, 2], [2, 1], [1, 2]])
julia> specification = TaillardSpecification(instance)
TaillardSpecification(JobShopInstance(3, 2, [2, 2, 2], [[1, 2], [2, 1], [1, 2]], [[1, 2], [2, 1], [1, 2]]))
julia> write("test.txt", specification)
julia> read("test.txt", TaillardSpecification)
TaillardSpecification(JobShopInstance(3, 2, [2, 2, 2], [[1, 2], [2, 1], [1, 2]], [[1, 2], [2, 1], [1, 2]]))
```
"""
struct TaillardSpecification <: JobShopFileSpecification
    instance::JobShopInstance
end

Base.read(data::IO, ::Type{T}) where {T <: JobShopFileSpecification}  = read(data, T, "")

function Base.read(data::IO, ::Type{StandardSpecification}, name::String)
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
    return JobShopInstance(n, m, n_i, p, μ; name=name)
end

function Base.read(data::IO, ::Type{TaillardSpecification}, name::String)
    n, m = parse.(Int,split(readline(data)))
    μ = Vector{Vector{Int}}()
    p = Vector{Vector{Int}}()
    lines = readlines(data)
    pLines = lines[1:n]
    μLines = lines[n+1:2n]
    p = [parse.(Int,split(line)) for line in pLines]
    μ = [parse.(Int,split(line)) for line in μLines]
    n_i = map(length, μ)
    return JobShopInstance(n, m, n_i, p, μ; name=name)
end

Base.read(filename::AbstractString, ::Type{T}) where {T <: JobShopFileSpecification} = read(filename, T, "")

Base.read(filename::AbstractString, ::Type{T}, name::String) where {T <: JobShopFileSpecification} = open(filename) do data
    read(data, T, name)
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

