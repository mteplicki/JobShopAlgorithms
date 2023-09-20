import .ShopAlgorithms: JobShopInstance, generateActiveSchedules

testBranchAndBound(filename::AbstractString, expectedValue::Int) = testBranchAndBound(read(filename, JobShopInstance), expectedValue)
testBranchAndBound(instance::JobShopInstance, expectedValue::Int) = 
testsWithResults = [("instances/test1.txt", 28), ]
@testset "BranchAndBoundTest" for (filename, expectedValue) in testsWithResults
    # @test testBranchAndBound("instances/test.txt", 55)
    @test generateActiveSchedules(instance).objectiveValue == 28
end