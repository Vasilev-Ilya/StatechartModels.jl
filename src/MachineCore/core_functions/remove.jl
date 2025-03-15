#
# Functions for removing components from the machine
#

"""
    rm_state!(machine::Machine, id::String)

Removing state with name `id` from machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_state!(machine, SP("A")); machine
{states: 1, transitions: 0, nodes: 0} machine `simple_machine`.

julia> rm_state!(machine, "A")
true

julia> machine
{states: 0, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function rm_state!(machine::Machine, id::String)::Bool
    states = machine.states
    haskey(states, id) || return false
    state = states[id]
    transitions = machine.transitions
    for tra_id in state.inports
        transitions[tra_id].values.destination = nothing
    end
    for tra_id in state.outports
        transition = transitions[tra_id]
        transition.values.order = 1
        for (_, tra) in transitions
            isnothing(tra.values.source) && (transition.values.order += 1;)
        end
        transition.values.source = nothing
    end
    isempty(state.parent_id) || delete!(states[state.parent_id].substates, id)
    delete!(states, id)
    return true
end

"""
    rm_node!(machine::Machine, id::Int)

Removing node with id `id` from machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_node!(machine, 1); machine
{states: 0, transitions: 0, nodes: 1} machine `simple_machine`.

julia> rm_node!(machine, 1)
true

julia> machine
{states: 0, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function rm_node!(machine::Machine, id::Int)::Bool
    nodes = machine.nodes
    haskey(nodes, id) || return false
    node = nodes[id]
    transitions = machine.transitions
    for tra_id in node.inports
        transitions[tra_id].values.destination = nothing
    end
    for tra_id in node.outports
        transition = transitions[tra_id]
        transition.values.order = 1
        for (_, tra) in transitions
            isnothing(tra.values.source) && (transition.values.order += 1;)
        end
        transition.values.source = nothing
    end
    delete!(nodes, id)
    return true
end

"""
    rm_transition!(machine::Machine, id::Int)

Removing transition with id `id` from machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_states!(machine, [SP("A"), SP("B")]);

julia> add_transition!(machine, TP("A", "B")); machine
{states: 2, transitions: 1, nodes: 0} machine `simple_machine`.

julia> rm_transition!(machine, 1)
true

julia> machine
{states: 2, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function rm_transition!(machine::Machine, id::Int)::Bool
    transitions = machine.transitions
    haskey(transitions, id) || return false
    tra = transitions[id]
    s = tra.values.source
    if !isnothing(s)
        comp_ports = get_node_or_state(machine, s).outports
        for tra_id in comp_ports
            comp_tra = transitions[tra_id]
            comp_tra.values.order > tra.values.order || continue
            comp_tra.values.order -= 1
        end
        delete!(comp_ports, id)
    end

    d = tra.values.destination
    if !isnothing(d)
        comp_ports = get_node_or_state(machine, d).inports
        delete!(comp_ports, id)
    end

    delete!(transitions, id)
    return true
end

"""
    rm_states!(machine::Machine, ids::Vector{String})

Remove states from the machine specified in the list `ids`.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_states!(machine, [SP("A"), SP("A")]); machine
{states: 2, transitions: 0, nodes: 0} machine `simple_machine`.

julia> rm_states!(machine, ["A", "B"])

julia> machine
{states: 0, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function rm_states! end

"""
    rm_nodes!(machine::Machine, ids::Vector{Int})

Remove nodes from the machine specified in the list `ids`.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_nodes!(machine, N=2); machine
{states: 0, transitions: 0, nodes: 2} machine `simple_machine`.

julia> rm_nodes!(machine, [1, 2])

julia> machine
{states: 0, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function rm_nodes! end

"""
    rm_transitions!(machine::Machine, ids::Vector{Int})

Remove transitions from the machine specified in the list `ids`.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_states!(machine, [SP("A"), SP("A")]);

julia> add_transitions(machine, [TP("A", "B"), TP("B", "A")]); machine
{states: 2, transitions: 2, nodes: 0} machine `simple_machine`.

julia> rm_transitions!(machine, [1, 2])

julia> machine
{states: 2, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function rm_transitions! end

for (fname, method_name, arg_type) in [(:rm_states!, :rm_state!, :String), (:rm_nodes!, :rm_node!, :Int), (:rm_transitions!, :rm_transition!, :Int)]
    @eval begin
        function $fname(machine::Machine, ids::Vector{$arg_type})
            for id in ids
                $method_name(machine, id)
            end
            return nothing
        end
    end
end