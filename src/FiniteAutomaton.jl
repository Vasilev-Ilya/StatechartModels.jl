module FiniteAutomaton

export Machine, 
    State,
    SP,
    Transition, 
    TP, 
    Node,
    NP,
    MachineComponents, 
    StateCollection, 
    NodeCollection, 
    TransitionCollection, 
    MachineCollection,

    # API functions
    add_state!, 
    add_states!,
    add_transition!, 
    add_transitions!, 
    add_node!, 
    add_nodes!, 
    add_component!, 
    add_components!, 
    get_machine_component, 
    get_node,
    get_transition,
    get_state,
    change_connection!,
    rm_state!, 
    rm_states!, 
    rm_node!, 
    rm_nodes!, 
    rm_transition!,
    rm_transitions!

include("MachineAPI/MachineAPI.jl")
using .MachineAPI
include("MachineCompiler/MachineCompiler.jl")
using .MachineCompiler
end # module FiniteAutomaton
