@testset "BranchAndBoundTricky" begin
        #bardzo zły przypadek 
        rng = MersenneTwister(1234531)
        instance1 = random_instance_generator(5,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:5], machine_repetition=true)

        println(instance1)
        solution1 = algorithm2_two_machines_job_shop(instance1)
        println(solution1)
        
        solution2 = generate_active_schedules(instance1)
        println(solution2)
end

@testset "ShiftingBottleneckTestsRecirculationTricky" verbose = true for x in 3:2:11
    rng = MersenneTwister(123)
    instance = random_instance_generator(x,x; rng=rng, pMax = 3x, pMin = x, n_i=fill(x, x), job_recirculation=true)
    @test (shiftingbottleneck(instance);true) 
    @test (shiftingbottleneckdpc(instance);true)
end