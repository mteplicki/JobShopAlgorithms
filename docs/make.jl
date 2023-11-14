using Documenter, ShopAlgorithms
using ShopAlgorithms.ShopInstances, ShopAlgorithms.ShopGraphs, ShopAlgorithms.InstanceLoaders, ShopAlgorithms.Plotters, ShopAlgorithms.Constraints, ShopAlgorithms.Algorithms
push!(LOAD_PATH,"../src/")

makedocs(
    sitename="ShopAlgorithms.jl",
    pages=[
        "Home" => "index.md",
        "Algorithms" => "algorithms.md",
        "Constraints" => "constraints.md",
        "InstanceLoaders" => "instance_loaders.md",
        "Plotters" => "plotters.md",
        "ShopGraphs" => "shop_graphs.md",
        "ShopInstances" => "shop_instances.md"
        ]
               )