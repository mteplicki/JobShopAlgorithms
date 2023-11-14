export Cmax_function, Lmax_function, ObjectiveFunction

"""
Enum representing different objective functions for shop scheduling problems.
"""
@enum ObjectiveFunction begin
    Cmax_function
    Lmax_function
end