#
# ----- UTILITY TYPES -----
#

struct MachineParserInput
    machine::Machine
    history_states_ids::Set{StateID}
end

struct ExitStateInfo
    tail::ParseTree
    source_names_hierarchy::Vector{String}
    source_name::String
    eldest_parent_index::Union{Nothing, Int}
    direction_out::Bool
end

mutable struct InitializationInfo
    tail::ParseTree
    parent_name::String
    first_entrance::Bool
end

struct ExitProcessing
    tail::ParseTree
    entry_states_names::AbstractArray{StateId}
    exit_states_names::AbstractArray{StateId}
    entry_state_name::StateId
    exit_state_name::StateId

    function ExitProcessing(; 
        tail::ParseTree,
        entry_state_name::StateId,
        exit_state_name::StateId,
        entry_states_names::AbstractArray{StateId},
        exit_states_names::AbstractArray{StateId},
    )
        return new(tail, entry_states_names, exit_states_names, entry_state_name, exit_state_name)
    end
end

#
# ----- ParseTree TYPES -----
#

abstract type ParseTree end

struct RefMachineCompInfo
    type::Symbol
    id::Union{Int, String}
end

struct CONDITION <: ParseTree
    next::ParseTree
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    value::String

    CONDITION(next::ParseTree; value::String="") = new(next, nothing, value)
    CONDITION(next::ParseTree; id::Union{Int, String}, type::Symbol, value::String="") = new(next, RefMachineCompInfo(type, id), value)
end

struct ACTION <: ParseTree
    next::ParseTree
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    value::String

    ACTION(next::ParseTree; value::String="") = new(next, nothing, value)
    ACTION(next::ParseTree; id::Union{Int, String}, type::Symbol, value::String="") = new(next, RefMachineCompInfo(type, id), value)
end

struct FORK <: ParseTree
    next::Vector{ParseTree}
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    
    FORK(next::Vector{ParseTree}) = new(next, nothing)
    FORK(next::Vector{ParseTree}; id::Union{Int, String}, type::Symbol) = new(next, RefMachineCompInfo(type, id))
    FORK(next::ParseTree) = new(ParseTree[next], nothing)
    FORK(next::ParseTree; id::Union{Int, String}, type::Symbol) = new(ParseTree[next], RefMachineCompInfo(type, id))
end

struct LEAF
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    out_values::Union{Nothing, Vector{String}}

    LEAF(; out_values::Union{Nothing, Vector{String}}=nothing) = new(nothing, out_values)
    LEAF(; id::Union{Int, String}, type::Symbol, out_values::Union{Nothing, Vector{String}}=nothing) = new(RefMachineCompInfo(type, id), out_values)
end

struct FUNCTION_CALL
    next::ParseTree
    value::String

    FUNCTION_CALL(next::ParseTree; value::String) = new(next, value)
end

struct MACHINE_FUNCTION
    body::ParseTree
    head::String
end