module StatechartModels

export Machine, 
    State,
    StateParameters,
    Transition, 
    TransitionParameters, 
    Node,
    NodeParameters,
    MachineComponents, 
    MachineComponentsDicts,
    Data,

    # API functions
    add_state!, 
    add_states!,
    add_transition!, 
    add_transitions!, 
    add_node!, 
    add_nodes!, 
    add_component!, 
    add_components!, 
    add_data!,
    get_machine_component, 
    get_node,
    get_transition,
    get_state,
    get_state_parent_tree_vector,
    get_in_transitions,
    change_connection!,
    rm_state!, 
    rm_states!, 
    rm_node!, 
    rm_nodes!, 
    rm_transition!,
    rm_transitions!,
    rm_data!,

    # Parser
    PARSE_TREE,
    ParsedMachine,
    parse_machine

include("MachineAPI/MachineAPI.jl")
using .MachineAPI
include("MachineCompiler/MachineCompiler.jl")
using .MachineCompiler
end # module StatechartModels
