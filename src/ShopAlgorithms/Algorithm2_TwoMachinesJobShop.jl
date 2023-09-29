export algorithm2_two_machines_job_shop

struct BarNode{T_J<:Integer, T_P<:Integer}
    j::Vector{T_J}
    h::T_J
    t::Vector{T_P}
    times::Vector{NamedTuple{(:i,:j,:C), Tuple{T_J,T_J,T_P}}}
    BarNode(j::Vector{T_J}, h::T_J, t::Vector{T_P}) where {T_J <: Integer, T_P <: Integer} = new{T_J, T_P}(j, h, t, [])
    BarNode(j::Vector{T_J}, h::T_J, t::Vector{T_P}, times::Vector{NamedTuple{(:i,:j,:C), Tuple{T_J,T_J,T_P}}}) where {T_J <: Integer, T_P <: Integer}  = new{T_J, T_P}(j, h, t, times)
end

struct BlockNode
    j::Vector{Int64}
    neighborhood::Vector{BlockNode}
    BlockNode(j::Vector{Int64}) = new(j ,[])
    BlockNode(barnode::BarNode) = new(barnode.j, [])
end

function algorithm2_two_machines_job_shop(instance::JobShopInstance)
    T_J::Type = all(instance.n_i .< typemax(Int8)) ? Int8 : all(instance.n_i .< typemax(Int16)) ? Int16 : all(instance.n_i .< typemax(Int32)) ? Int32 : Int64
    T_P::Type = sum(sum(instance.p)) < typemax(Int8) ? Int8 : sum(sum(instance.p)) < typemax(Int16) ? Int16 : sum(sum(instance.p)) < typemax(Int32) ? Int32 : Int64
    T_M::Type = maximum(maximum(instance.μ)) < typemax(Int8) ? Int8 : maximum(maximum(instance.μ)) < typemax(Int16) ? Int16 : maximum(maximum(instance.μ)) < typemax(Int32) ? Int32 : Int64
    return algorithm2_two_machines_job_shop(instance.n, instance.m, T_J.(instance.n_i), convert(Vector{Vector{T_P}},instance.p), convert(Vector{Vector{T_M}},instance.μ))
end

function algorithm2_two_machines_job_shop(
    n::Int64,
    m::Int64,
    n_i::Vector{T_J},
    p::Vector{Vector{T_P}},
    μ::Vector{Vector{T_M}}
) where {T_J <: Integer, T_P <: Integer, T_M <: Integer}
    r = sum(n_i)
    k = n
    previous = Dict{Vector{T_J}, Vector{T_J}}()
    d = Dict{Vector{T_J}, T_P}()
    sizehint = sum(n_i)^n ÷ 1000
    sizehint!(previous, sizehint) 
    sizehint!(d, sizehint)
    d[zeros(T_P, n)] = T_P(0)
    println("essa1")
    neighborhood = two_machines_job_shop_generate_network(n, m, n_i, p, μ)
    println("essa2")
    for (node, succesors) in neighborhood
        for successor in succesors
            if get(d,successor.j, typemax(T_P)) > d[node] + maximum(successor.t)
                d[successor.j] = d[node] + maximum(successor.t)
                previous[successor.j] = node
            end
        end
    end

    C = reconstructpathalgorithm2(n, n_i, neighborhood, previous)

    println("length of neighborhood: $(length(neighborhood))")
    println("r^k: $(r^k)")
    println("% of neighborhood: $(length(neighborhood)/r^k)")


    return ShopSchedule(
        JobShopInstance(n, m, Int64.(n_i), convert(Vector{Vector{Int64}}, p), convert(Vector{Vector{Int64}}, μ)), 
        convert(Vector{Vector{Int64}}, C),
        Int64(maximum(maximum.(C)))
    )
end

sizeofdict(n_i,k) = reduce((*), n_i .^ k; init=1)

function two_machines_job_shop_generate_network(
    n::Int64,
    m::Int64,
    n_i::Vector{T_J},
    p::Vector{Vector{T_P}},
    μ::Vector{Vector{T_M}}
) where {T_J <: Integer, T_P <: Integer, T_M <: Integer}
    neighborhood = OrderedDict{Vector{T_J}, Vector{BarNode{T_J, T_P}}}()
    sizehint = sum(n_i)^n ÷ 1000
    sizehint!(neighborhood, sizehint) 
    stack = Vector{Vector{T_J}}()
    startNode = zeros(T_J, n)
    push!(stack, startNode)
    while !isempty(stack)
        node = pop!(stack)
        barNodes = two_machines_job_shop_generate_block_graph(node, n, m, n_i, p, μ)
        neighborhood[node] = barNodes
        for barNode in filter(x -> x.j ∉ keys(neighborhood), barNodes)
            push!(stack, barNode.j)
        end
    end

    return neighborhood

end

function two_machines_job_shop_generate_block_graph(
    u::Vector{T_J},
    n::Int64,
    m::Int64,
    n_i::Vector{T_J},
    p::Vector{Vector{T_P}},
    μ::Vector{Vector{T_M}}
) where {T_J <: Integer, T_P <: Integer, T_M <: Integer}
    r = sum(n_i)
    k = n 
    barNodes = Vector{BarNode{T_J, T_P}}()
    # sizehint!(barNodes, r^k)
    barNodesSet = Set{Vector{T_J}}()
    sizehint = sum(n_i)^n ÷ 1000 
    sizehint!(barNodesSet, sizehint) 
    barNodesStack = Stack{BarNode{T_J, T_P}}()
    s = BarNode(u, T_J(0), T_P[0, 0])
    push!(barNodes, s)
    push!(barNodesStack, s)
    push!(barNodesSet, s.j)
    while !isempty(barNodesStack)
        node = pop!(barNodesStack)
        # println("node: $(node), length: $(length(barNodesStack))")
        for i = 1:n
            j = copy(node.j)
            j[i] += 1
            

            if j[i] > n_i[i]
                continue
            end
            μ_ij = μ[i][j[i]]
            t = copy(node.t)    
            t[μ_ij] += p[i][j[i]]
            times = copy(node.times)
            push!(times, (i=i, j=j[i], C=t[μ_ij]))
            newnode::Union{BarNode,Nothing} = nothing

            if node.j == s.j
                newnode = BarNode(j, T_J(i), t, times)
            else
                if node.t[1] > node.t[2] && μ_ij == 1
                    newnode = nothing
                elseif node.t[2] > node.t[1] && μ_ij == 2
                    newnode = nothing
                else
                    newnode = BarNode(j, T_J(i), t, times)
                end
            end
            if newnode !== nothing && newnode.j ∉ barNodesSet
                push!(barNodes, newnode)
                push!(barNodesStack, newnode)
                push!(barNodesSet, newnode.j)
            end
        end
    end
    return barNodes
end

function reconstructpathalgorithm2(
    n::Int,
    n_i::Vector{T_J},
    neighborhood::OrderedDict{Vector{T_J}, Vector{BarNode{T_J, T_P}}},
    previous::Dict{Vector{T_J}, Vector{T_J}}
) where {T_J <: Integer, T_P <: Integer}
    r = sum(n_i)
    k = length(n_i)
    C = [[0 for _ in 1:n_i[i]] for i in 1:n]
    path = Vector{Vector{T_J}}()
    current = [n_i[i] for i in 1:n]
    while current !== nothing
        pushfirst!(path, current)
        current = get(previous, current, nothing)
    end
    max_time = 0
    for (point1, point2) in zip(path, Iterators.drop(path, 1))
        current_neighbors = neighborhood[point1]
        times_index = findfirst(x -> x.j == point2, current_neighbors)
        times = current_neighbors[times_index].times
        for time in times
            i,j,C_ij = time.i, time.j, time.C
            C[i][j] = max_time + C_ij
        end
        max_time = maximum(maximum.(C))
    end
    return C

    
end
