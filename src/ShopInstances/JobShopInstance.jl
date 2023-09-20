struct JobShopInstance <: AbstractShop
    n::Int64
    m::Int64
    n_i::Vector{Int}
    p::Vector{Vector{Int}}
    μ::Vector{Vector{Int}}
    function JobShopInstance(
        n::Int64,
        m::Int64,
        n_i::Vector{Int},
        p::Vector{Vector{Int}},
        μ::Vector{Vector{Int}};
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

        new(n, m, n_i, p, μ)
    end
end

function Base.:(==)(instance1::JobShopInstance, instance2::JobShopInstance) 
    return (
    instance1.n == instance2.n &&
    instance1.m == instance2.m &&
    instance1.n_i == instance2.n_i &&
    instance1.p == instance2.p &&
    instance1.μ == instance2.μ)
end

function Base.show(io::IO, instance::JobShopInstance)
    println(io, "n: $(instance.n)")
    println(io, "m: $(instance.m)")
    println(io, "n_i: $(instance.n_i)")
    println(io, "p: $(instance.p)")
    println(io, "μ: $(instance.μ)")
end