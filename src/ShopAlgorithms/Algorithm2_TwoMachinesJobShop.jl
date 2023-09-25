export algorithm2_two_machines_job_shop

struct BarNode
    j::Vector{Int64}
    h::Int64
    t::Vector{Int64}
    times::Vector{NamedTuple{(:i,:j,:C), NTuple{3,Int64}}}
    BarNode(j::Vector{Int64}, h::Int64, t::Vector{Int}) = new(j, h, t, [])
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
    previous = Dict{Vector{Int}, Vector{Int}}()
    neighborhood = two_machines_job_shop_generate_network(n, m, n_i, p, μ)
    for node in values(neighborhood)
        node.l = typemax(Int64)
    end



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
    neighborhood = OrderedDict{Vector{Int}, Vector{NamedTuple}}()
    sizehint!(neighborhood, r^k)
    stack = Vector{Vector{Int}}()
    sizehint!(neighborhood, r^k)
    startNode = BlockNode(zeros(Int64, n))
    push!(stack, startNode)
    while !isempty(stack)
        node = pop!(stack)
        barNodes::Vector{BarNode} = two_machines_job_shop_generate_block_graph(node, n, m, n_i, p, μ)
        filter!(x -> x.j ∉ keys(neighborhood), barNodes)
        neighboursDict = OrderedDict{Vector{Int}, Vector{NamedTuple}}([x.j => (j=x.j, l=max(x.t_A, x.t_B)) for x in barNodes])
        merge!(neighborhood, neighboursDict)
        append!(stack, map(x -> x.j, barNodes))
    end

    return neighborhood

end

function two_machines_job_shop_generate_block_graph(
    node::BlockNode,
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)::Vector{BarNode}
    r = sum(n_i)
    k = n 
    barNodes = Vector{BarNode}()
    sizehint!(barNodes, r^k)
    barNodesSet = Set{Vector{Int}}()
    sizehint!(barNodesSet, r^k)
    barNodesStack = Vector{BarNode}()
    s = BarNode(node.j, 0, [0, 0])
    push!(barNodes, s)
    push!(barNodesStack, s)
    push!(barNodesSet, s.j)
    while !isempty(barNodesStack)
        node = pop!(barNodesStack)
        μ_bar = μ[node.h][node.j[node.h]]
        
        for i = 1:n
            j = copy(node.j)
            j[i] += 1
            μ = μ[i][j[i]]
            t = copy(node.t)    
            t[μ] += p[i][j[i]]
            times = copy(node.times)
            push!(times, (i=i, j=j[i], C=t[μ]))
            node::Union{BarNode,Nothing} = nothing

            if j[i] > n_i[i]
                node = nothing
            elseif j - j[i] == s.j
                node = BarNode(j, i, t)
            else
                if node.t[1] > node.t[2] && μ == 1
                    node = nothing
                elseif node.t[2] > node.t[1] && μ == 2
                    node = nothing
                else
                    node = BarNode(j, i, t)
                end
            end
            if node !== nothing
                if node.j ∉ barNodesSet
                    push!(barNodes, node)
                    push!(barNodesStack, node)
                    push!(barNodesSet, node.j)
                end
            end
    end
    return barNodes
end

function reconstructpath()
    
end

