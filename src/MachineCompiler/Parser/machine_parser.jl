
function parse_node! end

for (field_name, type_name) in [(:exit_state_info, :ExitStateInfo), (:initialization_info, :InitializationInfo)]
    function parse_node!(
        parser_input::MachineParserInput,
        node::Node,
        $field_name::$type_name,
    )::ParseTree
        machine = parser_input.machine
        out_transitions = get_out_transitions(machine, comp=node)
        next = Vector{ParseTree}(undef, length(out_transitions))
        for out_tran in out_transitions
            next[out_tran.values.order] = parse_transition!(machine, out_tran, $field_name)
        end
        return FORK(next, id=node.id, type=:node)
    end
end

function _parse_transition(next::ParseTree; action::String, condition::String, id::Int)::ParseTree
    next = ACTION(next, id=id, type=:transition, value=action)
    if !is_only_spaces(condition)
        next = CONDITION(next, id=id, type=:transition, value=condition)
    end
    return next
end

function parse_transition!(
    parser_input::MachineParserInput,
    transition::Transition,
    exit_state_info::ExitStateInfo,
)::ParseTree
    machine = parser_input.machine
    (; destination, action, condition) = transition.values
    states = machine.states
    comp = get_node_or_state(machine, id=destination)
    if comp isa State
        update_exit_state_info!(exit_state_info, states=states, target_state=comp)
        next = parse_state!(machine, comp, exit_state_info)
    else
        update_exit_state_info!(exit_state_info, states=states, parent_name=comp.parent_id)
        if !isempty(comp.outports)
            next = parse_node!(machine, comp, exit_state_info)
        else
            (; source_name, direction_out, tail) = exit_state_info
            next = parse_substates_scope!(machine, parent_name=source_name, tail=tail)
            next = FORK(next, id=comp.id, type=:node)
            if direction_out
                during_act = states[source_name].actions.during
                next = ACTION(next, value=during_act, type=:during, id=source_name)
            end
        end
    end
    return _parse_transition(next, condition=condition, action=action, id=transition.id)
end

function parse_transition!(
    parser_input::MachineParserInput,
    transition::Transition,
    initialization_info::InitializationInfo,
)::ParseTree
    machine = parser_input.machine
    (; destination, action, condition) = transition.values
    comp = get_node_or_state(machine, id=destination)
    if comp isa State
        next = parse_state!(machine, comp, initialization_info)
    else
        isempty(comp.outports) && error("Each path of the default transition is guaranteed to lead to the state.")
        next = parse_node!(machine, comp, initialization_info)
    end
    return _parse_transition(next, condition=condition, action=action, id=transition.id)
end

function parse_state!(
    parser_input::MachineParserInput,
    state::State,
    exit_state_info::ExitStateInfo,
)::ParseTree
    
end

function parse_state!(
    parser_input::MachineParserInput,
    state::State,
    initialization_info::InitializationInfo,
)::ParseTree
    (; machine, history_states_ids) = parser_input
    states = machine.states
    (; tail, parent_name, first_entrance) = initialize_info
    next = create_cst_for_init_state!(machine, state_id, is_init=is_init, tail=tail)
    curr_state_name = state.id
    while curr_state_name != parent_name
        curr_state = states[curr_state_name]
        next = ACTION(next, id=curr_state_name, value=get_entry_action(history_states_ids, state=curr_state), type=:entry)
        curr_state_name = curr_state.parent_id
    end
    return next
end

function parse_substates_scope!(
    machine::Machine;
    parent_name::String,
    tail::ParseTree,
)::ParseTree
    
end