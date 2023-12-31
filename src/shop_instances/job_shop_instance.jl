export JobShopInstance

"""
    struct JobShopInstance <: AbstractShop

    JobShopInstance(
        n::Int64,
        m::Int64,
        n_i::Vector{Int},
        p::Vector{Vector{Int}},
        μ::Vector{Vector{Int}};
        d::Vector{Int}=zeros(Int64, n),
        name::String=""
    )

JobShopInstance represents a job shop instance, which is a type of scheduling problem.

# Arguments
- `n::Int64`: number of jobs
- `m::Int64`: number of machines
- `n_i::Vector{Int}`: number of operations for each job
- `p::Vector{Vector{Int}}`: processing times for each operation
- `μ::Vector{Vector{Int}}`: machines assigned to each operation
- `d::Vector{Int} = zeros(Int64, n)`: due dates for each job
- `name::String = ""`: name of the instance

# Fields
- `n`: an integer representing the number of jobs
- `m`: an integer representing the number of machines
- `n_i`: a vector of integers representing the number of operations for each job
- `p`: a vector of vectors of integers representing the processing times for each operation
- `μ`: a vector of vectors of integers representing the machines assigned to each operation
- `d`: a vector of integers representing the due dates for each job
- `name`: a string representing the name of the instance

"""
struct JobShopInstance <: AbstractShop
    n::Int64
    m::Int64
    n_i::Vector{Int}
    p::Vector{Vector{Int}}
    μ::Vector{Vector{Int}}
    d::Vector{Int}
    name::String
    function JobShopInstance(
        n::Int64,
        m::Int64,
        n_i::Vector{Int},
        p::Vector{Vector{Int}},
        μ::Vector{Vector{Int}};
        d::Vector{Int}=zeros(Int64, n),
        name::String=""
    )
        
        n ≥ 1 || throw(ArgumentError("n must be non-negative"))
        m ≥ 1 || throw(ArgumentError("m must be non-negative"))
        all(n_i .≥ 0) || throw(ArgumentError("n_i must be non-negative"))
        all(all(p_i .≥ 0) for p_i in p) || throw(ArgumentError("p must be non-negative"))
        all(all(μ_i .≥ 1) for μ_i in μ) || throw(ArgumentError("μ must be non-negative"))
        all(all(μ_i .≤ m) for μ_i in μ) || throw(ArgumentError("μ must be less than or equal to m"))
        length(n_i) == n || throw(ArgumentError("length(n_i) must be equal to n"))
        all(length(p[i]) == n_i[i] for i in 1:n) || throw(ArgumentError("length(p[i]) must be equal to n_i[i]"))
        all(length(μ[i]) == n_i[i] for i in 1:n) || throw(ArgumentError("length(μ[i]) must be equal to n_i[i]"))
        length(d) == n || throw(ArgumentError("length(d) must be equal to n"))
        all(d .≥ 0) || throw(ArgumentError("d must be non-negative"))

        new(n, m, n_i, p, μ, d, name)
    end
end

function Base.:(==)(instance1::JobShopInstance, instance2::JobShopInstance) 
    return (
    instance1.n == instance2.n &&
    instance1.m == instance2.m &&
    instance1.n_i == instance2.n_i &&
    instance1.p == instance2.p &&
    instance1.μ == instance2.μ &&
    instance1.d == instance2.d &&
    instance1.name == instance2.name
    )
end

function Base.show(io::IO, instance::JobShopInstance)
    println(io, "Job shop instance: $(instance.name)")
    println(io, "n: $(instance.n)")
    println(io, "m: $(instance.m)")
    println(io, "n_i: $(instance.n_i)")
    println(io, "p: $(instance.p)")
    println(io, "μ: $(instance.μ)")
    instance.d ≠ zeros(Int64, instance.n) && println(io, "d: $(instance.d)")
end