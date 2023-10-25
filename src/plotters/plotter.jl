module Plotters
using ..ShopAlgorithms.ShopInstances
using PlotlyJS
export plot_geometric_approach, gantt_chart

"""
    plot_geometric_approach(solution::ShopSchedule)

This function takes a `ShopSchedule` object as input and returns a plot of the solution using a geometric approach, when n == 2. 
Plot is generated using PlotlyJS.

# Arguments
- `solution::ShopSchedule`: A `ShopSchedule` object representing the solution to a job shop scheduling problem.

# Returns
- A plot of the solution using a geometric approach.

# Examples
```jldoctest
julia> instance = random_instance_generator(2,5);
julia> solution = two_jobs_job_shop(instance);
julia> plot_geometric_approach(solution)
```

"""
function plot_geometric_approach(solution::ShopSchedule; title::Union{Nothing,String}=nothing, width=800, height=800, aspectmode="auto")
    if title === nothing
        title = solution.instance.name
    end
    rectangle(w, h, x, y, machine::String) = scatter(
        x=x .+ [0,w,w,0,0], 
        y=y .+ [0,0,h,h,0], 
        fill="toself", 
        text="Machine $machine",
        showlegend=false)
    textrectangle(w, h, x, y, machine) = scatter(
        x=[x + w/2], 
        y=[y + h/2], 
        text="$machine",
        mode="text",
        showlegend=false)
    solution.instance.n == 2 || throw(ArgumentError("n must be equal to 2"))
    a = [[0], [0]]
    for (index, i) in enumerate(solution.instance.p)
        for j in i
            push!(a[index], a[index][end] + j)
        end
    end
    range1 = a[1][end]
    range2 = a[2][end]
    traces::Vector{GenericTrace} = []
    for i in 1:solution.instance.n_i[1]
        for j in 1:solution.instance.n_i[2]
            if solution.instance.μ[1][i] == solution.instance.μ[2][j]
                x = a[1][i]
                y = a[2][j]
                w = solution.instance.p[1][i]
                h = solution.instance.p[2][j]
                push!(traces, rectangle(w, h, x, y, "$(solution.instance.μ[1][i])"))
                push!(traces, textrectangle(w, h, x, y, "$(solution.instance.μ[1][i])"))
            end
        end
    end  
    lastPosition = [0, 0]
    startTime = solution.C .- solution.instance.p

    C1 = collect(zip(solution.C[1], [1 for i in 1:length(solution.C[1])]))
    C2 = collect(zip(solution.C[2], [2 for i in 1:length(solution.C[1])]))
    C = sort(vcat(C1, C2), by = x -> x[1])
    time = 0
    while !(isempty(C))
        c, job = popfirst!(C)
        progress = c - time
        time = c
        if isempty(startTime[2]) || startTime[2][1] >= time
            push!(traces, scatter(x=[lastPosition[1], lastPosition[1] + progress], y=[lastPosition[2], lastPosition[2]], marker = attr(color="MediumPurple"), showlegend=false))
            lastPosition = [lastPosition[1] + progress, lastPosition[2]] 
        elseif isempty(startTime[1]) || startTime[1][1] >= time
            push!(traces, scatter(x=[lastPosition[1], lastPosition[1]], y=[lastPosition[2], lastPosition[2] + progress], marker = attr(color="MediumPurple"), showlegend=false))
            lastPosition = [lastPosition[1], lastPosition[2] + progress]
        elseif startTime[1][1] < time && startTime[2][1] < time
            push!(traces, scatter(
                x=[lastPosition[1], lastPosition[1] + progress], 
                y=[lastPosition[2], lastPosition[2] + progress], 
                marker = attr(color="LightSkyBlue"), showlegend=false))
            lastPosition = [lastPosition[1] + progress, lastPosition[2] + progress]
        end
        deleteat!(startTime[job], 1)
    end

    xticktext = []
    xtickvals = []
    for (index, (pos1,pos2)) in enumerate(zip(a[1], Iterators.drop(a[1], 1)))
        push!(xticktext, "M$(solution.instance.μ[1][index])")
        push!(xtickvals, (pos1+pos2)/2)
    end
    yticktext = []
    ytickvals = []
    for (index, (pos1,pos2)) in enumerate(zip(a[2], Iterators.drop(a[2], 1)))
        push!(yticktext, "M$(solution.instance.μ[2][index])")
        push!(ytickvals, (pos1+pos2)/2)
    end

    xtickvalsprim = a[1]
    ytickvalsprim = a[2]


    p = plot(traces, Layout(
        xaxis = attr(
            tickmode="array",
            ticktext=xticktext,
            tickvals=xtickvals,
            range=[-1, range1 + 1],
            showgrid=false,
            title = attr(
                text = "Job 1"
            )
        ),
        yaxis = attr(
            tickmode="array",
            ticktext=yticktext,
            tickvals=ytickvals,
            range=[-1, range2 + 1],
            showgrid=false,
            title = attr(
                text = "Job 2"
            )
        ),
        scene = attr(
            aspectmode=aspectmode
        ),
        width=width,
        height=height,
        title="Two jobs plot, geometric approach"))
    return p
end

"""
    gantt_chart(solution::ShopSchedule)

Create a Gantt chart for a given `ShopSchedule` solution.

# Arguments
- `solution::ShopSchedule`: A `ShopSchedule` object representing a solution to a job shop scheduling problem.

# Returns
- A plot of the solution using a Gantt chart.
"""
function gantt_chart(solution::ShopSchedule; kwargs...)
    kwargs = Dict(kwargs)

    traces = if haskey(kwargs, :show_blocks) 
        [[
        bar(
            y = string.(solution.instance.μ[i]), 
            x = solution.instance.p[i], 
            base = solution.C[i] - solution.instance.p[i], 
            name = "Job $i", 
            text = ["($i, $k)" for k in 1:solution.instance.n_i[i]],
            textposition = "inside",
            insidetextanchor = "middle",
            orientation="h") for i in 1:solution.instance.n]; 
        [scatter(
            x=[x1,x1],
            y=[0.5,2.5],
            mode="lines",
            color="black",
            showlegend=false
        ) for x1 in [0,6,19,58,99] ]
    ]
    else
        [
        bar(
            y = string.(solution.instance.μ[i]), 
            x = solution.instance.p[i], 
            base = solution.C[i] - solution.instance.p[i], 
            name = "Job $i", 
            text = ["($i, $k)" for k in 1:solution.instance.n_i[i]],
            textposition = "inside",
            insidetextanchor = "middle",
            orientation="h") for i in 1:solution.instance.n]
    end

    p = plot(traces,

    Layout(
        barmode="stack", 
        yaxis=attr(
            showline=true,
            title = attr(
                text = "Machine"
            ),
            categoryorder = "category descending",
            range = [0.5,2.5]
        ),
        xaxis = if haskey(kwargs, :show_blocks) 
        attr(
            ticktext=["t$i" for i in 0:4],
            tickvals=[0,6,19,58,99],
            # tickson="boundaries",
            tickwidth=3,
            tickcolor="#000000"


        ) 
        else 
            attr(
            title=attr(
                text="Time"
            )
        )
        end
        ,
        title="Gantt chart"))
    return p
end


end