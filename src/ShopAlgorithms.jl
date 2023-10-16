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
        # for x in 5:1:5
        #     filename = "test/instances/test5.txt"
        #     result1 = Algorithms.shiftingbottleneck(open(x->read(x, InstanceLoaders.StandardSpecification), filename))
        #     println(result1)
        #     result2 = Algorithms.shiftingbottleneckdpc(open(x->read(x, InstanceLoaders.StandardSpecification), filename))
        #     println(result2)
        #     # rng = MersenneTwister(1234567)
        #     # instance = random_instance_generator(3x,x; rng=rng, pMax = 5x, pMin = x, n_i=fill(x, 3x))
        #     # println(instance)
        #     # result = shiftingbottleneck(instance)
        #     # println(result) 
        #     # println(shiftingbottleneckdpc(instance))
        # end
        # rng = MersenneTwister(1234532)
        # rng = MersenneTwister(123453)
        # instance1 = InstanceLoaders.random_instance_generator(5,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:5], machine_repetition=true)
        # println(instance1)
        # result11 = Algorithms.algorithm2_two_machines_job_shop(instance1)
        # println(result11)
        # result12 = Algorithms.generate_active_schedules(instance1)
        # println(result12)
        # result13 = Algorithms.generate_active_schedules(instance1; bounding_algorithm=:pmtn)
        # println(result13)
        instance = open(x->read(x, InstanceLoaders.TaillardSpecification), "test/trickytest/n10n_i14.txt")
        println(instance)
        result = Algorithms.shiftingbottleneckdpc(instance; yielding=true)
        println(result)
        # result14 = Algorithms.generate_active_schedules_dpc(instance1)
        # println(result14)
        # println("feasible: ", ShopInstances.check_feasability(result11))
        # Plotters.gantt_chart(result11)
    end
    # test1()
end # module JobShopAlgorithms
