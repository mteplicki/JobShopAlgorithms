# do usunięcia
using DataStructures

TwoJobsJobShop(instance::JobShopInstance) = TwoJobsJobShop(
    instance.n,
    instance.m,
    instance.n_i,
    instance.p,
    instance.μ
)

function TwoJobsJobShop(
    n::Int64,
    m::Int64,
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}},
)
    n == 2 || throw(ArgumentError("n must be equal to 2"))
    (points, obstacles, size) = createPoints(n_i, p, μ)
    (network, points, ONumber) = createNetwork(points, obstacles, size)
    d = [typemax(Int64) for _ in 1:(length(points) + 1)]
    previous = [typemax(Int64) for _ in 1:(length(points) + 1)]
    d[ONumber] = 0
    for node in network
        for successor in node.Successors
            if d[successor.successorNumber] > d[successor.from] + successor.distance
                d[successor.successorNumber] = d[successor.from] + successor.distance
                previous[successor.successorNumber] = successor.from
            end
        end
    end
    return reconstructPath(n_i, p, obstacles, points, length(points) + 1, ONumber, previous)
end

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
    obstacleNumber::Union{Int64, Nothing}
    pointNumber::Union{Int64, Nothing}
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
    successorNumber::Int64
    distance::Int64
    from::Int64
end

struct NetworkNode
    Successors::Vector{Successor}
end

function reconstructPath(
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    obstacles::Vector{Obstacle},
    points::Vector{Point},
    FNumber::Int64,
    ONumber::Int64,
    previous::Vector{Int}
)
    path = Vector{Int64}()
    current = FNumber
    while current != ONumber
        pushfirst!(path, current)
        current = previous[current]
    end
    t = [0,0]
    currentJob = [0,0]
    time = [Vector{Int64}(), Vector{Int64}()]

    #TODO do poprawy nextObstacleNumber
    for (index, pointNumber) in enumerate(path)
        nextPointNumber = path[index + 1]
        nextPoint = points[nextPointNumber]
        nextObstacleNumber = points[nextPointNumber].obstacleNumber
        nextObstacle = obstacles[nextObstacleNumber]
        if nextPoint.type == SE
            for job in (currentJob[1] + 1):(nextObstacle.job1)
                t[1] += p[1,nextObstacle.job]
                push!(time[1], t[1])
            end
            for job in (currentJob[2] + 1):(nextObstacle.job2 - 1)
                t[2] += p[2,nextObstacle.job]
                push!(time[2], t[2])
            end
            t[2] = t[1]
        elseif nextPoint.type == NW
            for job in (currentJob[1] + 1):(nextObstacle.job1 - 1)
                t[1] += p[1,nextObstacle.job]
                push!(time[1], t[1])
            end
            for job in (currentJob[2] + 1):(nextObstacle.job2)
                t[2] += p[2,nextObstacle.job]
                push!(time[2], t[2])
            end
            t[1] = t[2]
        else # F-type point
            for job in (currentJob[1] + 1):(n_i[1])
                t[1] += p[1,nextObstacle.job]
                push!(time[1], t[1])
            end
            for job in (currentJob[2] + 1):(n_i[2])
                t[2] += p[2,nextObstacle.job]
                push!(time[2], t[2])
            end
        end
    end
    return time

end
function createPoints(
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    μ::Vector{Vector{Int}}
)
    size = [0,0]
    distanceFromOrigin =[Vector{Int64}(),Vector{Int64}()] 
    for i=1:2
        for j in 1:n_i[i]
            size[i] += p[i][j]
            push!(distanceFromOrigin[i], size[i])
        end
    end
    obstacles = Vector{Obstacle}()
    points = Vector{Point}()
    obstacleCount = 0
    for j in 1:n_i[2]
        for k in 1:n_i[1]
            if μ[1][k] == μ[2][j]
                obstacleCount += 1
                NWpoint = Point(Coordinate(distanceFromOrigin[1][k]-p[1][k], distanceFromOrigin[2][j]),obstacleCount, nothing, NW)
                SEpoint = Point(Coordinate(distanceFromOrigin[1][k], distanceFromOrigin[2][j]-p[2][j]),obstacleCount, nothing, SE)
                obstacle = Obstacle(NWpoint, SEpoint, obstacleCount, k, j)
                push!(obstacles, obstacle)
                push!(points, NWpoint)
                push!(points, SEpoint)
            end
        end
    end
    return points, obstacles, size
end

function distance(point1::Point, point2::Point)
    return abs(abs(point1.coordinate.x - point2.coordinate.x) - abs(point1.coordinate.y - point2.coordinate.y))
end


function createNetwork(
    points::Vector{Point},
    obstacles::Vector{Obstacle},
    size::Vector{Int},
)
    network = OffsetVector([NetworkNode(Vector{Successor}()) for i in 1:length(points)], -1)
    push!(points, Point(Coordinate(0,0), 0, nothing, O))
    S=SortedSet{Int}()
    sort!(points, alg = MergeSort(), by = point -> point.coordinate.y - point.coordinate.x, rev=true)
    for index in eachindex(points)
        points[index].pointNumber = index
    end
    F = Point(Coordinate(size[1],size[2]), nothing, length(points) + 1, F)
    # create network
    ONumber = 0
    for point in points
        #pole do debugowania
        (_, currentToken) = insert!(S, point.obstacleNumber) # dziwne
        advanceToken = advance((S, currentToken))
        startingObstacle = point.obstacleNumber
        if status(advanceToken) == 3 # 3 - to jest token na końcu
            push!(network[startingObstacle].Successors, Successor(F.pointNumber, distance(point, F), point.pointNumber))
        else
            obstacle::Obstacle = obstacles[deref((S,advanceToken))]
            push!(network[startingObstacle].Successors, Successor(obstacle.SE.pointNumber, distance(point, obstacle.SE), point.pointNumber))
            push!(network[startingObstacle].Successors, Successor(obstacle.NW.pointNumber, distance(point, obstacle.NW), point.pointNumber))
        end
        if point.type == SE || point.type == O
            ONumber = point.pointNumber
            S = delete!(S, point.obstacle)
        end
    end
    return network, points, ONumber
end