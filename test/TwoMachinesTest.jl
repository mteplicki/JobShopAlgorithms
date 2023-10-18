function TwoMachinesTest()
    @testset "TwoMachinesTest" verbose = true begin 
        @testset "TwoMachinesTest1" begin
            #bardzo zły przypadek 
            rng = MersenneTwister(1234531)
            instance1 = InstanceLoaders.random_instance_generator(5,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:5], machine_repetition=true)
            timed = @timed two_machines_result = Algorithms.algorithm2_two_machines_job_shop(instance1)
            @test two_machines_result.objectiveValue == 90
            # println(timed)
            # println(two_machines_result.metadata)
            branch_and_bound_objective = Algorithms.generate_active_schedules(instance1).objectiveValue
            @test branch_and_bound_objective == 90
            @test branch_and_bound_objective == two_machines_result.objectiveValue
            # println("done")
        end
        @testset "TwoMachinesTest2" begin
            #bardzo zły przypadek 
            rng = MersenneTwister(123453)
            instance1 = InstanceLoaders.random_instance_generator(5,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:5], machine_repetition=true)
            timed = @timed two_machines_result = Algorithms.algorithm2_two_machines_job_shop(instance1)
            @test two_machines_result.objectiveValue == 72
            # println(timed)
            # println(two_machines_result.metadata)
            branch_and_bound_objective = Algorithms.generate_active_schedules(instance1).objectiveValue
            @test branch_and_bound_objective == 72
            @test branch_and_bound_objective == two_machines_result.objectiveValue
            # println("done")
        end
        @testset "TwoMachinesTest3" begin
            #bardzo zły przypadek 
            rng = MersenneTwister(1234)
            instance1 = InstanceLoaders.random_instance_generator(4,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:4], machine_repetition=true)
            timed = @timed two_machines_result = Algorithms.algorithm2_two_machines_job_shop(instance1)
            # println(timed)
            # println(two_machines_result.metadata)
            branch_and_bound_objective = Algorithms.generate_active_schedules(instance1).objectiveValue
            @test branch_and_bound_objective == two_machines_result.objectiveValue
            # println("done")
        end
    end
end

n = 4
m = 2
n_i = [6, 6, 6, 6]
p = [[9, 6, 9, 6, 7, 7], [8, 6, 8, 10, 8, 9], [6, 7, 6, 8, 8, 10], [6, 8, 6, 8, 9, 8]]
μ = [[1, 2, 2, 2, 1, 1], [1, 2, 2, 2, 1, 1], [1, 1, 2, 1, 1, 1], [1, 2, 1, 2, 2, 2]]