import .ShopAlgorithms: JobShopInstance, shiftingbottleneck, StandardSpecification

global testsWithResults = [
    ("instances/test.txt", 59),
    ("instances/test1.txt", 28), 
    ("instances/test2.txt", 1019),
    ("instances/test3.txt", 666)
    ]
@testset "ShiftingBottleneckTests" verbose = true for (filename, expectedValue) in testsWithResults 
    @test shiftingbottleneck(open(x->read(x, StandardSpecification), filename)).objectiveValue <= expectedValue
end