module ShopAlgorithms
    using OffsetArrays
    using DataStructures
    using Graphs
    include("ObjectiveFunctions/ObjectiveFunction.jl")
    include("ShopInstances/ShopInstance.jl")
    include("ShopInstances/JobShopInstance.jl")
    include("graphs/SimpleWeightedGraphAdj.jl")
    include("graphs/DAGPaths.jl")

    include("JobShopSchedule.jl")

    include("ShopAlgorithms/SingleMachineReleaseLMax.jl")
    include("ShopAlgorithms/Algorithm2_2MachinesJobShop.jl")
    include("ShopAlgorithms/BranchAndBoundJobShop.jl")
    include("ShopAlgorithms/TwoJobsJobShop.jl")

    function test()
        n = 3
        m = 4
        n_i = [3,4,3]
        p = [[10,8,4],[8,3,5,6],[4,7,3]]
        μ = [[1,2,3],[2,1,4,3],[1,2,4]]
        generateActiveSchedules(n,m,n_i,p,μ)
    end
    
    test()
    
    

    

    

end # module JobShopAlgorithms
