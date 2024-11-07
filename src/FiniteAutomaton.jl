module FiniteAutomaton

export Machine,

    # core functions
    state!, 
    transition!, 
    node!, 
    get_node,
    get_transition,
    get_state

include("MachineCore/MachineCore.jl")
using .MachineCore
end # module FiniteAutomaton
