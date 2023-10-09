module ShopAlgorithms
    include("shop_instances/shop_instances.jl")
    include("instance_loaders/instance_loaders.jl")
    include("shop_graphs/shop_graphs.jl")
    include("algorithms/algorithms.jl")
    include("plotter/plotter.jl")
    include("constraints/constraints.jl")
    export Algorithms, ShopInstances, InstanceLoaders, Plotter


    function test1()
        for x in 5:1:5
            filename = "test/instances/test5.txt"
            result1 = Algorithms.shiftingbottleneck(open(x->read(x, InstanceLoaders.StandardSpecification), filename))
            println(result1)
            result2 = Algorithms.shiftingbottleneckdpc(open(x->read(x, InstanceLoaders.StandardSpecification), filename))
            println(result2)
            # rng = MersenneTwister(1234567)
            # instance = random_instance_generator(3x,x; rng=rng, pMax = 5x, pMin = x, n_i=fill(x, 3x))
            # println(instance)
            # result = shiftingbottleneck(instance)
            # println(result) 
            # println(shiftingbottleneckdpc(instance))
        end
    end
    # test1()
end # module JobShopAlgorithms
