struct JobShopInstanceBuilder
    n::Int64
    m::Int64
    n_i::Array{Int64,1}
    p::Array{Union{Int64, Nothing},2}
    μ::Array{Union{Int64, Nothing},2}

    function (n::Int64, m::Int64)
        @assert n >= 1 "n must be greater than or equal to 1"
        @assert m >= 1 "m must be greater than or equal to 1"
        new(n, m, fill(nothing, n), fill(nothing, n, m), fill(nothing, n, m))
    end
end

function set_n_i!(builder::JobShopInstanceBuilder, i::Int64, n_i::Int64)
    @assert i >= 1 "i must be greater than or equal to 1"
    @assert i <= builder.n "i must be less than or equal to n"
    @assert n_i >= 1 "n_i must be greater than or equal to 1"
    builder.n_i[i] = n_i
    return builder
end

function set_p!(builder::JobShopInstanceBuilder, i::Int64, j::Int64, p::Int64)
    @assert i >= 1 "i must be greater than or equal to 1"
    @assert i <= builder.n "i must be less than or equal to n"
    @assert j >= 1 "j must be greater than or equal to 1"
    @assert j <= builder.n_i[i] "j must be less than or equal to n_i[i]"
    @assert p >= 0 "p must be greater than or equal to 0"
    builder.p[i, j] = p
    return builder
end

function set_μ!