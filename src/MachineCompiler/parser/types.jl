#
# UTILITY TYPES
#

struct ExitStateInfo
    cst_tail::CST
    source_names_hierarchy::Vector{String}
    source_name::String
    target_name::Union{Nothing, String}
    eldest_parent_index::Union{Nothing, Int}
    direction_out::Bool
end

mutable struct InitializationInfo
    cst_tail::CST
    parent_name::String
    first_entrance::Bool
end

#
# ----- CST TYPES ---
#

abstract type CST end

struct RefMachineCompInfo
    type::Symbol
    id::Union{Int, String}
end

struct CONDITION <: CST
    next::CST
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    value::String
end

struct ACTION <: CST
    next::CST
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    value::String
end

struct FORK <: CST
    next::Vector{CST}
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
end

struct LEAF
    ref_comp_info::Union{Nothing, RefMachineCompInfo}
    final::Bool
    return_values::Bool
end

struct FUNCTION_CALL
    next::CST
    value::String
end

struct MACHINE_FUNCTION
    body::CST
    head::String
end