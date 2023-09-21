module ShopAlgorithms
    using OffsetArrays
    using DataStructures
    using Graphs
    using Plots
    include("ShopInstances/ShopInstance.jl")
    include("ShopInstances/JobShopInstance.jl")
    include("graphs/SimpleWeightedGraphAdj.jl")
    include("graphs/DAGPaths.jl")
    include("ShopInstances/ShopInstance.jl")
    include("ShopInstances/JobShopSchedule.jl")
    include("instanceLoaders/StandardLoader.jl")
    include("randomGenerators/RandomInstanceGenerator.jl")

    include("ShopAlgorithms/Utils.jl")

    include("ShopAlgorithms/SingleMachineReleaseLMax.jl")
    include("ShopAlgorithms/Algorithm2_2MachinesJobShop.jl")
    include("ShopAlgorithms/BranchAndBoundJobShop.jl")
    include("ShopAlgorithms/TwoJobsJobShop.jl")
    include("ShopAlgorithms/ShiftingBottleneck.jl")

    function test1()
        # n = 3
        # m = 4
        # n_i = [3,4,3]
        # p = [[10,8,4],[8,3,5,6],[4,7,3]]
        # μ = [[1,2,3],[2,1,4,3],[1,2,4]]
        # instance = JobShopInstance(n,m,n_i,p,μ)
        # instance = open("test/instances/test2.txt") do data
        #     read(data, StandardSpecification)
        # end
        # println(instance)
        # println(shiftingbottleneck(instance))
        # println("")
        instance1 = open("test/twojobsinstances/test1.txt") do data # 31
            read(data, StandardSpecification)
        end
        
        # instance2 = open("test/twojobsinstances/test2.txt") do data # 36
        #     read(data, StandardSpecification)
        # end
        # println(instance1)
        solution = generate_active_schedules(instance1)
        println(solution)
        # p = plot_solution(solution)
        # display(p)
        solution2 = two_jobs_job_shop(instance1)
        println(solution2)
        
        


    end
    
    test1()
    
    

    

    

end # module JobShopAlgorithms
