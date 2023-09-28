import DataStructures: insert!
export two_jobs_job_shop

@enum PointType begin
    NW
    SE
    O
    F
end

struct Coordinate
    x::Int64
    y::Int64
end

mutable struct Point
    coordinate::Coordinate
    obstacleNumber::Union{Int64,Nothing}
    pointNumber::Union{Int64,Nothing}
    type::PointType
end

struct Obstacle
    NW::Point
    SE::Point
    obstacleNumber::Int64
    job1::Int64
    job2::Int64
end

struct Successor
    point::Point
    successorNumber::Int64
    distance::Int64
    from::Int64
end

struct NetworkNode
    Successors::Vector{Successor}
end

struct LexicographicOrdering <: Base.Order.Ordering
end

Base.Order.lt(::LexicographicOrdering, p1::Point, p2::Point) = p1.coordinate.y < p2.coordinate.y || (p1.coordinate.y == p2.coordinate.y && p1.coordinate.x < p2.coordinate.x)

two_jobs_job_shop(instance::JobShopInstance) = two_jobs_job_shop(
    instance.n,
    instance.m,
    instance.n_i,
    instance.p,
    instance.μ
)

function two_jobs_job_shop(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}},
)
    n == 2 || throw(ArgumentError("n must be equal to 2"))
    (points, obstacles, size) = createpoints(n_i, p, μ)
    (network, _, ONumber) = createnetwork(points, obstacles, size)
    d = OffsetArray([Int64(typemax(Int32)) for _ in 1:(length(points)+1)], -1)
    previous::Vector{Union{Nothing, Int}} = [nothing for _ in 1:(length(points)+1)]
    
    d[ONumber] = 0
    for node in network
        for successor in node.Successors
            if d[successor.successorNumber] > d[successor.from] + successor.distance
                d[successor.successorNumber] = d[successor.from] + successor.distance
                previous[successor.successorNumber] = successor.from
            end
        end
    end
    C = reconstructpath(n_i, p, obstacles, points, length(points) - 1, ONumber, previous)
    return ShopSchedule(
        JobShopInstance(n, m, n_i, p, μ), 
        C,
        max(maximum(C[1]), maximum(C[2])))
end

function createpoints(
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    size = [0, 0]
    distanceFromOrigin = [Vector{Int64}(), Vector{Int64}()]
    for i = 1:2
        for j in 1:n_i[i]
            size[i] += p[i][j]
            push!(distanceFromOrigin[i], size[i])
        end
    end
    obstacles = Vector{Obstacle}()
    points = OffsetVector{Point}([Point(Coordinate(0, 0), 0, 0, O)], -1)
    obstacleCount = 0
    pointCount = 1
    for j in 1:n_i[2]
        for k in 1:n_i[1]
            if μ[1][k] == μ[2][j]
                obstacleCount += 1
                # if obstacleCount == 28
                #     println("tralala")
                # end
                NWpoint = Point(Coordinate(distanceFromOrigin[1][k] - p[1][k], distanceFromOrigin[2][j]), obstacleCount, pointCount, NW)
                SEpoint = Point(Coordinate(distanceFromOrigin[1][k], distanceFromOrigin[2][j] - p[2][j]), obstacleCount, pointCount + 1, SE)
                pointCount += 2
                obstacle = Obstacle(NWpoint, SEpoint, obstacleCount, k, j)
                push!(obstacles, obstacle)
                push!(points, NWpoint)
                push!(points, SEpoint)
            end
        end
    end
    Fpoint = Point(Coordinate(size[1], size[2]), nothing, length(points), F)
    push!(points, Fpoint)
    return points, obstacles, size
end

function distance(point1::Point, point2::Point)
    return abs(abs(point1.coordinate.x - point2.coordinate.x) - abs(point1.coordinate.y - point2.coordinate.y))
end


function createnetwork(
    pointsUnsorted::OffsetVector{Point},
    obstacles::Vector{Obstacle},
    size::Vector{Int},
)
    network = OffsetVector([NetworkNode(Vector{Successor}()) for _ in 1:length(pointsUnsorted)], -1)
    
    S = SortedSet{Int}()
    Fpoint = pointsUnsorted[end]
    points = sort(pointsUnsorted, alg=MergeSort, by=point -> point.coordinate.y - point.coordinate.x, rev=true)
    
    # create network
    ONumber = 0
    for point in points
        #pole do debugowania
        if point.type == F
            continue
        end
        (_, currentToken) = insert!(S, point.obstacleNumber) # dziwne
        advanceToken = advance((S, currentToken))
        startingObstacle = point.pointNumber
        if status((S,advanceToken)) == 3 # 3 - to jest token na końcu
            push!(network[startingObstacle].Successors, Successor(Fpoint,Fpoint.pointNumber, distance(point, Fpoint), point.pointNumber))
        else
            obstacle::Obstacle = obstacles[deref((S, advanceToken))]
            push!(network[startingObstacle].Successors, Successor(pointsUnsorted[obstacle.SE.pointNumber],obstacle.SE.pointNumber, distance(point, obstacle.SE), point.pointNumber))
            push!(network[startingObstacle].Successors, Successor(pointsUnsorted[obstacle.NW.pointNumber],obstacle.NW.pointNumber, distance(point, obstacle.NW), point.pointNumber))
        end
        if point.type == SE || point.type == O
            S = delete!(S, point.obstacleNumber)
        end
        if point.type == O
            ONumber = point.pointNumber
        end
    end
    return network, points, ONumber
end

function reconstructpath(
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    obstacles::Vector{Obstacle},
    points::OffsetVector{Point},
    FNumber::Int64,
    ONumber::Int64,
    previous::Vector{Union{Nothing, Int}}
)
    path = Vector{Int64}()
    current = FNumber
    while current != 0
        pushfirst!(path, current)
        current = previous[current]
    end
    pushfirst!(path, 0)
    t = [0, 0]
    currentJob = [0, 0]
    time = [Vector{Int64}(), Vector{Int64}()]

    #TODO do poprawy nextObstacleNumber
    for index in Iterators.take(eachindex(path), length(path)-1)
        nextPointNumber = path[index+1]
        nextPoint = points[nextPointNumber]
        
        if nextPoint.type == SE
            nextObstacleNumber = points[nextPointNumber].obstacleNumber
            nextObstacle = obstacles[nextObstacleNumber]
            for job in (currentJob[1]+1):(nextObstacle.job1)
                t[1] += p[1][job]
                push!(time[1], t[1])
            end
            for job in (currentJob[2]+1):(nextObstacle.job2-1)
                t[2] += p[2][job]
                push!(time[2], t[2])
            end
            t[2] = t[1]
            currentJob[1] = nextObstacle.job1
            currentJob[2] = nextObstacle.job2 - 1
        elseif nextPoint.type == NW
            nextObstacleNumber = points[nextPointNumber].obstacleNumber
            nextObstacle = obstacles[nextObstacleNumber]
            for job in (currentJob[1]+1):(nextObstacle.job1-1)
                t[1] += p[1][job]
                push!(time[1], t[1])
            end
            for job in (currentJob[2]+1):(nextObstacle.job2)
                t[2] += p[2][job]
                push!(time[2], t[2])
            end
            t[1] = t[2]
            currentJob[1] = nextObstacle.job1 - 1
            currentJob[2] = nextObstacle.job2
        else # F-type point
            for job in (currentJob[1]+1):(n_i[1])
                t[1] += p[1][job]
                push!(time[1], t[1])
            end
            for job in (currentJob[2]+1):(n_i[2])
                t[2] += p[2][job]
                push!(time[2], t[2])
            end
        end
    end
    return time

end
