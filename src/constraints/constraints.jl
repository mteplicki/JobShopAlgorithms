module Constraints    
    machine_lower_limit(limit::Int) = instance->instance.m ≥ limit
    machine_upper_limit(limit::Int) = instance->instance.m ≤ limit
    machine_equals(to::Int) = instance->instance.m == to
    job_lower_limit(limit::Int) = instance->instance.n ≥ limit
    job_upper_limit(limit::Int) = instance->instance.n ≤ limit
    job_equals(to::Int) = instance->instance.n == to

    job_recirculation() = instance -> any(sort(collect(Set(x))) ≠ sort(x) for x in instance.μ)

    machine_repetition() = instance -> any(any(machine1 == machine2 for (machine1, machine2) in zip(x, Iterators.drop(x, 1))) for x in instance.μ)
end