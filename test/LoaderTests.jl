import .ShopAlgorithms: JobShopInstance, shiftingbottleneck, StandardSpecification, TaillardSpecification, read, write, JobShopFileSpecification

n = 3
m = 4
n_i = [3,4,3]
p = [[10,8,4],[8,3,5,6],[4,7,3]]
μ = [[1,2,3],[2,1,4,3],[1,2,4]]
baseinstance = JobShopInstance(n,m,n_i,p,μ)


names = [
    "test.txt",
    "test1.txt", 
    "test2.txt",
    "test3.txt"
    ]

files = "instances/" .* names

function save_and_read(::Type{T}, instance::JobShopInstance, filename::AbstractString) where {T <: JobShopFileSpecification}
    write("loaderinstances/$(T)$(filename)", T(instance))
    return read("loaderinstances/$(T)$(filename)", T)
end

instances = map(files) do filename
    read(filename, StandardSpecification)
end

@testset "LoaderTest" verbose = true begin
    @testset "BaseLoaderTests" begin
        @test instances[2] == baseinstance
        @test save_and_read(StandardSpecification, baseinstance, "test.txt") == baseinstance
    end
    
    @testset "TaillardSpecificationTests $name"for (instance, name) in zip(instances, names)
        @test save_and_read(TaillardSpecification, instance, name) == instance
    end

    @testset "StandardSpecificationTests $name" for (instance, name) in zip(instances, names)
        @test save_and_read(StandardSpecification, instance, name) == instance
    end
end