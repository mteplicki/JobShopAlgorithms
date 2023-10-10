module Algorithms
    using ..ShopAlgorithms
    using ..ShopAlgorithms.ShopInstances
    using ..ShopAlgorithms.ShopGraphs
    using DataStructures, Graphs, OffsetArrays
    using ..ShopAlgorithms.Constraints
    import ..ShopAlgorithms.ShopInstances.ObjectiveFunction
    import Graphs.add_edge!
    include("utils.jl")
    include("dpc_algorithms.jl")
    include("single_machine_release_lmax.jl")
    include("branch_and_bound_jobshop.jl")
    include("branch_and_bound_dpc.jl")
    include("shifting_bottleneck.jl")
    include("shifting_bottleneck_dpc.jl")
    include("two_jobs_job_shop.jl")
    include("two_machines_job_shop.jl")
    include("algorithm2_twomachinesjobshop.jl")
    
    
    

end