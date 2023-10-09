module Constraints    
    export machine_lower_limit, machine_upper_limit, machine_equals, job_lower_limit, job_upper_limit, job_equals, job_recirculation, machine_repetition
    export processing_time_lower_limit, processing_time_upper_limit, processing_time_equals
    
    machine_lower_limit(limit::Int) = instance->instance.m ≥ limit
    machine_upper_limit(limit::Int) = instance->instance.m ≤ limit
    machine_equals(to::Int) = instance->instance.m == to

    job_lower_limit(limit::Int) = instance->instance.n ≥ limit
    job_upper_limit(limit::Int) = instance->instance.n ≤ limit
    job_equals(to::Int) = instance->instance.n == to

    processing_time_lower_limit(limit::Int) = instance->all(all(p_ij ≥ limit for p_ij in p_i) for p_i in instance.p)
    processing_time_upper_limit(limit::Int) = instance->all(all(p_ij ≤ limit for p_ij in p_i) for p_i in instance.p)
    processing_time_equals(to::Int) = instance->all(all(p_i .== to) for p_i in instance.p)
    processing_time_equals(to::Vector{Int}) = instance->all(all(p_i .== to[i]) for (i, p_i) in enumerate(instance.p))

    job_recirculation() = instance -> any(sort(collect(Set(x))) ≠ sort(x) for x in instance.μ)

    machine_repetition() = instance -> any(any(machine1 == machine2 for (machine1, machine2) in zip(x, Iterators.drop(x, 1))) for x in instance.μ)
end