module ShopAlgorithms
    using OffsetArrays
    using DataStructures
    using Graphs
    include("ShopInstances/ShopInstance.jl")
    include("ShopInstances/JobShopInstance.jl")
    include("graphs/SimpleWeightedGraphAdj.jl")
    include("graphs/DAGPaths.jl")
    include("ShopInstances/ShopInstance.jl")
    include("ShopInstances/JobShopSchedule.jl")
    include("instanceLoaders/StandardLoader.jl")

    include("ShopAlgorithms/Utils.jl")

    include("ShopAlgorithms/SingleMachineReleaseLMax.jl")
    include("ShopAlgorithms/Algorithm2_2MachinesJobShop.jl")
    include("ShopAlgorithms/BranchAndBoundJobShop.jl")
    include("ShopAlgorithms/TwoJobsJobShop.jl")
    include("ShopAlgorithms/ShiftingBottleneck.jl")

    function test()
        n = 3
        m = 4
        n_i = [3,4,3]
        p = [[10,8,4],[8,3,5,6],[4,7,3]]
        μ = [[1,2,3],[2,1,4,3],[1,2,4]]
        instance = JobShopInstance(n,m,n_i,p,μ)
        # instance = open(readStandardFormat, "test.txt")
        # println(instance)
        # println(generateActiveSchedules(instance))
        # println("")
    end
    
    test()
    
    

    

    

end # module JobShopAlgorithms
