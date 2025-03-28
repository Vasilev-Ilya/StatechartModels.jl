
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
            next[out_tran.values.order] = parse_transition!(parser_input, out_tran, $field_name)
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
        next = parse_state!(parser_input, comp, exit_state_info)
    else
        update_exit_state_info!(exit_state_info, states=states, parent_name=comp.parent_id)
        if !isempty(comp.outports)
            next = parse_node!(parser_input, comp, exit_state_info)
        elseif comp.history
            target_state = states[comp.parent_id]
            update_exit_state_info!(exit_state_info, states=states, target_state=target_state)
            next = parse_state!(parser_input, target_state, exit_state_info)
            next = FORK(next, id=comp.id, type=:node_history)
        else
            (; source_name, direction_out, tail) = exit_state_info
            next = parse_substates_scope!(parser_input, parent_name=source_name, tail=tail)
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
        next = parse_state!(parser_input, comp, initialization_info)
    else
        isempty(comp.outports) && error("Each path of the default transition is guaranteed to lead to the state.")
        next = parse_node!(parser_input, comp, initialization_info)
    end
    return _parse_transition(next, condition=condition, action=action, id=transition.id)
end

function parse_state!(
    parser_input::MachineParserInput,
    state::State,
    exit_state_info::ExitStateInfo,
)::ParseTree
    machine = parser_input.machine
    states = machine.states
    (; tail, source_names_hierarchy, source_name) = exit_state_info
    target_name = state.id
    target_names_hierarchy = get_state_parent_tree_vector(states, target_name)
    size_source = length(source_names_hierarchy)
    size_target = length(target_names_hierarchy)

    N = min(size_source, size_target)
    j = 0
    for i=1:N
        source_names_hierarchy[i] != target_names_hierarchy[i] && (j = i; break;)
    end

    exit_states_names = entry_states_names = StateId[]
    exit_state_name = source_name
    entry_state_name = target_name
    if j == 0
        (; eldest_parent_index, is_out) = exit_state_info
        if isnothing(eldest_parent_index)
            if size_source > size_target
                entry_state_name = source_name
                exit_states_names = entry_states_names = @view source_names_hierarchy[size_target+1:end]
            elseif size_source < size_target
                exit_state_name = target_name
                exit_states_names = entry_states_names = @view target_names_hierarchy[size_source+1:end]
            elseif is_out
                exit_states_names = @view source_names_hierarchy[end:end]
                entry_states_names = @view target_names_hierarchy[end:end]
            end
        else
            index = eldest_parent_index+1
            exit_states_names = @view source_names_hierarchy[index:end]
            entry_states_names = @view target_names_hierarchy[index:end]
        end     
    else
        exit_states_names = @view source_names_hierarchy[j:end]
        entry_states_names = @view target_names_hierarchy[j:end]
    end

    exit_info = ExitProcessing(tail=tail, entry_state_name=entry_state_name, exit_state_name=exit_state_name, 
        entry_states_names=entry_states_names, exit_states_names=exit_states_names)
    next = _get_state_exit_parse_tree!(parser_input, exit_info=exit_info)
    return next
end

function _get_state_exit_parse_tree!(
    parser_input::MachineParserInput;
    exit_info::ExitProcessing
)::ParseTree
    
end

function parse_state!(
    parser_input::MachineParserInput,
    state::State,
    initialization_info::InitializationInfo,
)::ParseTree
    (; machine, history_states_ids) = parser_input
    states = machine.states
    next = get_init_state_parse_tree!(parser_input, initialization_info=initialization_info)
    curr_state_name = state.id
    parent_name = initialize_info.parent_name
    while curr_state_name != parent_name
        curr_state = states[curr_state_name]
        next = ACTION(next, id=curr_state_name, value=get_entry_action(history_states_ids, state=curr_state), type=:entry)
        curr_state_name = curr_state.parent_id
    end
    return next
end

function get_init_state_parse_tree!(
    parser_input::MachineParserInput;
    initialization_info::InitializationInfo,
)::ParseTree
    (; machine, history_states_ids) = parser_input
    (; tail, parent_name, first_entrance) = initialization_info
    states = machine.states
    substate_name = findfirst(x->x.parent_id == parent_name, states)
    is_parallel = isnothing(substate_name) ? false : !isnothing(states[substate_name].order)
    next = tail
    if is_parallel
        substates = get_substates(states, parent_name)
        sort!(substates, by=s->s.order)
        for i=length(substates):-1:1
            state = substates[i]
            func_name = "parallel_entry_$(state.id)$(state.order)_$(machine.id)!"
            next = FUNCTION_CALL(next, value="$func_name(machine)")
        end
    elseif first_entrance || !(parent_name in history_states_ids && any(x->x.second.parent_id == parent_name, states))
        next = _get_init_state_parse_tree!(parser_input, initialization_info=initialization_info)
    else
        state = states[parent_name]
        next = FUNCTION_CALL(next, value="history_entry_$(state.id)_$(machine.id)!(machine)")
    end
    return next
end

function _get_init_state_parse_tree!(
    parser_input::MachineParserInput;
    initialization_info::InitializationInfo,
)::ParseTree
    machine = parser_input.machine
    (; tail, parent_name, first_entrance) = initialization_info
    in_transitions = get_in_transitions(machine.transitions, parent_name)
    if isempty(in_transitions)
        substates = get_substates(machine.states, parent_name)
        if isempty(substates)
            return tail
        else
            next_initialization_info = InitializationInfo(tail, substates[1].parent_id, first_entrance)
            return parse_state!(parser_input, substates[1].id, next_initialization_info)
        end
    end

    next = NODE(Vector{ParseTree}(undef, length(in_transitions)))
    for in_transition in in_transitions
        next_initialization_info = InitializationInfo(tail, in_transition.parent_id, first_entrance)
        next.to[in_transition.order] = parse_transition!(parser_input, in_transition, next_initialization_info)
    end
    return next
end

function parse_substates_scope!(
    parser_input::MachineParserInput;
    parent_name::String,
    tail::ParseTree,
)::ParseTree
    
end