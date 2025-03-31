
is_only_spaces(str::String) = isempty(strip(str))

function update_exit_state_info!(exit_state_info::ExitStateInfo; states::Dict{String, State}, parent_name::String)
    eldest_parent_index = exit_state_info.eldest_parent_index
    if eldest_parent_index != 0
        (; source_names_hierarchy, source_name) = exit_state_info
        parent_index = findfirst(==(parent_name), source_names_hierarchy)
        if isnothing(parent_index)
            check_state_is_parent(states, parent_name=source_name, daughter_name=parent_name) ||
                (exit_state_info.eldest_parent_index = 0;)
        elseif isnothing(eldest_parent_index) || eldest_parent_index > parent_index
            exit_state_info.eldest_parent_index = parent_index
        end
    end
    return nothing
end

function update_exit_state_info!(exit_state_info::ExitStateInfo; states::Dict{String, State}, target_state::State)
    target_name = target_state.id
    source_name = exit_state_info.source_name
    eldest_parent_index = exit_state_info.eldest_parent_index
    index_valid = !isnothing(eldest_parent_index) && eldest_parent_index != 0
    if index_valid && check_state_is_parent(states, parent_name=target_name, daughter_name=source_name)
        daughter_name = exit_state_info.source_names_hierarchy[eldest_parent_index]
        is_parent = check_state_is_parent(states, parent_name=target_name, daughter_name=daughter_name)
        (is_parent || target_name == daughter_name) && (exit_state_info.eldest_parent_index = nothing;)
    end
    return nothing
end

get_state_label(parent_name::StateId; prefix::String) = "$prefix$parent_name"

function get_entry_action(history_states_names::Set{StateID}; state::State)::String
    parent_name = state.parent_id
    state_label = get_state_label(parent_name, prefix="_state")
    isnothing(state.order) || return "$state_label = true\n$(state.entry)\n"
    action = "$state_label = \"$(state.id)\"\n"
    if parent_name in history_states_names
        is_active_label = get_state_label(parent_name, prefix="_is_active")
        action *= "$is_active_label = true\n"
    end
    return "$action$(state.entry)\n"
end

function get_exit_action(history_states_names::Set{StateID}; state::State)::String
    parent_name = state.parent_id
    counter_label = get_state_label(parent_name, prefix="_counter")
    exit_act = "$(state.exit)\n$counter_label = 0\n"
    if parent_name in history_states_names
        state_label = get_state_label(parent_name, prefix="_is_active")
        exit_act *= "$state_label = false\n"
    else
        state_label = get_state_label(parent_name, prefix="_state")
        reset_label = isnothing(state.order) ? "$state_label = \"\"" : "$state_label = false"
        exit_act *= "$reset_label\n"
    end
    return exit_act
end

function higher_parallel_states(states::Dict{StateId, State}, states_names::AbstractArray{StateId})::Union{Nothing, Tuple{Int, Vector{State}}}
    for (i, state_name) in enumerate(states_names)
        state = states[state_name]
        if !isnothing(state.order)
            parallel_states = get_substates(states, state.parent_id)
            sort!(parallel_states, by=s->s.order)
            return i, parallel_states
        end
    end
    return nothing
end

function get_all_state_leaves!(state_leaves::Vector{State}, state::State, states::Dict{StateId, State})
    if !isempty(get_substates(states, state))
        _get_all_state_leaves!(state_leaves, state, states)
    end
    return nothing
end

function _get_all_state_leaves!(state_leaves::Vector{State}, state::State, states::Dict{StateId, State})
    substates = get_substates(states, states[state.id])
    if isempty(substates)
        push!(state_leaves, state)
    else
        for substate in substates
            _get_all_state_leaves!(state_leaves, substate, states)
        end
    end
    return nothing
end

function get_special_data(states::Dict{StateId, State}, history_states_names::Set{StateID})::Vector{Data}
    data = Data[]
    states_with_unique_parents = unique(s->s.parent_id, values(states))
    for state in states_with_unique_parents
        state_name = state.parent_id
        if isnothing(state.order)
            if parent_id in history_states_names
                push!(data, Data(name="_is_active$state_name", scope=3, type="Bool", value="false"))
            end
            push!(data, Data("_state$state_name", scope=3, type="String", value="\"\""))
        else
            push!(data, Data("_state$state_name", scope=3, type="Bool", value="false"))
        end
        push!(data, Data("_counter$state_name", scope=3, type="Int", value="0"))
    end
    return data
end
