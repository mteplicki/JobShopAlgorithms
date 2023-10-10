export dataframe_to_schedules

"""
    DataFrame(solution::ShopSchedule)

Converts a `ShopSchedule` object to a `DataFrame` object.

# Arguments
- `solution::ShopSchedule`: A `ShopSchedule` object.

# Returns
- `DataFrame`: A `DataFrame` object with columns:
    - `name`: name of the instance
    - `date`: date and time when the solution was generated
    - `m`: number of machines
    - `n`: number of jobs
    - `d`: due date of the job
    - `solution_id`: unique identifier for each solution
    - `algorithm`: name of the algorithm used to generate the solution
    - `objectiveValue`: value of the objective function
    - `objectiveFunction`: name of the objective function
    - `job`: job number
    - `operation`: operation number
    - `machine`: machine number where the operation was executed
    - `processing_time`: processing time of the operation
    - `starttime`: start time of the operation
    - `endtime`: end time of the operation
    - `microruns`: number of microruns used by the algorithm
    - `timeSeconds`: time in seconds used by the algorithm
    - `memoryBytes`: memory used by the algorithm
"""
function DataFrames.DataFrame(solution::ShopSchedule)::DataFrame
    dataframe = DataFrame(
        name = String[],
        date = DateTime[],
        m = Int[],
        n = Int[],
        d = [],
        solution_id = Int[],
        algorithm = String[],
        objectiveValue = Int64[],
        objectiveFunction = String[],
        job = Int64[],
        operation = Int64[],
        machine = Int64[],
        processing_time = Int64[],
        starttime = Int64[],
        endtime = Int64[],
        microruns = Int64[],
        timeSeconds = Float64[],
        memoryBytes = Int64[]
    )
    for (index, i) in enumerate(solution.C)
        for (index2, j) in enumerate(i)
            push!(dataframe, [
                solution.instance.name,
                Dates.now(),
                solution.instance.m,
                solution.instance.n,
                solution.instance.d[index],
                hash(solution),
                solution.algorithm,
                solution.objectiveValue,
                string(solution.objectiveFunction),
                index,
                index2,
                solution.instance.μ[index][index2],
                solution.instance.p[index][index2],
                j - solution.instance.p[index][index2],
                j,
                solution.microruns,
                solution.timeSeconds,
                solution.memoryBytes
            ]; promote=true)
        end
    end
    return dataframe
end

"""
    dataframe_to_schedules(df::DataFrame)::Vector{ShopSchedule}

Converts a `DataFrame` to a `Vector` of `ShopSchedule` objects. The `DataFrame` should have the following columns:
- `solution_id`: unique identifier for each solution
- `name`: name of the instance
- `m`: number of machines
- `n`: number of jobs
- `algorithm`: name of the algorithm used to generate the solution
- `microruns`: number of microruns used by the algorithm
- `timeSeconds`: time in seconds used by the algorithm
- `memoryBytes`: memory used by the algorithm
- `job`: job number
- `operation`: operation number
- `endtime`: end time of the operation
- `processing_time`: processing time of the operation
- `machine`: machine number where the operation was executed
- `d`: due date of the job

Returns a `Vector` of `ShopSchedule` objects, each representing a solution in the `DataFrame`.
"""
function dataframe_to_schedules(df::DataFrame)::Vector{ShopSchedule}
    instances = groupby(df, [:solution_id])
    schedules = []
    for instance in instances
        name, m, n, algorithm, microruns, timeSeconds, memoryBytes = instance[1, [:name, :m, :n, :algorithm, :microruns, :timeSeconds, :memoryBytes]]
        n_i = [0 for _ in 1:n]
        for row in eachrow(combine(groupby(instance, [:job]), nrow => :count))
            n_i[row[:job]] = row[:count]
        end
        C = [[0 for _ in 1:n_i[j]] for j in 1:n]
        p = [[0 for _ in 1:n_i[j]] for j in 1:n]
        μ = [[0 for _ in 1:n_i[j]] for j in 1:n]
        d = [0 for _ in 1:n]
        for row in eachrow(instance)
            C[row[:job]][row[:operation]] = row[:endtime]
            p[row[:job]][row[:operation]] = row[:processing_time]
            μ[row[:job]][row[:operation]] = row[:machine]
            d[row[:job]] = row[:d]
        end
        jobShopInstance = JobShopInstance(n, m, n_i, p, μ; name=name, d=d)
        if instance[1, :objectiveFunction] == "Cmax_function"
            objectiveFunction = Cmax_function
        elseif instance[1, :objectiveFunction] == "Lmax_function"
            objectiveFunction = Lmax_function
        end
        objectiveValue = instance[1, :objectiveValue]
        push!(schedules, ShopSchedule(jobShopInstance, C, objectiveValue, objectiveFunction; algorithm=algorithm, microruns=microruns, timeSeconds=timeSeconds, memoryBytes=memoryBytes))
    end
    return schedules
end
