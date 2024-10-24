module FiniteAutomaton

export Machine,

    # core functions
    state!, 
    transition!, 
    node!, 
    get_node

include("MachineCore/MachineCore.jl")
using .MachineCore
end # module FiniteAutomaton
