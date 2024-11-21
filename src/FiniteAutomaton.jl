module FiniteAutomaton

export Machine, 
    State,
    SP,
    Transition, 
    TP, 
    Node,
    MachineComponents, 
    StateCollection, 
    NodeCollection, 
    TransitionCollection, 
    MachineCollection,

    # core functions
    add_state!, 
    add_states!,
    add_transition!, 
    add_transitions!, 
    add_node!, 
    add_nodes!, 
    add_component!, 
    add_components!, 
    get_node,
    get_transition,
    get_state,
    change_connection!

include("MachineCore/MachineCore.jl")
using .MachineCore
end # module FiniteAutomaton
