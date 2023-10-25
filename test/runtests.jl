include("../src/ShopAlgorithms.jl")
using .ShopAlgorithms
using Test
include("BranchAndBoundTest.jl")
include("ShiftingBottleneckTests.jl")
include("LoaderTests.jl")
include("TwoJobsTest.jl")
include("SingleMachineReleaseTests.jl")
include("TrickyTest.jl")
include("DPCTest.jl")
include("TwoMachinesTest.jl")
include("ShiftingBottleneckDPCTest.jl")

@testset "ShopAlgorithmsTests" verbose = true begin

    @testset verbose=true "basetests" begin
        @test 2 == 2
        @test_broken read("../test.txt", ShopAlgorithms.JobShopInstance) |> x -> true
    end

    BranchAndBoundTest()

    ShiftingBottleneckTests()

    LoaderTests()

    TwoJobsTest()

    SingleMachineReleaseLMaxTest()

    TrickyTest()

    TwoMachinesTest()

    DPCTest()

    ShiftingBottleneckCarlierTest()

end


