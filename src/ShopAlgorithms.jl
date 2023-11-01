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
        rng = MersenneTwister(1234)
        # instance = InstanceLoaders.random_instance_generator(4,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:4], machine_repetition=true)

        instance = open(x->read(x, InstanceLoaders.StandardSpecification), "test/instances/test1.txt")
        println(instance)
        result = Algorithms.branchandbound_carlier(instance; with_dpc=false, with_priority_queue=false)
        result = Algorithms.branchandbound_carlier(instance; with_dpc=false, with_priority_queue=false)
        println(result)
        result2 = Algorithms.branchandbound(instance)
        result2 = Algorithms.branchandbound(instance)
        println(result2)
    end
    test1()
end # module JobShopAlgorithms
