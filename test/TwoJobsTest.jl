# BEGIN: abpxx6d04wxr
import Random: MersenneTwister
import .ShopAlgorithms: two_jobs_job_shop, generate_active_schedules, random_instance_generator
testsWithResults = [
    ("twojobsinstances/test1.txt", 31),
    ("twojobsinstances/test2.txt", 36)
    ]
rng = MersenneTwister(123456)
@testset "TwoJobsTest" verbose = true begin
    @testset "TwoJobsTestFromFile $filename" verbose = true for (filename, expectedValue) in testsWithResults 
        @test two_jobs_job_shop(open(x->read(x, StandardSpecification), filename)).objectiveValue <= expectedValue
    end
    @testset "TwoJobsTestRandom $i" for i in 3:2:11
        instance = random_instance_generator(2,i; rng=rng, pMax = 3i, pMin = i)
        @test two_jobs_job_shop(instance).objectiveValue == generate_active_schedules(instance).objectiveValue
    end
    @testset "TwoJobsTestWithRecirculation $i" for i in 3:2:11
        instance = random_instance_generator(2,i; rng=rng, pMax = 3i, pMin = i, n_i=[2i,2i], job_recirculation=true)
        @test two_jobs_job_shop(instance).objectiveValue == generate_active_schedules(instance).objectiveValue
    end
end
# END: abpxx6d04wxr