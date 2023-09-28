export algorithm2_two_machines_job_shop

struct BarNode
    j::Vector{Int64}
    h::Int64
    t::Vector{Int64}
    times::Vector{NamedTuple{(:i,:j,:C), NTuple{3,Int64}}}
    BarNode(j::Vector{Int64}, h::Int64, t::Vector{Int}) = new(j, h, t, [])
    BarNode(j::Vector{Int64}, h::Int64, t::Vector{Int}, times::Vector{NamedTuple{(:i,:j,:C), NTuple{3,Int64}}}) = new(j, h, t, times)
end

struct BlockNode
    j::Vector{Int64}
    neighborhood::Vector{BlockNode}
    BlockNode(j::Vector{Int64}) = new(j ,[])
    BlockNode(barnode::BarNode) = new(barnode.j, [])
end

algorithm2_two_machines_job_shop(instance::JobShopInstance) = algorithm2_two_machines_job_shop(
    instance.n,
    instance.m,
    instance.n_i,
    instance.p,
    instance.μ
)

function algorithm2_two_machines_job_shop(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    r = sum(n_i)
    k = n
    previous = Dict{Vector{Int}, Vector{Int}}()
    d = Dict{Vector{Int}, Int64}()
    # sizehint!(d, r^k)
    # sizehint!(previous, r^k)
    d[zeros(Int64, n)] = 0
    neighborhood = two_machines_job_shop_generate_network(n, m, n_i, p, μ)
    for (node, succesors) in neighborhood
        for (successor_k, successor) in succesors
            if get(d,successor_k, typemax(Int)) > d[node] + successor.distance
                d[successor_k] = d[node] + successor.distance
                previous[successor_k] = node
            end
        end
    end

    C = reconstructpathalgorithm2(n, n_i, neighborhood, previous)

    return ShopSchedule(
        JobShopInstance(n, m, n_i, p, μ), 
        C,
        (maximum∘maximum)(C))
end

function two_machines_job_shop_generate_network(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    r = sum(n_i)
    k = n
    neighborhood = OrderedDict{Vector{Int}, Dict}()
    # sizehint!(neighborhood, r^k)
    stack = Vector{Vector{Int}}()
    # sizehint!(neighborhood, r^k)
    startNode = zeros(Int64, n)
    push!(stack, startNode)
    while !isempty(stack)
        node = pop!(stack)
        barNodes = two_machines_job_shop_generate_block_graph(node, n, m, n_i, p, μ)
        neighborhood[node] = Dict([barNode.j => (distance=max(barNode.t[1], barNode.t[2]), times=barNode.times) for barNode in barNodes])
        filter!(x -> x.j ∉ keys(neighborhood), barNodes)
        for barNode in barNodes
            push!(stack, barNode.j)
        end
    end

    return neighborhood

end

function two_machines_job_shop_generate_block_graph(
    u::Vector{Int},
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)::Vector{BarNode}
    r = sum(n_i)
    k = n 
    barNodes = Vector{BarNode}()
    # sizehint!(barNodes, r^k)
    barNodesSet = Set{Vector{Int}}()
    # sizehint!(barNodesSet, r^k)
    barNodesStack = Vector{BarNode}()
    s = BarNode(u, 0, [0, 0])
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
                newnode = BarNode(j, i, t, times)
            else
                if node.t[1] > node.t[2] && μ_ij == 1
                    newnode = nothing
                elseif node.t[2] > node.t[1] && μ_ij == 2
                    newnode = nothing
                else
                    newnode = BarNode(j, i, t, times)
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
    n_i::Vector{Int},
    neighborhood::OrderedDict{Vector{Int}, Dict},
    previous::Dict{Vector{Int}, Vector{Int}}
)
    r = sum(n_i)
    k = length(n_i)
    C = [[0 for _ in 1:n_i[i]] for i in 1:n]
    path = Vector{Vector{Int}}()
    current = [n_i[i] for i in 1:n]
    while current !== nothing
        pushfirst!(path, current)
        current = get(previous, current, nothing)
    end
    max_time = 0
    for (point1, point2) in zip(path, Iterators.drop(path, 1))
        for time in neighborhood[point1][point2].times
            i,j,C_ij = time.i, time.j, time.C
            C[i][j] = max_time + C_ij
        end
        max_time = (maximum∘maximum)(C)
    end
    return C

    
end
