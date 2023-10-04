# @testset "BranchAndBoundTricky" begin
#         #bardzo zły przypadek 
#         rng = MersenneTwister(1234531)
#         algorithm2_two_machines_job_shop
#         instance1 = random_instance_generator(5,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:5], machine_repetition=true)
#         two_machines_objective = algorithm2_two_machines_job_shop(instance1).objectiveValue
#         @test two_machines_objective == 85 
#         branch_and_bound_objective = generate_active_schedules(instance1).objectiveValue
#         @test branch_and_bound_objective == 90
#         @test branch_and_bound_objective > two_machines_objective
# end

@testset "ShiftingBottleneckTestsRecirculationTricky $x" verbose = true for x in 3:2:11
    rng = MersenneTwister(123)
    instance = random_instance_generator(x,x; rng=rng, pMax = 3x, pMin = x, n_i=fill(x, x), job_recirculation=true)
    if x <= 8
        @test (shiftingbottleneck(instance);true)
    else
        @test_throws ArgumentError shiftingbottleneck(instance)
        println("test1")
    end
    @test (shiftingbottleneckdpc(instance);true)
    println("test2")
end

# nie działa to na razie