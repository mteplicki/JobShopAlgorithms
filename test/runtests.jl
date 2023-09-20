include("../src/ShopAlgorithms.jl")
using .ShopAlgorithms
using  Test
include("BranchAndBoundTest.jl")
@testset "basetests" begin
    @test 2 == 2
    @test read("../test.txt", ShopAlgorithms.JobShopInstance) |> x -> true
end
