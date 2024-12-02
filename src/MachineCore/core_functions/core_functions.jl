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

"""
    change_connection!(machine::Machine, id::Int; s::Union{Nothing, ComponentId}, d::ComponentId)

Reconnect transition `id` to new source `s` and destination `d`.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_states!(machine, [SP("A"), SP("B")]);

julia> add_transition!(machine, TP("A", "B"))
{A, B} transition `1`.

julia> change_connection!(machine, 1, s="B", d="A")
{B, A} transition `1`.
```
"""
function change_connection!(machine::Machine, id::Int; s::Union{Nothing, ComponentId}, d::ComponentId)::Transition
    transitions = machine.transitions
    transition = get_machine_component(transitions, id)
    
    old_s = transition.values.source
    old_d = transition.values.destination
    if old_s != s
        order = transition.values.order
        if isnothing(old_s)
            for (_, tra) in transitions
                (isnothing(tra.values.source) && tra.values.order > order) || continue
                tra.values.order -= 1
            end
            comp_outputs = _get_node_or_state(machine, s).outports
            push!(comp_outputs, id)
            order = length(comp_outputs)
        else
            comp_outputs = _get_node_or_state(machine, old_s).outports
            for tra_id in comp_outputs
                tra = transitions[tra_id]
                tra.values.order > order || continue
                tra.values.order -= 1
            end
            delete!(comp_outputs, id)
            if isnothing(s)
                order = 1
                for (_, tra) in transitions
                    isnothing(tra.values.source) && (order += 1;)
                end
            else
                comp_outputs = _get_node_or_state(machine, s).outports
                push!(comp_outputs, id)
                order = length(comp_outputs)
            end
        end
        transition.values.order = order
        transition.values.source = s
    end

    if old_d != d
        comp_inputs = _get_node_or_state(machine, old_d).inports
        delete!(comp_inputs, id)
        comp_inputs = _get_node_or_state(machine, d).inports
        push!(comp_inputs, id)
        transition.values.destination = d
    end
    return transition
end

include("add.jl")
include("get.jl")
include("remove.jl")
