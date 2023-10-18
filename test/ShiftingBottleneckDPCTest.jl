function ShiftingBottleneckDPCTest()
    testsWithResults = [
        ("instances/test.txt", 61, InstanceLoaders.StandardSpecification),
        ("instances/test1.txt", 28, InstanceLoaders.StandardSpecification),
        ("instances/test2.txt", 1024, InstanceLoaders.StandardSpecification),
        ("instances/test3.txt", 666, InstanceLoaders.StandardSpecification),
        ("trickytest/m14n_i6.txt", 49, InstanceLoaders.TaillardSpecification),
        ("trickytest/m10n_i22.txt", 137, InstanceLoaders.TaillardSpecification)
        ]
    @testset "ShiftingBottleneckDPCTests $filename" verbose = true for (filename, expectedValue, specification) in testsWithResults 
        value = Algorithms.shiftingbottleneckdpc(open(x->read(x, specification), filename)).objectiveValue
        println(instances, ": ", value)
        @test value <= expectedValue
    end

end