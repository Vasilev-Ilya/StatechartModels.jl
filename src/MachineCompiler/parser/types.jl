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