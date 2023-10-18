module ShopAlgorithms
    include("constraints/constraints.jl")
    include("shop_instances/shop_instances.jl")
    include("instance_loaders/instance_loaders.jl")
    include("shop_graphs/shop_graphs.jl")
    include("algorithms/algorithms.jl")
    include("plotter/plotter.jl")
    export Algorithms, ShopInstances, InstanceLoaders, Plotters, Constraints


    using Random
    function test1()
        instance = open(x->read(x, InstanceLoaders.TaillardSpecification), "test/trickytest/m102n_i102.txt")
        println(instance)
        result = Algorithms.two_jobs_job_shop(instance)
        println(result)
    end
    # test1()
end # module JobShopAlgorithms
