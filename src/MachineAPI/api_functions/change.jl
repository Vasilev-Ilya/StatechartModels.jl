#
# Functions for modifying existing machine components
#

"""
    change_connection!(machine::Machine, id::Int; s::Union{Nothing, ComponentId}, d::ComponentId)

Reconnect transition `id` to new source `s` and destination `d`.

# Examples
```jldoctest
julia> machine = Machine(id="simple_machine");

julia> add_states!(machine, [StateParameters("A"), StateParameters("B")]);

julia> add_transition!(machine, TransitionParameters("A", "B"))
{A, B} transition `1`.

julia> change_connection!(machine, 1, s="B", d="A")
{B, A} transition `1`.
```
"""
function change_connection!(machine::Machine, id::Int; s::Union{Nothing, ComponentId}, d::ComponentId)::Transition
    transitions = machine.transitions
    transition = get_machine_component(transitions, id)
    
    old_s = transition.source
    old_d = transition.destination
    if old_s != s
        order = transition.order
        if isnothing(old_s)
            for (_, tra) in transitions
                (isnothing(tra.source) && tra.order > order) || continue
                tra.order -= 1
            end
            comp_outputs = get_node_or_state(machine, s).outports
            push!(comp_outputs, id)
            order = length(comp_outputs)
        else
            comp_outputs = get_node_or_state(machine, old_s).outports
            for tra_id in comp_outputs
                tra = transitions[tra_id]
                tra.order > order || continue
                tra.order -= 1
            end
            delete!(comp_outputs, id)
            if isnothing(s)
                order = 1
                for (_, tra) in transitions
                    isnothing(tra.source) && (order += 1;)
                end
            else
                comp_outputs = get_node_or_state(machine, s).outports
                push!(comp_outputs, id)
                order = length(comp_outputs)
            end
        end
        transition.order = order
        transition.source = s
    end

    if old_d != d
        comp_inputs = get_node_or_state(machine, old_d).inports
        delete!(comp_inputs, id)
        comp_inputs = get_node_or_state(machine, d).inports
        push!(comp_inputs, id)
        transition.destination = d
    end
    return transition
end
