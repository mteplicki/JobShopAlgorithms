import Random: default_rng
export random_instance_generator

function random_instance_generator(n::Int64, m::Int64; n_i::Union{Vector{Int}, Nothing}=nothing, pMin::Int=1, pMax::Int=10, rng=default_rng(), job_recirculation::Bool=false, machine_repetition::Bool=false)::JobShopInstance
    n_i === nothing && (n_i = [m for _ in 1:n])

    length(n_i) == n || throw(ArgumentError("length of n_i must be equal to n"))
    n > 0 || throw(ArgumentError("n must be positive"))
    m > 0 || throw(ArgumentError("m must be positive"))
    pMin > 0 || throw(ArgumentError("pMin must be positive"))
    pMax > 0 || throw(ArgumentError("pMax must be positive"))
    pMin <= pMax || throw(ArgumentError("pMin must be less or equal to pMax"))
    
    p = Vector{Vector{Int64}}(undef, n)
    μ = Vector{Vector{Int64}}(undef, n)
    for i in 1:n
        machineSet = Set{Int64}(collect(1:m))
        p[i] = Vector{Int64}(undef, n_i[i])
        μ[i] = Vector{Int64}(undef, n_i[i])
        lastMachine = 0
        for j in 1:n_i[i]
            p[i][j] = rand(rng, pMin:pMax)
            isempty(machineSet) && throw(ArgumentError("unable to generate instance with no machine repetition"))
            if machine_repetition
                machine = rand(rng, machineSet)
            else
                machine = rand(rng, setdiff(machineSet, Set([lastMachine])))
            end
            if job_recirculation
                μ[i][j] = machine
            else
                μ[i][j] = machine
                delete!(machineSet, machine)
            end
            lastMachine = machine
        end
    end
    return JobShopInstance(n, m, n_i, p, μ)
end