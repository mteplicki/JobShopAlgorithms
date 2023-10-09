function BranchAndBoundTest()

testsWithResults = [
    ("instances/test1.txt", 28), 
    ("instances/test.txt", 55)
    #, ("instances/test3.txt", 666)
    ]
@testset "BranchAndBoundTest" verbose = true for (filename, expectedValue) in testsWithResults 
    @test Algorithms.generate_active_schedules(open(x->read(x, InstanceLoaders.StandardSpecification), filename)).objectiveValue == expectedValue
end

end