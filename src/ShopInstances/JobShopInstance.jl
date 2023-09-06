struct JobShopInstance <: AbstractShop
    n::Int64
    m::Int64
    n_i::Vector{Int}
    p::Vector{Vector{Int}}
    μ::Vector{Vector{Int}}
    d
    function (
        n::Int64,
        m::Int64,
        n_i::Vector{Int},
        p::Vector{Vector{Int}},
        μ::Vector{Vector{Int}}
    )
        
    # @assert n == size(p, 1) "n not equals to size(p, 1)"
    # @assert maximum(n_i) == size(p, 2) "maximum value of n_i not equals to size(p, 2)"
    # @assert n == size(μ, 1) "n not equals to size(μ, 1)"
    # @assert maximum(n_i) == size(μ, 2) "maximum value of n_i not equals to size(μ, 2)"
    # @assert size(p) == size(μ) "size(p) not equals to size(μ)"
    # @assert all(n_i .>= 1) "there is a job with no operations"
    # @assert all(n_i .<= size(p, 2)) "there is a job with more operations than machines"
    # @assert all(p .>= 0) "there is a negative processing time"
    # @assert all(μ .> 0) "there is a non-positive machine number"
    # @assert all(μ .<= m) "there is a machine number greater than m"
    # 

    

    new(n, m, n_i, p, μ)
    end
end