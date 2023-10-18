function BranchAndBoundTest()

testsWithResults = [
    ("instances/test1.txt", 28, InstanceLoaders.StandardSpecification), 
    ("instances/test.txt", 55, InstanceLoaders.StandardSpecification), 
    ("instances/test3.txt", 666, InstanceLoaders.StandardSpecification),
    ("trickytest/m14n_i6.txt", 49, InstanceLoaders.TaillardSpecification),
    ("trickytest/m10n_i22.txt", 137, InstanceLoaders.TaillardSpecification)
    ]
@testset "BranchAndBoundTest $filename" verbose = true for (filename, expectedValue, specification) in testsWithResults 
    # println(filename)
    @test Algorithms.generate_active_schedules(open(x->read(x, specification), filename)).objectiveValue == expectedValue
    # println("done")
end

end