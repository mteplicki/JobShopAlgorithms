include("../src/ShopAlgorithms.jl")
using .ShopAlgorithms
using  Test

include("BranchAndBoundTest.jl")
include("ShiftingBottleneckTests.jl")
include("LoaderTests.jl")

@testset verbose=true "basetests" begin
    @test 2 == 2
    @test_broken read("../test.txt", ShopAlgorithms.JobShopInstance) |> x -> true
end
