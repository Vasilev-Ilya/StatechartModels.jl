#
# Core functions for creating a finite state machine
#

"""
    state!(machine::Machine, name::String)

Add state with name `name` to the machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> state!(machine, "A")
{0, 0} state `A`.

julia> machine
{states: 1, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function state!(machine::Machine, name::String)::State
    states = machine.states
    isempty(name) && error("State name must not be empty.") 
    haskey(states, name) && error("A state with name `$name` already exists.")
    state = State(name, Int[], Int[])
    states[name] = state
    return state
end

"""
    node!(machine::Machine)

Add node to the machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> node!(machine)
{0, 0} node `1`.

julia> machine
{states: 0, transitions: 0, nodes: 1} machine `simple_machine`.
```
"""
function node!(machine::Machine)::Node
    nodes = machine.nodes
    id = length(nodes) + 1
    node = Node(id, Int[], Int[])
    nodes[id] = node
    return node
end

"""
    transition!(machine::Machine, s::ComponentId, d::ComponentId; cond::String="", act::String="")

Add transition from source `s` to destination `d` with condition `cond` and action `act` to the machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> state!(machine, "A"); state!(machine, "B");

julia> node!(machine); node!(machine);

julia> transition!(machine, "A", "B") # transition between state `A` and state `B`
{A, B} transition `1`.

julia> transition!(machine, "A", 1, cond="x == 0") # transition between state `A` and node `1` with condition `x == 0`
{A, 1} transition `2`.

julia> transition!(machine, 2, "B", act="x = 0") # transition between node `2` and state `B` with action `x = 0`
{2, B} transition `3`.
````
"""
function transition!(machine::Machine, s::ComponentId, d::ComponentId; cond::String="", act::String="")::Transition
    transitions = machine.transitions
    id = length(transitions) + 1
    if s isa String
        states = machine.states
        haskey(states, s) || throw_no_state(s)
        state = states[s]
        order = length(state.outports) + 1
        push!(state.outports, id)
    else
        nodes = machine.nodes
        0 < s <= length(nodes) || throw_no_node(s)
        node = get_node(nodes, s)
        order = length(node.outports) + 1
        push!(node.outports, id)
    end
    _fill_destination!(machine, id, d)
    transition = Transition(id, TransitionValues(order, cond=cond, act=act), s=s, d=d)
    transitions[id] = transition
    return transition
end

"""
    transition!(machine::Machine, d::ComponentId; cond::String="", act::String="")

Add input transition to component `d` with condition `cond` and action `act` to the machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> state!(machine, "A"); node!(machine);

julia> transition!(machine, "A") # input transition to state `A`
Input transition `1` to state `A`.

julia> transition!(machine, 1, act="x = 0") # input transition to node `1` with action `x = 0`
Input transition `2` to node `1`.
````
"""
function transition!(machine::Machine, d::ComponentId; cond::String="", act::String="")
    transitions = machine.transitions
    id = length(transitions) + 1
    _fill_destination!(machine, id, d)
    order = 1
    for (_, tra) in transitions
        isnothing(tra.source) && (order += 1;)
    end
    transition = Transition(id, TransitionValues(order, cond=cond, act=act), s=nothing, d=d)
    transitions[id] = transition
    return transition
end

"""
    _fill_destination!(machine::Machine, id::Int, d::ComponentId)

Add connection information to the destination component in the machine.
"""
function _fill_destination!(machine::Machine, id::Int, d::ComponentId)
    if d isa String
        states = machine.states
        haskey(states, d) || throw_no_state(d)
        state = states[d]
        push!(state.inports, id)
    else
        nodes = machine.nodes
        0 < d <= length(nodes) || throw_no_node(d)
        node = get_node(nodes, d)
        push!(node.inports, id)
    end
    return nothing
end

"""
    get_node([T=Dict{Int, Node}, T=Machine], n::Int)

Get the structure of node n.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> node!(machine); node!(machine);

julia> get_node(machine.nodes, 1)
{0, 0} node 1.

julia> get_node(machine, 2)
{0, 0} node 2.
````
"""
function get_node(nodes::Dict{Int, Node}, n::Int)::Node
    node::Union{Node, Nothing} = get(nodes, n, nothing)
    isnothing(node) && error("Node $n does not exist.")
    return node
end

get_node(machine::Machine, n::Int) = get_node(machine.nodes, n)

"""
    get_transition([T=Dict{Int, Transition}, T=Machine], n::Int)

Get the structure of transition n.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> node!(machine); node!(machine);

julia> transition!(machine, 1, 2); transition!(machine, 2, 1);

julia> get_transition(machine.transitions, 1)
{1, 2} transition 1.

julia> get_transition(machine, 2)
{2, 1} transition 2.
````
"""
function get_transition(transitions::Dict{Int, Transition}, n::Int)::Transition
    transition::Union{Transition, Nothing} = get(transitions, n, nothing)
    isnothing(transition) && error("Transition $n does not exist.")
    return transition
end

get_transition(machine::Machine, n::Int) = get_transition(machine.transitions, n)

"""
    get_state([T=Dict{String, State}, T=Machine], n::String)

Get the structure of state n.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> state!(machine, "A"); state!(machine, "B");

julia> get_state(machine.states, "A")
{0, 0} state A.

julia> get_state(machine, "B")
{0, 0} state B.
"""
function get_state(states::Dict{String, State}, n::String)::State
    state::Union{State, Nothing} = get(states, n, nothing)
    isnothing(state) && error("State $n does not exist.")
    return state
end

get_state(machine::Machine, n::String) = get_state(machine.states, n)
