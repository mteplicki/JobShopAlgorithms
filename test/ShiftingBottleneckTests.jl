import Random: MersenneTwister

function ShiftingBottleneckTests()

testsWithResults = [
        ("instances/test.txt", 59, InstanceLoaders.StandardSpecification),
        ("instances/test1.txt", 28, InstanceLoaders.StandardSpecification), 
        ("instances/test2.txt", 1019, InstanceLoaders.StandardSpecification),
        ("instances/test3.txt", 711, InstanceLoaders.StandardSpecification),
        ("trickytest/m14n_i6.txt", 49, InstanceLoaders.TaillardSpecification),
        ("trickytest/m10n_i22.txt", 137, InstanceLoaders.TaillardSpecification)
    ]
@testset "ShiftingBottleneckTests $filename" verbose = true for (filename, expectedValue, specification) in testsWithResults 
    value = Algorithms.shiftingbottleneck(open(x->read(x, specification), filename); suppress_warnings=true).objectiveValue
    # println(instances, ": ", value)
    @test value <= expectedValue
end

end



