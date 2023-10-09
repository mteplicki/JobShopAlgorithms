export dataframe_to_schedules

"""
    to_dataframe(solution::ShopSchedule)

Converts a `ShopSchedule` object to a `DataFrame` object.

# Arguments
- `solution::ShopSchedule`: A `ShopSchedule` object.

# Returns
- `DataFrame`: A `DataFrame` object with columns `job`, `machine`, `starttime`, and `endtime`.
"""
function DataFrames.DataFrame(solution::ShopSchedule)::DataFrame
    dataframe = DataFrame(
        name = String[],
        m = Int[],
        n = Int[],
        n_i = Vector{Int}[],
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
                solution.instance.m,
                solution.instance.n,
                solution.instance.n_i,
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
            ])
        end
    end
    return dataframe
end

# BEGIN: 2b7a3f4d9e7c
"""
# END: 2b7a3f4d9e7c
"""
function dataframe_to_schedules(df::DataFrame)::Vector{ShopSchedule}
    instances = groupby(df, [:solution_id])
    schedules = []
    for instance in instances
        name, m, n, n_i, algorithm, microruns, timeSeconds, memoryBytes = instance[1, [:name, :m, :n, :n_i, :algorithm, :microruns, :timeSeconds. :memoryBytes]]
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
