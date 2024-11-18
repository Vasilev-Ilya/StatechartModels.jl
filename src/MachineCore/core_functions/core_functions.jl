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

include("add.jl")
include("get.jl")
