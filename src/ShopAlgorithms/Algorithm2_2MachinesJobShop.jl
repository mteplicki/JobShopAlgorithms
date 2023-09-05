function Algorithm2_2MachinesJobShop(
    n::Int64,
    m::Int64,
    n_i::Array{Int64,1},
    p::Array{Union{Int64, Nothing},2},
    μ::Array{Union{Int64, Nothing},2},
    d::Array{Int64,1}
)::ShopSchedule
    r = sum(n_i)
    A::OffsetVector{Union{Nothing, Tuple{Int64,Int64}}, Vector{Union{Nothing, Tuple{Int64,Int64}}}} = OffsetArray([nothing for i=0:r], -1)
    B::OffsetVector{Union{Nothing, Tuple{Int64,Int64}}, Vector{Union{Nothing, Tuple{Int64,Int64}}}} = OffsetArray([nothing for i=0:r], -1)
    if all(d .> 0)
        d = d .- minimum(d)
    end
    L = OffsetArray([[] for i=1:2r-1], -r)
    Z = []
    for i=1:n
        if d[i] < r
            for j=1:n_i[i]
                push!(L[d[i]-n[i]+j], (i,j))
            end
        else
            push!(Z, i)
        end
    end
    LAST = zeros(Int64, n)
    T1 = Ref(0)
    T2 = Ref(0)
    for k=-r+1:r-1
        while !empty(L[k])
            O = popfirst!(L[k])
            Schedule_Oij(O, T1, T2, A, B, LAST, μ)
        end
    end
    while !empty(Z)
        i = popfirst!(Z)
        for j=1:n_i[i]
            Schedule_Oij((i,j), T1, T2, A, B, LAST, μ)
        end
    end
    # do poprawy
    return ShopSchedule(
        JobShopInstance(n, m, n_i, p, μ, d),
        JobShopObjectiveFunction(),
        C = [A[i] for i=1:r],
        objectiveValue = maximum(LAST)
    )
end

function Schedule_Oij(
    O::Tuple{Int64,Int64},
    T1::Ref{Int64},
    T2::Ref{Int64},
    LAST::Array{Int64,1},
    A::OffsetVector{Union{Nothing, Tuple{Int64,Int64}}, Vector{Union{Nothing, Tuple{Int64,Int64}}}},
    B::OffsetVector{Union{Nothing, Tuple{Int64,Int64}}, Vector{Union{Nothing, Tuple{Int64,Int64}}}},
    μ::Array{Union{Int64, Nothing},2}
)
    (i,j) = O
    t = -1
    if μ[i,j] == 1
        if T1[] < LAST[i]
            t = LAST[i]
            A[t] = (i,j)
        else
            t = T1[]
            A[t] = (i,j)
            while A[T1[]] !== nothing
                T1[] += 1
            end
        end
    else
        if T2[] < LAST[i]
            t = LAST[i]
            B[t] = (i,j)
        else
            t = T2[]
            B[t] = (i,j)
            while B[T2[]] !== nothing
                T2[] += 1
            end
        end
        # wątpliwe, być może trzeba przenieść pod end
        
    end
    LAST[i] = t + 1
    
    
end