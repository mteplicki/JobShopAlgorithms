module ShopAlgorithms
    using OffsetArrays
    using DataStructures
    using Graphs
    using PlotlyJS
    using DataFrames
    using Random
    include("ShopInstances/ShopInstance.jl")
    include("ShopInstances/JobShopInstance.jl")
    include("graphs/SimpleWeightedGraphAdj.jl")
    include("graphs/DAGPaths.jl")
    include("ShopInstances/ShopInstance.jl")
    include("ShopInstances/JobShopSchedule.jl")
    include("instanceLoaders/StandardLoader.jl")
    include("randomGenerators/RandomInstanceGenerator.jl")
    include("plots/TwoJobPlot.jl")

    include("ShopAlgorithms/Utils.jl")

    include("ShopAlgorithms/SingleMachineReleaseLMax.jl")
    include("ShopAlgorithms/Algorithm2_TwoMachinesJobShop.jl")
    include("ShopAlgorithms/BranchAndBoundJobShop.jl")
    include("ShopAlgorithms/TwoJobsJobShop.jl")
    include("ShopAlgorithms/ShiftingBottleneck.jl")
    include("ShopAlgorithms/TwoMachinesJobShop.jl")

    function test1()
        rng = MersenneTwister(123453)
        instance1 = random_instance_generator(2,4; rng=rng, job_recirculation=true, n_i=[40,40])
        solution = two_jobs_job_shop(instance1)
        println(instance1)
        println(solution)
        display(gantt_chart(solution))
        display(plot_geometric_approach(solution))
        solution = generate_active_schedules(instance1)
        println(solution)
        # p = gantt_chart(solution)
        # display(p) 
        # r = [0, 10, 9, 18]
        # p = [8, 8, 7, 4]
        # d = [8, 18, 19, 22]
        # println(single_machine_release_LMax(p,r,d))

    end
    # test1()
end # module JobShopAlgorithms
