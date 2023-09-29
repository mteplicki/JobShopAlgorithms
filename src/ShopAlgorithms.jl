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

    include("ShopAlgorithms/dpc_algorithms.jl")
    include("ShopAlgorithms/SingleMachineReleaseLMax.jl")

    include("ShopAlgorithms/Algorithm2_TwoMachinesJobShop.jl")
    include("ShopAlgorithms/BranchAndBoundJobShop.jl")
    include("ShopAlgorithms/TwoJobsJobShop.jl")
    include("ShopAlgorithms/ShiftingBottleneck.jl")
    include("ShopAlgorithms/TwoMachinesJobShop.jl")
    include("ShopAlgorithms/ShiftingBottleneckDPC.jl")

    function test1()
        #bardzo zły przypadek 
        rng = MersenneTwister(1234531)
        instance1 = random_instance_generator(5,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:5], machine_repetition=true)

        println(instance1)
        solution1 = algorithm2_two_machines_job_shop(instance1)
        println(solution1)
        
        
        
        solution2 = generate_active_schedules(instance1)
        println(solution2)
        display(gantt_chart(solution1))

        p = gantt_chart(solution2)
        display(p) 
        # r = [0, 10, 9, 18]
        # p = [8, 8, 7, 4]
        # d = [8, 18, 19, 22]
        # println(single_machine_release_LMax(p,r,d))

    end
    # test1()
end # module JobShopAlgorithms
