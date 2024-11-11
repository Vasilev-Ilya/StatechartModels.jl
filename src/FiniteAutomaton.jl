module FiniteAutomaton

export Machine, 
    State, 
    Transition, 
    TransitionValues, 
    Node,

    # core functions
    add_state!, 
    add_transition!, 
    add_node!, 
    add_component!, 
    get_node,
    get_transition,
    get_state

include("MachineCore/MachineCore.jl")
using .MachineCore
end # module FiniteAutomaton
