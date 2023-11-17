"""
This module contains the implementation of algorithms for solving job shop scheduling problems.
It exports the following modules: Algorithms, ShopInstances, InstanceLoaders, Plotters, Constraints, ShopGraphs.
"""
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
        result2 = Algorithms.branchandbound_carlier(instance; with_dpc=false, with_priority_queue=false, heuristic_UB=true)
        println(result2)
    end
    test1()
end # module JobShopAlgorithms
