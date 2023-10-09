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

struct SweepOrdering <: Base.Order.Ordering
end

function Base.Order.lt(::SweepOrdering, p1::Point, p2::Point)
    if p1.coordinate.y - p1.coordinate.x < p2.coordinate.y - p2.coordinate.x
        return true
    elseif p1.coordinate.y - p1.coordinate.x > p2.coordinate.y - p2.coordinate.x
        return false
    else
        if p1.obstacleNumber < p2.obstacleNumber
            return true
        else
            return false
        end
    end
end

"""
    two_jobs_job_shop(instance::JobShopInstance)

Solves the two jobs job shop `J | n=2 | Cmax` problem for a given `instance` of `JobShopInstance` with recirculation and machine
repetition allowed. Complexity: `O(r log r)`, where `r = sum(n_i)` is the number of operations.

# Arguments
- `instance::JobShopInstance`: An instance of the job shop problem.

# Returns
- `ShopSchedule`: A `ShopSchedule` object representing the solution to the job shop problem.

"""
function two_jobs_job_shop(
    instance::JobShopInstance
)
    _ , timeSeconds, bytes = @timed begin 
    n, m, n_i, p, μ = instance.n, instance.m, instance.n_i, instance.p, instance.μ
    job_equals(2)(instance) || throw(ArgumentError("n must be equal to 2"))
    additionalInformation = Dict{String, Any}()

    points, obstacles, size = createpoints(n_i, p, μ)
    network, ONumber = createnetwork(points, obstacles)
    d = OffsetArray([Int64(typemax(Int32)) for _ in 1:(length(points))], -1)
    previous::Vector{Union{Nothing, Int}} = [nothing for _ in 1:(length(points)-1)]
    
    d[ONumber] = 0
    for node in network
        for successor in node.Successors
            if d[successor.successorNumber] > d[successor.from] + successor.distance
                d[successor.successorNumber] = d[successor.from] + successor.distance
                previous[successor.successorNumber] = successor.from
            end
        end
    end
    C = reconstructpath(n_i, p, obstacles, points, previous)
    end
    return ShopSchedule(
        instance, 
        C,
        max(maximum(C[1]), maximum(C[2])),
        Cmax_function;
        algorithm = "Two jobs job shop - geometric approach",
        timeSeconds = timeSeconds,
        memoryBytes = bytes,
        )
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
    Fpoint = Point(Coordinate(size[1], size[2]), typemax(Int), length(points), F)
    push!(points, Fpoint)
    return points, obstacles, size
end

function distance(point1::Point, point2::Point)
    return abs(abs(point1.coordinate.x - point2.coordinate.x) - abs(point1.coordinate.y - point2.coordinate.y))
end


function createnetwork(
    pointsUnsorted::OffsetVector{Point},
    obstacles::Vector{Obstacle}
)
    network = OffsetVector([NetworkNode(Vector{Successor}()) for _ in 1:length(pointsUnsorted)], -1)
    
    S = SortedSet{Int}()
    Fpoint = pointsUnsorted[end]
    points = sort(pointsUnsorted, alg=MergeSort, order=SweepOrdering(), rev=true)
    
    # create network
    ONumber = 0
    for point in points
        #pole do debugowania
        if point.type == F
            continue
        end
        (_, currentToken) = insert!(S, point.obstacleNumber) 
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
    return network, ONumber
end

function reconstructpath(
    n_i::Vector{Int},
    p::Vector{Vector{Int}},
    obstacles::Vector{Obstacle},
    points::OffsetVector{Point},
    previous::Vector{Union{Nothing, Int}}
)
    FNumber = length(points) - 1
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
