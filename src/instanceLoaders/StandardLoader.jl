function readStandardFormat(data::IO)
    n, m = parse.(Int,split(readline(data), " "))
    μ = Vector{Vector{Int}}()
    p = Vector{Vector{Int}}()
    for _ in 1:n
        list = parse.(Int,split(readline(data), " "))
        μ_i = list[(1:length(list)) .% 2 .== 1]
        μ_i .+= 1
        p_i = list[(1:length(list)) .% 2 .== 0]
        push!(μ, μ_i)
        push!(p, p_i)
    end
    n_i = map(length, μ)
    return JobShopInstance(n, m, n_i, p, μ)
end

function writeStandardFormat(instance::JobShopInstance, data::IO=IOBuffer())
    println(data, "$(instance.n) $(instance.m)")
    for (μ_i, p_i) in zip(instance.μ, instance.p)
        list = zeros(Int, length(p_i)*2 )
        list[(1:length(list)) .% 2 .== 1] .= (μ_i .- 1)
        list[(1:length(list)) .% 2 .== 0] .= p_i
        println(data, join(list, " "))
    end
    return data
end