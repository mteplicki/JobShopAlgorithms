# Instance Loaders

The `InstanceLoaders` module provides functions to load instances from files. It also provides functions to generate random instances.

## Loading instances from files

The `Base.read` function can be used to load an instance from a file. It takes as input the path to the file and returns an instance. There are two types of specification: `StandardSpecification` and `TaillardSpecification`.

```@docs
StandardSpecification
TaillardSpecification
```

```julia
# Reading a instance
Base.read(data::IO, ::Type{T}) where {T <: JobShopFileSpecification} 
```

## Saving instances to files

The `Base.write` function can be used to save an instance to a file. It takes as input the path to the file and the instance.

```julia
# Writing a instance
Base.write(data::IO, specification::T) where {T <: JobShopFileSpecification}
```

## Generating random instances

The `InstanceLoaders` module provides functions to generate random instances. The `random_instance_generator` function can be used to generate a random instance. 

```@docs
random_instance_generator
```



