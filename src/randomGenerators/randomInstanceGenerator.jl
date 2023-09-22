import Random: default_rng
function random_instance_generator(n::Int64, m::Int64; n_i_random::Bool=false, pMin::Int=1, pMax::Int=10, rng=default_rng(), machineRepetition::Bool=false, n_i_min::Int=1, n_i_max::Int=10)::JobShopInstance
    n_i = Vector{Int64}(undef, n)
    p = Vector{Vector{Int64}}(undef, n)
    μ = Vector{Vector{Int64}}(undef, n)
    if n_i_random
        for i in 1:n
            n_i[i] = rand(rng, n_i_min:n_i_max)
        end
    else
        n_i .= m
    end
    for i in 1:n
        machineSet = Set{Int64}(collect(1:m))
        p[i] = Vector{Int64}(undef, n_i[i])
        μ[i] = Vector{Int64}(undef, n_i[i])
        for j in 1:n_i[i]
            p[i][j] = rand(rng, pMin:pMax)
            isempty(machineSet) && throw(ArgumentError("unable to generate instance with no machine repetition"))
            machine = rand(rng, machineSet)
            if machineRepetition
                μ[i][j] = machine
            else
                μ[i][j] = machine
                delete!(machineSet, machine)
            end
        end
    end
    return JobShopInstance(n, m, n_i, p, μ)
end