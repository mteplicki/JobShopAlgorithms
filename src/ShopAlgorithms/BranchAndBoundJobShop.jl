mutable struct Operation
    i::Int64
    j::Int64
    p::Int64
    r::Int64
end

function generateActiveSchedules(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    Ω = [Operation(i,1,p[i][j],0) for i=1:n]
    minimum, index = findmin(a->a.p + a.r, Ω)
    i_star = Ω[index].i
    Ω_prim = filter(a->a.r < minimum, Ω)
end




