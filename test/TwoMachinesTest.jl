function TwoMachinesTest()
    @testset "TwoMachinesTest" verbose = true begin 
        @testset "TwoMachinesTest1" begin
            #bardzo zły przypadek 
            rng = MersenneTwister(1234531)
            instance1 = InstanceLoaders.random_instance_generator(5,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:5], machine_repetition=true)
            two_machines_objective = Algorithms.algorithm2_two_machines_job_shop(instance1).objectiveValue
            @test two_machines_objective == 90
            branch_and_bound_objective = Algorithms.generate_active_schedules(instance1).objectiveValue
            @test branch_and_bound_objective == 90
            @test branch_and_bound_objective == two_machines_objective
        end
        @testset "TwoMachinesTest2" begin
            #bardzo zły przypadek 
            rng = MersenneTwister(123453)
            instance1 = InstanceLoaders.random_instance_generator(5,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:5], machine_repetition=true)
            two_machines_objective = Algorithms.algorithm2_two_machines_job_shop(instance1).objectiveValue
            @test two_machines_objective == 72
            branch_and_bound_objective = Algorithms.generate_active_schedules(instance1).objectiveValue
            @test branch_and_bound_objective == 72
            @test branch_and_bound_objective == two_machines_objective
        end
        @testset "TwoMachinesTest3" begin
            #bardzo zły przypadek 
            rng = MersenneTwister(1234)
            instance1 = InstanceLoaders.random_instance_generator(4,2; rng=rng, job_recirculation=true, n_i=[6 for _ in 1:4], machine_repetition=true)
            two_machines_objective = Algorithms.algorithm2_two_machines_job_shop(instance1).objectiveValue
            branch_and_bound_objective = Algorithms.generate_active_schedules(instance1).objectiveValue
            @test branch_and_bound_objective == two_machines_objective
        end
    end
end