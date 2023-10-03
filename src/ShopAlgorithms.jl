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
        for x in 3:1:8
            # result1 = shiftingbottleneck(open(x->read(x, StandardSpecification), filename))
            # println(result1)
            # result2 = shiftingbottleneckdpc(open(x->read(x, StandardSpecification), filename))
            # println(result2)
            rng = MersenneTwister(1234)
            instance = random_instance_generator(2x,x; rng=rng, pMax = 3x, pMin = x, n_i=fill(x, 2x))
            println(instance)
            result = shiftingbottleneck(instance)
            println(result) 
            println(shiftingbottleneckdpc(instance))
        end
    end
    test1()
end # module JobShopAlgorithms
