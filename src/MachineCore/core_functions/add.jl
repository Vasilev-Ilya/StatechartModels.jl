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
function add_state!(machine::Machine, name::String; en::String="", du::String="", ex::String="")::State
    states = machine.states
    isempty(name) && error("State name must not be empty.") 
    haskey(states, name) && throw_duplicated_id(name)
    state = State(name, Int[], Int[], en=en, du=du, ex=ex)
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
function add_states!(machine::Machine, states::Vector{SP})
    isempty(states) && return nothing
    machine_states = machine.states
    sizehint!(machine_states, length(machine_states) + length(states))
    for state in states
        add_state!(machine, state.name, en=state.entry, du=state.during, ex=state.exit)
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
    add_transition!(machine::Machine, s::ComponentId, d::ComponentId; order::Int=0, cond::String="", act::String="")

Add transition from source `s` to destination `d` with condition `cond` and action `act` to the machine.   

You can also set the execution order (`order`). If the `order` is `0`, then the execution order is last.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_state!(machine, "A"); add_state!(machine, "B");

julia> add_node!(machine); add_node!(machine);

julia> add_transition!(machine, "A", "B") # transition between state `A` and state `B`
{A, B} transition `1`.

julia> add_transition!(machine, "A", 1, cond="x == 0") # transition between state `A` and node `1` with condition `x == 0`
{A, 1} transition `2`.

julia> add_transition!(machine, 2, "B", act="x = 0") # transition between node `2` and state `B` with action `x = 0`
{2, B} transition `3`.
```
"""
function add_transition!(
    machine::Machine, 
    s::ComponentId, 
    d::ComponentId; 
    order::Int=0, 
    cond::String="", 
    act::String="",
)::Transition
    transitions = machine.transitions
    id = length(transitions) + 1
    if s isa String
        state =  get_state(machine.states, s)
        order = !iszero(order) ? order : length(state.outports) + 1
        push!(state.outports, id)
    else
        node = get_node(machine.nodes, s)
        order = !iszero(order) ? order : length(node.outports) + 1
        push!(node.outports, id)
    end
    _fill_destination!(machine, id, d)
    transition = Transition(id, TP(s, d, order=order, cond=cond, act=act))
    transitions[id] = transition
    return transition
end

"""
    add_transition!(machine::Machine, d::ComponentId; order::Int=0, cond::String="", act::String="")

Add input transition to component `d` with condition `cond` and action `act` to the machine.   

You can also set the execution order (`order`). If the `order` is `0`, then the execution order of the transition \
has the lowest priority in the component to which it is connected.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_state!(machine, "A"); add_node!(machine);

julia> add_transition!(machine, "A") # input transition to state `A`
{nothing, A} transition `1`.

julia> add_transition!(machine, 1, act="x = 0") # input transition to node `1` with action `x = 0`
{nothing, 1} transition `2`.
```
"""
function add_transition!(machine::Machine, d::ComponentId; order::Int=0, cond::String="", act::String="")::Transition
    transitions = machine.transitions
    id = length(transitions) + 1
    _fill_destination!(machine, id, d)
    if iszero(order)
        order = 1
        for (_, tra) in transitions
            isnothing(tra.source) && (order += 1;)
        end
    end
    transition = Transition(id, TP(d, order=order, cond=cond, act=act))
    transitions[id] = transition
    return transition
end

"""
    _fill_destination!(machine::Machine, id::Int, d::ComponentId)

Add connection information to the destination component in the machine.
"""
function _fill_destination!(machine::Machine, id::Int, d::ComponentId)
    if d isa String
        state = get_state(machine.states, d)
        push!(state.inports, id)
    else
        node = get_node(machine.nodes, d)
        push!(node.inports, id)
    end
    return nothing
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
function add_transitions!(machine::Machine, transitions::Vector{TP})
    isempty(transitions) && return nothing
    machine_trans = machine.transitions
    sizehint!(machine_trans, length(machine_trans) + length(transitions))
    for tran in transitions
        if isnothing(tran.source)
            add_transition!(machine, tran.destination, order=tran.order, cond=tran.cond, act=tran.act)
        else
            add_transition!(machine, tran.source, tran.destination, order=tran.order, cond=tran.cond, act=tran.act)
        end
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

julia> add_component!(machine, State("A", [1], [2], du="x += 1"))
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
               State("A", [1], [], du="x += 1"), 
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
