import .ShopAlgorithms: JobShopInstance, generate_active_schedules, StandardSpecification

testsWithResults = [
    ("instances/test1.txt", 28), 
    ("instances/test.txt", 55)
    #, ("instances/test3.txt", 666)
    ]
@testset "BranchAndBoundTest" verbose = true for (filename, expectedValue) in testsWithResults 
    @test generate_active_schedules(open(x->read(x, StandardSpecification), filename)).objectiveValue == expectedValue
end