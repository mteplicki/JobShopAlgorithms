module ShopAlgorithms
    include("constraints/constraints.jl")
    include("shop_instances/shop_instances.jl")
    include("instance_loaders/instance_loaders.jl")
    include("shop_graphs/shop_graphs.jl")
    include("algorithms/algorithms.jl")
    include("plotters/plotter.jl")
    export Algorithms, ShopInstances, InstanceLoaders, Plotters, Constraints, ShopGraphs


    using Random
    function test1()
        rng = MersenneTwister(125)
        instance = InstanceLoaders.random_instance_generator(11,2; rng=rng, job_recirculation=true, n_i = [11 for i in 1:11], machine_repetition=true)
        println(instance)
        # instance = open(x->read(x, InstanceLoaders.StandardSpecification), "test/instances/test1.txt")
        # println(instance)
        result = Algorithms.shiftingbottleneckcarlier(instance; with_dpc=false)
        println(result)
        result = Algorithms.shiftingbottleneckcarlier(instance; carlier_timeout=0.01, carlier_depth=0)
        result = Algorithms.shiftingbottleneckcarlier(instance; carlier_timeout=0.01, carlier_depth=0)
        println(result)
        result = Algorithms.shiftingbottleneckcarlier(instance; carlier_timeout=0.01)
        println(result)
        result2 = Algorithms.branchandbound_carlier(instance; with_dpc=false, with_priority_queue=true)
        result2 = Algorithms.branchandbound_carlier(instance; with_dpc=false, with_priority_queue=true)
        println(result2)
        result2 = Algorithms.branchandbound_carlier(instance; with_dpc=false, with_priority_queue=false)
        result2 = Algorithms.branchandbound_carlier(instance; with_dpc=false, with_priority_queue=false)
        println(result2)
    end
    # test1()
end # module JobShopAlgorithms
