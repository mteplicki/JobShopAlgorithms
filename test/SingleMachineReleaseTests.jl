import ShopAlgorithms: Algorithms.single_machine_release_LMax

function SingleMachineReleaseLMaxTest()

@testset "SingleMachineReleaseTests.jl" begin
    r = [0, 10, 9, 18]
    p = [8, 8, 7, 4]
    d = [8, 18, 19, 22]
    @test single_machine_release_LMax(p,r,d) == (6, [1, 3, 2, 4])
    p = [8,8,7]
    r = [10,0,4]
    d = [18,8,19]
    @test single_machine_release_LMax(p,r,d) == (5, [2, 3, 1])
end

end