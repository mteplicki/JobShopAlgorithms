function TrickyTest()
    
@testset "TrickyTests" verbose = true begin


    @testset "ShiftingBottleneckTestsRecirculationTricky $x" verbose = true for x in 3:2:9
        rng = MersenneTwister(123)
        instance = InstanceLoaders.random_instance_generator(x,x; rng=rng, pMax = 3x, pMin = x, n_i=fill(x, x), job_recirculation=true)
        if x <= 8
            @test (Algorithms.shiftingbottleneck(instance; suppress_warnings=true);true)
        else
            @test_throws ArgumentError Algorithms.shiftingbottleneck(instance; suppress_warnings=true)
        end
        @test (Algorithms.shiftingbottleneckdpc(instance);true)
    end

end

end

# nie działa to na razie