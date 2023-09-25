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
        rng = MersenneTwister(1234567)
        instance1 = random_instance_generator(11,2; rng=rng, pMax = 1)
        solution2 = generate_active_schedules(instance1)
        println(solution2)
        println(instance1)
        solution = twomachinesjobshop(instance1)
        println(solution)
        p = gantt_chart(solution)
        display(p) 
    end
    # test1()
end # module JobShopAlgorithms
