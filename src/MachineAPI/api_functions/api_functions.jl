#
# Core functions for creating a finite state machine
#

function Base.empty!(machine::Machine; rm_data::Bool=false)
    empty!(machine.states)
    empty!(machine.nodes)
    empty!(machine.transitions)
    rm_data && empty!(machine.data)
    return nothing
end

function Base.delete!(v::Vector, target_elem)
    for (i, elem) in enumerate(v)
        target_elem == elem && (deleteat!(v, i); break;)
    end
    return nothing
end

include("add.jl")
include("get.jl")
include("remove.jl")
include("change.jl")
include("check.jl")
