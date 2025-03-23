#
# Functions for checking
#

function check_state_is_parent(states::Dict{String, State}; parent_name::String, daughter_name::String)::Bool
    curr_state_name = daughter_name
    while !isempty(curr_state_name)
        curr_parent_name = states[curr_state_name].parent_id
        curr_parent_name == parent_name && return true
        curr_state_name = curr_parent_name
    end
    return false
end