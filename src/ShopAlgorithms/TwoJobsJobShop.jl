# do usunięcia
using DataStructures

function TwoJobsJobShop(
    n::Int64,
    m::Int64,
    n_i::Array{Int64,1},
    p::Array{Union{Int64, Nothing},2},
    μ::Array{Union{Int64, Nothing},2},
    d::Array{Int64,1},
)
    @assert n == 2 "n not equals to 2"
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
    reconstructPath(n_i, p, μ, length(points) + 1, ONumber, previous)
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
    n_i::Array{Int64,1},
    p::Array{Union{Int64, Nothing},2},
    μ::Array{Union{Int64, Nothing},2},
    FNumber::Int64,
    ONumber::Int64,
    previous::Array{Int64,1}
)
    path = Vector{Int64}()
    current = FNumber
    while current != zeroPointNumber
        pushfirst!(path, current)
        current = previous[current]
    end
    
end
function createPoints(
    n_i::Array{Int64,1},
    p::Array{Union{Int64, Nothing},2},
    μ::Array{Union{Int64, Nothing},2}
)
    size = [0,0]
    distanceFromOrigin =[Vector{Int64}(),Vector{Int64}()] 
    for i=1:2
        for j in 1:n_i[i]
            size[i] += p[i,j]
            push!(distanceFromOrigin[i], size[i])
        end
    end
    obstacles = Vector{Obstacle}()
    points = Vector{Point}()
    obstacleCount = 0
    for j in 1:n_i[2]
        for k in 1:n_i[1]
            if μ[1,k] == μ[2,j]
                obstacleCount += 1
                NWpoint = Point(Coordinate(distanceFromOrigin[1][k]-p[1,k], distanceFromOrigin[2][j]),obstacleCount, nothing, NW)
                SEpoint = Point(Coordinate(distanceFromOrigin[1][k], distanceFromOrigin[2][j]-p[2,j]),obstacleCount, nothing, SE)
                push!(obstacles, Obstacle(NWpoint, SEpoint, obstacleCount))
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
    size::Array{Int64,1},
)
    network = OffsetVector([NetworkNode(Vector{Successor}()) for i in 1:length(points)], -1)
    push!(points, Point(Coordinate(0,0), 0, nothing, O))
    S=SortedSet{Int}()
    sort!(points, alg = MergeSort(), by = point -> point.coordinate.y - point.coordinate.x, rev=true)
    for index in indices(sortPoints)
        sortPoints[index].pointNumber = index
    end
    F = Point(Coordinate(size[1],size[2]), nothing, length(points) + 1, F)
    # create network
    zeroPointNumber = 0
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
            zeroPointNumber = point.pointNumber
            S = delete!(S, point.obstacle)
        end
    end
    return network, points, zeroPointNumber
end