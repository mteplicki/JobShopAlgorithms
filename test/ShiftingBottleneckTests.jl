import Random: MersenneTwister

function ShiftingBottleneckTests()

testsWithResults = [
    ("instances/test.txt", 59),
    ("instances/test1.txt", 28), 
    ("instances/test2.txt", 1019),
    ("instances/test3.txt", 666)
    ]
@testset "ShiftingBottleneckTests" verbose = true for (filename, expectedValue) in testsWithResults 
    @test Algorithms.shiftingbottleneck(open(x->read(x, InstanceLoaders.StandardSpecification), filename)).objectiveValue <= expectedValue
end

end



