#
# ----- UTILITY TYPES -----
#

struct MachineParserInput
    machine::Machine
    history_states_names::Set{StateID}
end

Base.@kwdef struct ExitStateInfo
    tail::PARSE_TREE
    source_names_hierarchy::Vector{String}
    source_name::String
    eldest_parent_index::Union{Nothing, Int}=nothing
    direction_out::Bool
end

mutable struct InitializationInfo
    tail::PARSE_TREE
    parent_name::String
    first_entrance::Bool
end

struct ExitProcessing
    tail::PARSE_TREE
    entry_states_names::AbstractArray{StateId}
    exit_states_names::AbstractArray{StateId}
    entry_state_name::StateId
    exit_state_name::StateId

    function ExitProcessing(; 
        tail::PARSE_TREE,
        entry_state_name::StateId,
        exit_state_name::StateId,
        entry_states_names::AbstractArray{StateId},
        exit_states_names::AbstractArray{StateId},
    )
        return new(tail, entry_states_names, exit_states_names, entry_state_name, exit_state_name)
    end
end

#
# ----- PARSE_TREE TYPES -----
#

abstract type PARSE_TREE end

struct RefMachineCompInfo
    type::Symbol
    id::Union{Int, String}
end

struct CONDITION <: PARSE_TREE
    next::PARSE_TREE
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    value::String

    CONDITION(next::PARSE_TREE; value::String="") = new(next, nothing, value)
    CONDITION(next::PARSE_TREE; id::Union{Int, String}, type::Symbol, value::String="") = new(next, RefMachineCompInfo(type, id), value)
end

struct ACTION <: PARSE_TREE
    next::PARSE_TREE
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    value::String

    ACTION(next::PARSE_TREE; value::String="") = new(next, nothing, value)
    ACTION(next::PARSE_TREE; id::Union{Int, String}, type::Symbol, value::String="") = new(next, RefMachineCompInfo(type, id), value)
end

struct FORK <: PARSE_TREE
    next::Vector{PARSE_TREE}
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    
    FORK(next::Vector{PARSE_TREE}) = new(next, nothing)
    FORK(next::Vector{PARSE_TREE}; id::Union{Int, String}, type::Symbol) = new(next, RefMachineCompInfo(type, id))
    FORK(next::PARSE_TREE) = new(PARSE_TREE[next], nothing)
    FORK(next::PARSE_TREE; id::Union{Int, String}, type::Symbol) = new(PARSE_TREE[next], RefMachineCompInfo(type, id))
end

struct LEAF
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    out_values::Union{Nothing, Vector{String}}

    LEAF(; out_values::Union{Nothing, Vector{String}}=nothing) = new(nothing, out_values)
    LEAF(; id::Union{Int, String}, type::Symbol, out_values::Union{Nothing, Vector{String}}=nothing) = new(RefMachineCompInfo(type, id), out_values)
end

struct FUNCTION_CALL
    next::PARSE_TREE
    value::String

    FUNCTION_CALL(next::PARSE_TREE; value::String) = new(next, value)
end

struct MACHINE_FUNCTION
    body::PARSE_TREE
    head::String
end