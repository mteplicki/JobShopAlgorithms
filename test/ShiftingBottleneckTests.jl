import .ShopAlgorithms: JobShopInstance, shiftingbottleneck, StandardSpecification
import Random: MersenneTwister

global testsWithResults = [
    ("instances/test.txt", 59),
    ("instances/test1.txt", 28), 
    ("instances/test2.txt", 1019),
    ("instances/test3.txt", 666)
    ]
@testset "ShiftingBottleneckTests" verbose = true for (filename, expectedValue) in testsWithResults 
    @test shiftingbottleneck(open(x->read(x, StandardSpecification), filename)).objectiveValue <= expectedValue
end

@testset "ShiftingBottleneckTestsRecirculation" verbose = true for x in 3:2:11
    rng = MersenneTwister(123)
    instance = random_instance_generator(x,x; rng=rng, pMax = 3x, pMin = x, n_i=fill(x, x), job_recirculation=true)
    @test (shiftingbottleneck(instance);true) skip = true
end

