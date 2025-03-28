
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

function get_entry_action(history_states_ids::Set{StateID}; state::State)::String
    parent_name = state.parent_id
    state_label = get_state_label(parent_name, prefix="_state")
    isnothing(state.order) || return "$state_label = true\n$(state.entry)\n"
    action = "$state_label = \"$(state.id)\"\n"
    if parent_name in history_states_ids
        is_active_label = get_state_label(parent_name, prefix="_is_active")
        action *= "$is_active_label = true\n"
    end
    return "$action$(state.entry)\n"
end
