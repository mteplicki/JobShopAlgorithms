"""
This module contains functions that define constraints for the job shop scheduling problem. Every method
in a module should return a function that takes an instance of the problem and returns a boolean value.
"""
module Constraints    
    export machine_lower_limit, machine_upper_limit, machine_equals, job_lower_limit, job_upper_limit, job_equals, job_recirculation, machine_repetition
    export processing_time_lower_limit, processing_time_upper_limit, processing_time_equals
    
    """
        machine_lower_limit(limit::Int)

    Checks if the lower limit of the machine is greater than or equal to the given limit.

    # Arguments
    - `limit::Int`: the limit to check against the lower limit of the machine.

    # Returns
    function that takes an instance of the problem and returns a boolean value: 
    `true` if the lower limit of the machine is greater than or equal to the given limit, `false` otherwise.    
    """
    machine_lower_limit(limit::Int) = instance->instance.m ≥ limit

    """
        machine_upper_limit(limit::Int)

    Checks if the upper limit of the machine is less than or equal to the given limit.

    # Arguments
    - `limit::Int`: The maximum limit allowed for the machine.

    # Returns
    a function that takes an instance of the problem and returns a boolean value:
    `true` if the upper limit of the machine is less than or equal to the given limit, `false` otherwise.
    """
    machine_upper_limit(limit::Int) = instance->instance.m ≤ limit

    """
        machine_equals(to::Int)

    Returns a function that takes an instance and returns a boolean indicating whether the instance's m field is equal to the given integer `to`.

    # Arguments
    - `to::Int`: The integer to compare the instance's m field to.

    # Returns
    A function that takes an instance and returns a boolean indicating whether the instance's m field is equal to the given integer `to`.
    """
    machine_equals(to::Int) = instance->instance.m == to

    """
        job_lower_limit(limit::Int)

    Check if the number of jobs in the instance is greater than or equal to the given limit.

    # Arguments
    - `limit::Int`: The lower limit to check against the number of jobs in the instance.

    # Returns
    A function that takes an instance and returns a boolean value: 
    `true` if the number of jobs in the instance is greater than or equal to the given limit, `false` otherwise.
    """
    job_lower_limit(limit::Int) = instance->instance.n ≥ limit
    
    """
        job_upper_limit(limit::Int)

    Check if the number of jobs in the instance is lower than or equal to the given limit.

    # Arguments
    - `limit::Int`: The upper limit to check against the number of jobs in the instance.

    # Returns
    A function that takes an instance and returns a boolean value: 
    `true` if the number of jobs in the instance is less than or equal to the given limit, `false` otherwise.
    """
    job_upper_limit(limit::Int) = instance->instance.n ≤ limit

    """
        job_equals(to::Int)

    Returns a function that takes an instance and returns a boolean indicating whether the instance's number of jobs is equal to the given integer `to`.

    # Arguments
    - `to::Int`: The integer to compare the instance's number of jobs.

    # Returns
    A function that takes an instance and returns a boolean indicating whether the instance's number of jobs is equal to the given integer `to`.
    """
    job_equals(to::Int) = instance->instance.n == to

    """
        processing_time_lower_limit(limit::Int)

    Returns a funtion indicating whether all processing times in the instance are greater than or equal to the given limit.

    # Arguments
    - `limit::Int`: The lower limit for processing times.

    # Returns
    A function that takes an instance and returns a boolean value:
    `true` if all processing times in the instance are greater than or equal to the given limit, `false` otherwise.
    """
    processing_time_lower_limit(limit::Int) = instance->all(all(p_ij ≥ limit for p_ij in p_i) for p_i in instance.p)


    """
        processing_time_upper_limit(limit::Int)

    Returns a function indicating whether all processing times in the instance are less than or equal to the given limit.

    # Arguments
    - `limit::Int`: The upper limit for processing times.

    # Returns
    A function that takes an instance and returns a boolean value:
    `true` if all processing times in the instance are less than or equal to the given limit, `false` otherwise.
    """
    processing_time_upper_limit(limit::Int) = instance->all(all(p_ij ≤ limit for p_ij in p_i) for p_i in instance.p)
    processing_time_equals(to::Int) = instance->all(all(p_i .== to) for p_i in instance.p)
    processing_time_equals(to::Vector{Int}) = instance->all(all(p_i .== to[i]) for (i, p_i) in enumerate(instance.p))

    """
        machine_repetition()

    Returns a function indicating whether any machine is repeated in the instance.

    # Returns
    A function that takes an instance and returns a boolean value:
    `true` if any machine is repeated in the instance, `false` otherwise.
    """
    job_recirculation() = instance -> any(sort(collect(Set(x))) ≠ sort(x) for x in instance.μ)

    """
        machine_repetition()

    Returns a function indicating whether any jobs has to be processed in the same machine more than once in a row.

    # Returns
    A function that takes an instance and returns a boolean value:
    `true` if any jobs has to be processed in the same machine more than once in a row, `false` otherwise.
    """
    machine_repetition() = instance -> any(any(machine1 == machine2 for (machine1, machine2) in zip(x, Iterators.drop(x, 1))) for x in instance.μ)
end