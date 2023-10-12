export two_machines_job_shop

"""
    twomachinesjobshop(instance::JobShopInstance)

Solves the two-machine job shop problem `J2 | p_ij = 1 | Lmax` for the given `instance`. Complexity is `O(r)`, where `r = sum(n_i)` is the number of operations.

# Arguments
- `instance::JobShopInstance`: An instance of the two-machine job shop problem.

# Returns
- An optimal solution to the two-machine job shop problem.

"""
function two_machines_job_shop(
    instance::JobShopInstance;
    yielding::Bool = false
)::ShopSchedule
    _ , timeSeconds, bytes = @timed begin 
    n, m, n_i, p, μ, d = instance.n, instance.m, instance.n_i, instance.p, instance.μ, instance.d
    yield_ref = yielding ? Ref(time()) : nothing
    processing_time_equals(1)(instance) || throw(ArgumentError("p_ij must be equal to 1 for all i and j"))
    machine_upper_limit(2)(instance) || throw(ArgumentError("m must be less than or equal to 2"))
    additionalInformation = Dict{String, Any}()

    r = sum(n_i)
    A::OffsetVector{Union{Nothing,Tuple{Int64,Int64}},Vector{Union{Nothing,Tuple{Int64,Int64}}}} = OffsetArray([nothing for i = 0:r], -1)
    B::OffsetVector{Union{Nothing,Tuple{Int64,Int64}},Vector{Union{Nothing,Tuple{Int64,Int64}}}} = OffsetArray([nothing for i = 0:r], -1)
    if all(d .> 0)
        d = d .- minimum(d)
    end
    L = OffsetArray([[] for i = 1:2r-1], -r)
    Z = []
    for i = 1:n
        if d[i] < r
            for j = 1:n_i[i]
                push!(L[d[i]-n_i[i]+j], (i, j))
            end
        else
            push!(Z, i)
        end
    end
    LAST = zeros(Int64, n)
    T1 = Ref(0)
    T2 = Ref(0)
    for k = -r+1:r-1
        while !isempty(L[k])
            O = popfirst!(L[k])
            schedule_Oij!(O, T1, T2, LAST, A, B, μ)
            try_yield(yield_ref)
        end
    end
    while !isempty(Z)
        i = popfirst!(Z)
        for j = 1:n_i[i]
            schedule_Oij!((i, j), T1, T2, LAST, A, B, μ)
            try_yield(yield_ref)
        end
    end
    C = [[0 for _ in 1:n_i[i] ] for i in 1:n]
    for machine_schedule in [A, B]
        for (time, operation) in enumerate(machine_schedule)
            if operation !== nothing
                i,j = operation
                C[i][j] = time
            end
        end
    end
    end
    return ShopSchedule(
        instance,
        C,
        maximum(LAST),
        Lmax_function;
        timeSeconds = timeSeconds,
        algorithm = "Two machines job shop",
        memoryBytes = bytes
    )
end

function schedule_Oij!(
    O::Tuple{Int64,Int64},
    T1::Ref{Int64},
    T2::Ref{Int64},
    LAST::Vector{Int},
    A::OffsetVector{Union{Nothing,Tuple{Int64,Int64}},Vector{Union{Nothing,Tuple{Int64,Int64}}}},
    B::OffsetVector{Union{Nothing,Tuple{Int64,Int64}},Vector{Union{Nothing,Tuple{Int64,Int64}}}},
    μ::Vector{Vector{Int}}
)
    (i, j) = O
    t = -1
    if μ[i][j] == 1
        if T1[] < LAST[i]
            t = LAST[i]
            A[t] = (i, j)
        else
            t = T1[]
            A[t] = (i, j)
            while A[T1[]] !== nothing
                T1[] += 1
            end
        end
    else
        if T2[] < LAST[i]
            t = LAST[i]
            B[t] = (i, j)
        else
            t = T2[]
            B[t] = (i, j)
            while B[T2[]] !== nothing
                T2[] += 1
            end
        end
        # wątpliwe, być może trzeba przenieść pod end

    end
    LAST[i] = t + 1


end