function ShiftingBottleneckCarlierTest()
    testsWithResults = [
        ("instances/test.txt", 61, InstanceLoaders.StandardSpecification),
        ("instances/test1.txt", 28, InstanceLoaders.StandardSpecification),
        ("instances/test2.txt", 1036, InstanceLoaders.StandardSpecification),
        ("instances/test3.txt", 666, InstanceLoaders.StandardSpecification),
        ("trickytest/m14n_i6.txt", 49, InstanceLoaders.TaillardSpecification),
        ("trickytest/m10n_i22.txt", 137, InstanceLoaders.TaillardSpecification)
        ]
    @testset "ShiftingBottleneckDPCTests $filename" verbose = true for (filename, expectedValue, specification) in testsWithResults 
        value = Algorithms.shiftingbottleneckcarlier(open(x->read(x, specification), filename)).objectiveValue
        println(filename, ": ", value)
        @test value <= expectedValue
    end

    @testset "ShiftingBottleneckCarlierTests $filename" verbose = true for (filename, expectedValue, specification) in testsWithResults 
        value = Algorithms.shiftingbottleneckcarlier(open(x->read(x, specification), filename); with_dpc=false).objectiveValue
        println(filename, ": ", value)
        @test value <= expectedValue
    end

end