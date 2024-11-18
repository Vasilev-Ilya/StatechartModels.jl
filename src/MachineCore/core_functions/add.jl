#
# Functions for adding components to the machine
#

"""
    add_state!(machine::Machine, name::String; en::String="", du::String="", ex::String="")

Add state with name `name` to the machine.   

Additionally, you can assign the state-actions: entry (`en`), during (`du`) and exit (`ex`).

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_state!(machine, "A")
{0, 0} state `A`.

julia> machine
{states: 1, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function add_state!(machine::Machine, p::SP)::State
    states = machine.states
    name = p.id
    isempty(name) && error("State name must not be empty.") 
    haskey(states, name) && throw_duplicated_id(name)
    state = State(Int[], Int[], p)
    states[name] = state
    return state
end

"""
    add_states!(machine::Machine, states::Vector{SP})

Adds multiple states to the machine.   

The states to be added are stored in a vector. Each element of the vector is a `SP` struct.   

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_states!(machine, [SP("A", en="x=0"), SP("B", du="x=1"), SP("C", ex="x=3")])

julia> machine
{states: 3, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function add_states!(machine::Machine, parameters::Vector{SP})
    isempty(parameters) && return nothing
    machine_states = machine.states
    sizehint!(machine_states, length(machine_states) + length(parameters))
    for p in parameters
        add_state!(machine, p)
    end
    return nothing
end

"""
    add_node!(machine::Machine)

Add node to the machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_node!(machine)
{0, 0} node `1`.

julia> machine
{states: 0, transitions: 0, nodes: 1} machine `simple_machine`.
```
"""
function add_node!(machine::Machine)::Node
    nodes = machine.nodes
    id = length(nodes) + 1
    node = Node(id, Int[], Int[])
    nodes[id] = node
    return node
end

"""
    add_nodes!(machine::Machine, N::Int)

Adds multiple nodes to the machine. 

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_nodes!(machine, N=4)

julia> machine
{states: 0, transitions: 0, nodes: 4} machine `simple_machine`.
```
"""
function add_nodes!(machine::Machine; N::Int)
    N < 1 && return nothing
    machine_nodes = machine.nodes
    sizehint!(machine_nodes, length(machine_nodes) + N)
    for _=1:N
        add_node!(machine)
    end
    return nothing
end

"""
    add_transition!(machine::Machine, p::TP)

Add transition to the machine.   

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_state!(machine, "A"); add_state!(machine, "B");

julia> add_node!(machine); add_node!(machine);

julia> add_transition!(machine, TP("A", "B")) # transition between state `A` and state `B`
{A, B} transition `1`.

julia> add_transition!(machine, TP("A", 1, cond="x == 0")) # transition between state `A` and node `1` with condition `x == 0`
{A, 1} transition `2`.

julia> add_transition!(machine, TP(2, "B", act="x = 0")) # transition between node `2` and state `B` with action `x = 0`
{2, B} transition `3`.

julia> add_transition!(machine, TP("A")) # input transition to state `A`
{nothing, A} transition `4`.
```
"""
function add_transition!(machine::Machine, p::TP)::Transition
    transitions = machine.transitions
    id = length(transitions) + 1
    s, d = p.source, p.destination
    if isnothing(s)
        if iszero(p.order)
            p.order = 1
            for (_, tra) in transitions
                isnothing(tra.values.source) && (p.order += 1;)
            end
        end
    else
        comp = _get_node_or_state(machine, s)
        push!(comp.outports, id)
        iszero(p.order) && (p.order = length(comp.outports);)
    end
    comp = _get_node_or_state(machine, d)
    push!(comp.inports, id)

    transition = Transition(id, p)
    transitions[id] = transition
    return transition
end

"""
    add_transitions!(machine::Machine, transitions::Vector{TP})

Adds multiple transitions to the machine.   

The transitions to be added are stored in a vector. Each element of the vector is a `TP` struct.   

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_state!(machine, "A"); add_node!(machine);

julia add_transitions!(machine, [TP("A", act="x=0"), TP("A", 1, cond="x==0")])

julia> machine
{states: 1, transitions: 2, nodes: 1} machine `simple_machine`.
```
"""
function add_transitions!(machine::Machine, parameters::Vector{TP})
    isempty(parameters) && return nothing
    machine_trans = machine.transitions
    sizehint!(machine_trans, length(machine_trans) + length(parameters))
    for p in parameters
        add_transition!(machine, p)
    end
    return nothing
end

"""
    add_component!(machine::Machine, component::[State | Node | Transition])

Explicitly add a component to the machine.   

**_NOTE:_** With this method, the added component will not be connected automatically. Connections must be added manually.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_component!(machine, State([1], [2], SP("A", du="x += 1")))
{1, 1} state `A`.

julia> add_component!(machine, Node(1, [2], []))
{1, 0} node `1`.

julia> add_transition!(machine, Transition(1, TP(nothing, "A", order=1, act="x=0"))) # input transition to state `A`
{nothing, A} transition `1`.

julia> add_transition!(machine, Transition(2, TP("A", 1, order=1))) # transition between state `A` and node `1`
{A, 1} transition `2`.
```
"""
function add_component! end

for (field_name, comp_type) in ((:states, :State), (:nodes, :Node), (:transitions, :Transition))
    @eval begin
        function add_component!(machine::Machine, component::$comp_type)::$comp_type
            components = machine.$field_name
            id = component.id
            haskey(components, id) && throw_duplicated_id(id)
            components[id] = component
            return component
        end
    end
end

"""
    add_components!(machine::Machine, components::Vector{MachineComponents})

Adds multiple components to the machine.   

**_NOTE:_** With this method, the added componentw will not be connected automatically. Connections must be added manually.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_component!(
           machine, 
           [
               State([1], [], SP("A", du="x += 1")), 
               Node(1, [], []), 
               Transition(1, TP(nothing, "A", order=1, act="x=0")),
           ]
       )

julia> machine
{states: 1, transitions: 1, nodes: 1} machine `simple_machine`.
```
"""
function add_components!(machine::Machine, components::Vector{MachineComponents})
    for comp in components
        add_component!(machine, comp)
    end
    return nothing
end
