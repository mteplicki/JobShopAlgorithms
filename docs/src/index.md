# ShopAlgorithms documentation

Main documentation for ShopAlgorithms.jl. This package provides a framework for solving shop scheduling problems.
It is a part of a project for my master thesis. 

## Installation
Currently, this package is not registered in a Julia Packages Registry. To install it, run the following command in the Julia REPL:
```julia
import Pkg
Pkg.add(https://github.com/mteplicki/JobShopAlgorithms)
```

## Usage
```julia
using ShopAlgorithms
instance = read("path/to/instance", InstanceLoaders.StandardSpecification)
results = Algorithms.bnbcarlier(instance)
println(results)
```

## Documentation

The package consists of the following submodules:

```@docs
ShopAlgorithms
ShopAlgorithms.Algorithms
ShopAlgorithms.ShopInstances
ShopAlgorithms.InstanceLoaders
ShopAlgorithms.Plotters
ShopAlgorithms.Constraints
ShopAlgorithms.ShopGraphs
```

## Extensions

To extend the package, you can define your own algorithms. To do so, you need to define a function that takes as input an instance and returns a `ShopResult` object. 
