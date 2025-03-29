
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
    (; machine, history_states_names) = parser_input
    (; tail, entry_state_name, exit_state_name, entry_states_names, exit_states_names) = exit_info
    states = machine.states
    next = tail
    if isempty(entry_states_names)
        next = get_init_state_parse_tree!(parser_input, initialization_info=InitializationInfo(next, entry_state_name, false))
    else
        index_parallel_states = higher_parallel_states(states, entry_states_names)
        if isnothing(index_parallel_states)
            next = get_init_state_parse_tree!(parser_input, initialization_info=InitializationInfo(next, entry_state_name, false))
            next = get_changed_states_entry_actions_parse_tree(next, history_states_names=history_states_names, 
                states=states, changed_parents_names=entry_states_names)
        else
            index, parallel_states = index_parallel_states
            order = states[entry_states_names[index]].order
            for i=length(parallel_states):-1:order+1
                parallel_state = parallel_states[i]
                func_name = "parallel_entry_$(parallel_state.id)$(parallel_state.order)_$(machine.id)!"
                next = FUNCTION_CALL(next, value="$func_name(__machine__)")
            end
            next = get_init_state_parse_tree!(parser_input, initialization_info=InitializationInfo(next, entry_state_name, false))
            reduced_entry_states_names = @view entry_states_names[index:end]
            next = get_changed_states_entry_actions_parse_tree(next, history_states_names=history_states_names, 
                states=states, changed_parents_names=reduced_entry_states_names)
            for i=order-1:-1:1
                parallel_state = parallel_states[i]
                func_name = "parallel_entry_$(parallel_state.id)$(parallel_state.order)_$(machine.id)!"
                next = FUNCTION_CALL(next, value="$func_name(__machine__)")
            end
            reduced_entry_states_names = @view entry_states_names[begin:index-1]
            next = get_changed_states_entry_actions_parse_tree(next, history_states_names=history_states_names, 
                states=states, changed_parents_names=reduced_entry_states_names)
        end
    end
    if !isempty(exit_states_names)
        index_parallel_states = higher_parallel_states(states, exit_states_names)
        if isnothing(index_parallel_states)
            next = get_changed_states_exit_actions_parse_tree(next, history_states_names=history_states_names, 
                states=states, changed_parents_names=exit_states_names)
        else
            index, parallel_states = index_parallel_states
            reduced_exit_states_names = @view exit_states_names[begin:index-1]
            next = get_changed_states_exit_actions_parse_tree(next, history_states_names=history_states_names, 
                states=states, changed_parents_names=reduced_exit_states_names)
            for parallel_state in parallel_states
                func_name = "parallel_exit_$(parallel_state.id)$(parallel_state.order)_$(machine.id)!"
                next = FUNCTION_CALL(next, value="$func_name(__machine__)")
            end
            return next
        end
    end
    next = get_exit_parse_tree(parser_input, state=states[exit_state_name], tail=next)
    return next
end

function get_changed_states_exit_actions_parse_tree(
    tail_cst::ParseTree; 
    history_states_names::Set{StateID}, 
    states::Dict{StateId, State}, 
    changed_parents_names::AbstractArray{StateId},
)::ParseTree
    next = tail_cst
    for state_name in changed_parents_names
        exit_act = get_exit_action(history_states_names, state=states[state_name])
        next = ACTION(next, value=exit_act, type=:exit, id=state_name)
    end
    return next
end

function get_changed_states_entry_actions_parse_tree(
    tail::ParseTree; 
    history_states_names::Set{StateID},
    states::Dict{StateId, State}, 
    changed_parents_names::AbstractArray{StateId},
)::ParseTree
    next = tail
    for state_name in reverse(changed_parents_names)
        entry_act = get_entry_action(history_states_names, state=states[state_name])
        next = ACTION(next, value=entry_act, type=:entry, id=state_name)
    end
    return next
end

function get_exit_parse_tree(parser_input::MachineParserInput; state::State, tail::ParseTree)::ParseTree
    (; machine, history_states_names) = parser_input
    states = machine.states
    substates = get_substates(states, state.id)
    isempty(substates) && return tail
    
    state_leaves = State[]
    get_all_state_leaves!(state_leaves, state, states)
    filter!(x->(isnothing(x.order) || x.order == 1), state_leaves)
    head_next = NODE(Vector{ParseTree}(undef, length(state_leaves)))
    for (i, state_leaf) in enumerate(state_leaves)
        changed_parents_names = StateId[]
        curr_state = state_leaf
        while curr_state.id != state.id
            pushfirst!(changed_parents_names, curr_state.id)
            curr_state = states[curr_state.parent_id]
        end
        index_parallel_states = higher_parallel_states(states, changed_parents_names)
        next = tail
        if isnothing(index_parallel_states)
            next = get_changed_states_exit_actions_parse_tree(next, history_states_names=history_states_names, 
                states=states, changed_parents_names=changed_parents_names)
        else
            index, parallel_states = index_parallel_states
            reduced_exit_states_names = @view changed_parents_names[begin:index-1]
            next = get_changed_states_exit_actions_parse_tree(next, history_states_names=history_states_names, 
                states=states, changed_parents_names=reduced_exit_states_names)
            for parallel_state in parallel_states
                func_name = "parallel_exit_$(parallel_state.id)$(parallel_state.order)_$(machine.id)!"
                next = FUNCTION_CALL(next, value="$func_name(__machine__)")
            end
        end
        state_label = get_state_label(state_leaf.parent_id, prefix="_state")
        condition = isnothing(state_leaf.order) ? "$state_label == \"$(state_leaf.id)\"" : "$state_label == true"
        head_next.to[i] = CONDITION(next, value=condition)
    end
    return head_next
end

function parse_state!(
    parser_input::MachineParserInput,
    state::State,
    initialization_info::InitializationInfo,
)::ParseTree
    (; machine, history_states_names) = parser_input
    states = machine.states
    next = get_init_state_parse_tree!(parser_input, initialization_info=initialization_info)
    curr_state_name = state.id
    parent_name = initialize_info.parent_name
    while curr_state_name != parent_name
        curr_state = states[curr_state_name]
        next = ACTION(next, id=curr_state_name, value=get_entry_action(history_states_names, state=curr_state), type=:entry)
        curr_state_name = curr_state.parent_id
    end
    return next
end

function get_init_state_parse_tree!(
    parser_input::MachineParserInput;
    initialization_info::InitializationInfo,
)::ParseTree
    (; machine, history_states_names) = parser_input
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
            next = FUNCTION_CALL(next, value="$func_name(__machine__)")
        end
    elseif first_entrance || !(parent_name in history_states_names && any(x->x.second.parent_id == parent_name, states))
        next = _get_init_state_parse_tree!(parser_input, initialization_info=initialization_info)
    else
        state = states[parent_name]
        next = FUNCTION_CALL(next, value="history_entry_$(state.id)_$(machine.id)!(__machine__)")
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