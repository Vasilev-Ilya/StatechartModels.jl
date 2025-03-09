

for (field_name, type_name) in [(:exit_state_info, :ExitStateInfo), (:initialization_info, :InitializationInfo)]
    function parse_node_to_cst!(
        machine::Machine,
        node::Node,
        $field_name::$type_name,
    )::CST
        
    end
end

function parse_transition_to_cst!(
    machine::Machine,
    transition::Transition,
    exit_state_info::ExitStateInfo,
)::CST
    
end

function parse_transition_to_cst!(
    machine::Machine,
    transition::Transition,
    initialization_info::InitializationInfo,
)::CST
    
end

function parse_state_to_cst!(
    machine::Machine,
    state::State,
    exit_state_info::ExitStateInfo,
)::CST
    
end

function parse_state_to_cst!(
    machine::Machine,
    state::State,
    initialization_info::InitializationInfo,
)::CST
    
end