
function parse_node! end

for (field_name, type_name) in [(:exit_state_info, :ExitStateInfo), (:initialization_info, :InitializationInfo)]
    @eval begin
        function parse_node!(
            parser_input::MachineParserInput,
            node::Node,
            $field_name::$type_name,
        )::PARSE_TREE
            machine = parser_input.machine
            out_transitions = get_out_transitions(machine, comp=node)
            next = Vector{PARSE_TREE}(undef, length(out_transitions))
            for out_tran in out_transitions
                next[out_tran.order] = parse_transition!(parser_input, out_tran, $field_name)
            end
            return FORK(next, node.id, :node)
        end
    end
end

function _parse_transition(next::PARSE_TREE; action::String, condition::String, id::Int)::PARSE_TREE
    next = ACTION(next, id, :transition, action)
    if !is_only_spaces(condition)
        next = CONDITION(next, id, :transition, condition)
    end
    return next
end

function parse_transition!(
    parser_input::MachineParserInput,
    transition::Transition,
    exit_state_info::ExitStateInfo,
)::PARSE_TREE
    machine = parser_input.machine
    (; destination, action, condition) = transition
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
            next = FORK(next, comp.id, :node_history)
        else
            (; source_name, direction_out, tail) = exit_state_info
            next = parse_substates_scope!(parser_input, parent_name=source_name, tail=tail)
            next = FORK(next, comp.id, :node)
            if direction_out
                during_act = states[source_name].actions.during
                next = ACTION(next, source_name, :during, during_act)
            end
        end
    end
    return _parse_transition(next, condition=condition, action=action, id=transition.id)
end

function parse_transition!(
    parser_input::MachineParserInput,
    transition::Transition,
    initialization_info::InitializationInfo,
)::PARSE_TREE
    machine = parser_input.machine
    (; destination, action, condition) = transition
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
)::PARSE_TREE
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

    exit_states_names = entry_states_names = StateID[]
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
)::PARSE_TREE
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
    tail_cst::PARSE_TREE; 
    history_states_names::Set{StateID}, 
    states::Dict{StateID, State}, 
    changed_parents_names::AbstractArray{StateID},
)::PARSE_TREE
    next = tail_cst
    for state_name in changed_parents_names
        exit_act = get_exit_action(history_states_names, state=states[state_name])
        next = ACTION(next, state_name, :exit, exit_act)
    end
    return next
end

function get_changed_states_entry_actions_parse_tree(
    tail::PARSE_TREE; 
    history_states_names::Set{StateID},
    states::Dict{StateID, State}, 
    changed_parents_names::AbstractArray{StateID},
)::PARSE_TREE
    next = tail
    for state_name in reverse(changed_parents_names)
        entry_act = get_entry_action(history_states_names, state=states[state_name])
        next = ACTION(next, state_name, :entry, entry_act)
    end
    return next
end

function get_exit_parse_tree(parser_input::MachineParserInput; state::State, tail::PARSE_TREE)::PARSE_TREE
    (; machine, history_states_names) = parser_input
    states = machine.states
    substates = get_substates(states, state.id)
    isempty(substates) && return tail
    
    state_leaves = State[]
    get_all_state_leaves!(state_leaves, state, states)
    filter!(x->(isnothing(x.order) || x.order == 1), state_leaves)
    head_next = FORK(Vector{PARSE_TREE}(undef, length(state_leaves)))
    for (i, state_leaf) in enumerate(state_leaves)
        changed_parents_names = StateID[]
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
        head_next.next[i] = CONDITION(next, condition)
    end
    return head_next
end

function parse_state!(
    parser_input::MachineParserInput,
    state::State,
    initialization_info::InitializationInfo,
)::PARSE_TREE
    (; machine, history_states_names) = parser_input
    (; tail, first_entrance, parent_name) = initialization_info
    states = machine.states
    next = get_init_state_parse_tree!(parser_input, initialization_info=InitializationInfo(tail, state.id, first_entrance))
    curr_state_name = state.id
    while curr_state_name != parent_name
        curr_state = states[curr_state_name]
        next = ACTION(next, curr_state_name, :entry, get_entry_action(history_states_names, state=curr_state))
        curr_state_name = curr_state.parent_id
    end
    return next
end

function get_init_state_parse_tree!(
    parser_input::MachineParserInput;
    initialization_info::InitializationInfo,
)::PARSE_TREE
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
)::PARSE_TREE
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

    next = FORK(Vector{PARSE_TREE}(undef, length(in_transitions)))
    for in_transition in in_transitions
        next_initialization_info = InitializationInfo(tail, in_transition.parent_id, first_entrance)
        next.next[in_transition.order] = parse_transition!(parser_input, in_transition, next_initialization_info)
    end
    return next
end

function get_state_during_parse_tree(parser_input::MachineParserInput; state::State, tail::PARSE_TREE)::PARSE_TREE
    machine = parser_input.machine
    state_out_transitions = get_out_transitions(machine, comp=state)
    first_in_indx = findfirst(x->!(x.direction_out), state_out_transitions)
    state_name = state.id
    next = parse_substates_scope!(parser_input, parent_name=state_name, tail=tail)
    n_out_trans = length(state_out_transitions)
    if !isnothing(first_in_indx)
        n_out_trans = first_in_indx - 1
        out_transitions = @view(state_out_transitions[first_in_indx:end])
        n_trees = length(out_transitions) + 1
        fork = FORK(Vector{PARSE_TREE}(undef, n_trees))
        fork.next[n_trees] = next
        if !isempty(out_transitions)
            get_state_out_parse_tree!(parser_input, fork, state_name, out_transitions=out_transitions, 
                tail=tail, direction_out=false, order_offset=-n_out_trans)
        end
        next = fork
    end

    n_trees = 1 + n_out_trans
    fork = FORK(Vector{PARSE_TREE}(undef, n_trees))
    fork.next[n_trees] = ACTION(next, state_name, :during, state.during)
    out_transitions = @view(state_out_transitions[begin:n_out_trans])
    if !isempty(out_transitions)
        get_state_out_parse_tree!(parser_input, fork, state_name, out_transitions=out_transitions, 
            tail=tail, direction_out=true)
    end
    return fork
end

function get_state_out_parse_tree!(
    parser_input::MachineParserInput,
    fork::FORK, 
    state_name::StateID; 
    out_transitions::SubArray{Transition}, 
    tail::PARSE_TREE,
    direction_out::Bool,
    order_offset::Int=0,
)
    parents_names = get_state_parent_tree_vector(parser_input.machine.states, state_name)
    for out_transition in out_transitions
        exit_info = ExitStateInfo(tail=tail, source_names_hierarchy=parents_names, source_name=state_name, 
            direction_out=direction_out)
        order = out_transition.order + order_offset
        fork.next[order] = parse_transition!(parser_input, out_transition, exit_info)
    end
    return nothing
end

function parse_substates_scope!(parser_input::MachineParserInput; parent_name::StateID, tail::PARSE_TREE)::PARSE_TREE
    machine = parser_input.machine
    states = machine.states
    substates = get_substates(states, parent_name)
    (isempty(substates) && !isempty(parent_name)) && return tail
    init_state_parse_tree = get_init_state_parse_tree!(parser_input, initialization_info=InitializationInfo(tail, parent_name, true))
    isempty(substates) && return init_state_parse_tree
    is_exclusive = isnothing(substates[1].order)
    state_label = get_state_label(parent_name, prefix="_state")
    if is_exclusive
        next = FORK(Vector{PARSE_TREE}(undef, length(substates)+1))
        next.next[1] = CONDITION(init_state_parse_tree, "isempty($state_label)")
        for (i, substate) in enumerate(substates)
            next.next[i+1] = CONDITION(
                    get_state_during_parse_tree(parser_input, state=substate, tail=tail), 
                    "$state_label == \"$(substate.id)\"",
                )
        end
    else
        next = FORK(Vector{PARSE_TREE}(undef, 2))
        next.next[1] = CONDITION(
                ACTION(init_state_parse_tree, "$state_label = true"),
                "$state_label == false"
            )
        sort!(substates, by=s->s.order)
        next_subtree = tail
        for i=length(substates):-1:1
            substate = substates[i]
            func_name = "parallel_during_$(substate.id)$(substate.order)_$(machine.id)!"
            next_subtree = FUNCTION_CALL(next_subtree, value="$func_name(__machine__)")
        end
        next.next[2] = next_subtree
    end
    return next
end

function add_history_entry_function!(machine_funcs::Vector{PARSE_TREE}, parser_input::MachineParserInput, state::State)
    states = machine_funcs.machine.states
    state_name = state.id
    substates = get_substates(states, state_name)
    if !isempty(substates)
        n_indexs = length(substates) + 1
        next = FORK(Vector{PARSE_TREE}(undef, n_indexs))
        state_label = get_state_label(state_name, prefix="_state")
        fork = _get_init_state_parse_tree(parser_input, initialization_info=InitializationInfo(LEAF(), state_name, false))
        next.next[1] = CONDITION(fork, "isempty($state_label)")
        for i=2:n_indexs
            substate = substates[i-1]
            initialization_info = InitializationInfo(LEAF(), substate.id, false)
            next_tree = get_init_state_parse_tree!(parser_input, initialization_info=initialization_info)
            entry_act = get_entry_action(parser_input.history_states_names, substate)
            next_tree = ACTION(next_tree, substate.id, :entry, entry_act)
            next.next[i] = CONDITION(next_tree, "$state_label == \"$(substate.id)\"")
        end
        next = FORK(PARSE_TREE[next, LEAF()])
        push!(
                machine_funcs, 
                MACHINE_FUNCTION(next, head=String["history_entry_$(state.id)_$(machine.id)!"]),
            )
    end
    return nothing
end

function add_parallel_states_functions!(machine_funcs::Vector{PARSE_TREE}, parent_name::StateID, parser_input::MachineParserInput)
    states = parser_input.machine.states
    parallel_states = get_substates(states, parent_name)
    for state in parallel_states
        add_parallel_state_exit_function!(machine_funcs, parser_input, state)
        add_parallel_state_entry_function!(machine_funcs, parser_input, state)
        add_parallel_state_during_function!(machine_funcs, parser_input, state)
    end
    return nothing
end

function add_parallel_state_exit_function!(machine_funcs::Vector{PARSE_TREE}, parser_input::MachineParserInput, state::State)
    exit_act = get_exit_action(parser_input.history_states_names, state=state)
    next = ACTION(LEAF(), state.id, :exit, exit_act)
    next = get_exit_parse_tree(parser_input, state=state, tail=next)
    next = FORK(PARSE_TREE[next, LEAF()])
    func_name = "parallel_exit_$(state.id)$(state.order)_$(parser_input.machine.id)!"
    push!(machine_funcs, MACHINE_FUNCTION(next, head=String[func_name]))
    return nothing
end

function add_parallel_state_entry_function!(machine_funcs::Vector{PARSE_TREE}, parser_input::MachineParserInput, state::State)
    initialization_info = InitializationInfo(LEAF(), state.id, false)
    next = get_init_state_parse_tree!(parser_input, initialization_info=initialization_info)
    entry_act = get_entry_action(parser_input.history_states_names, state)
    next = ACTION(next, state.id, :entry, entry_act)
    next = FORK(PARSE_TREE[next, LEAF()])
    func_name = "parallel_entry_$(state.id)$(state.order)_$(parser_input.machine.id)!"
    push!(machine_funcs, MACHINE_FUNCTION(next, head=String[func_name]))
    return nothing
end

function add_parallel_state_during_function!(machine_funcs::Vector{PARSE_TREE}, parser_input::MachineParserInput, state::State)
    next = get_state_during_parse_tree!(is_terminal, state=state, tail=LEAF())
    next = FORK(PARSE_TREE[next, LEAF()])
    func_name = "parallel_during_$(state.id)$(state.order)_$(parser_input.machine.id)!"
    push!(machine_funcs, MACHINE_FUNCTION(next, head=String[func_name]))
    return nothing
end

function get_all_machine_functions(parser_input::MachineParserInput)::Vector{PARSE_TREE}
    machine_funcs = PARSE_TREE[]
    for (_, state) in parser_input.machine.states
        state.id in parser_input.history_states_names && 
            add_history_entry_function!(machine_funcs, state, chart, cycle_infos)
        state.order == 1 && 
            add_parallel_states_functions!(machine_funcs, state.parent_id, chart, cycle_infos)
    end
    return machine_funcs
end

function parse_machine(machine::Machine)::ParsedMachine
    history_states_names = Set([node.parent_id for (_, node) in machine.nodes if node.history])
    parser_input = MachineParserInput(machine, history_states_names)
    machine_functions = get_all_machine_functions(parser_input)
    data = machine.data
    tail = LEAF(String[var.name for var in machine.data if var.scope == 2])
    main_function = parse_substates_scope!(parser_input, parent_name="", tail=tail)
    special_data = get_special_data(machine.states, history_states_names)
    return ParsedMachine(
            id=machine.id,
            main_function=main_function,
            machine_functions=machine_functions,
            data=Data[data..., special_data...]
        )
end