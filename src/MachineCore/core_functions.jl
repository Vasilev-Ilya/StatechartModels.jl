#
# Core functions for creating a finite state machine
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
    add_transition!(machine::Machine, s::ComponentId, d::ComponentId; cond::String="", act::String="")

Add transition from source `s` to destination `d` with condition `cond` and action `act` to the machine.

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
````
"""
function add_transition!(
    machine::Machine, 
    s::ComponentId, 
    d::ComponentId; 
    order::Union{Nothing, Int}=nothing, 
    cond::String="", 
    act::String="",
)::Transition
    transitions = machine.transitions
    id = length(transitions) + 1
    if s isa String
        state =  get_state(machine.states, s)
        order = !isnothing(order) ? order : length(state.outports) + 1
        push!(state.outports, id)
    else
        node = get_node(machine.nodes, s)
        order = !isnothing(order) ? order : length(node.outports) + 1
        push!(node.outports, id)
    end
    _fill_destination!(machine, id, d)
    transition = Transition(id, TransitionValues(s, d, order=order, cond=cond, act=act))
    transitions[id] = transition
    return transition
end

"""
    add_transition!(machine::Machine, d::ComponentId; cond::String="", act::String="")

Add input transition to component `d` with condition `cond` and action `act` to the machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_state!(machine, "A"); add_node!(machine);

julia> add_transition!(machine, "A") # input transition to state `A`
{nothing, A} transition `1`.

julia> add_transition!(machine, 1, act="x = 0") # input transition to node `1` with action `x = 0`
{nothing, 1} transition `2`.
````
"""
function add_transition!(
    machine::Machine, 
    d::ComponentId; 
    order::Union{Nothing, Int}=nothing, 
    cond::String="", 
    act::String="",
)::Transition
    transitions = machine.transitions
    id = length(transitions) + 1
    _fill_destination!(machine, id, d)
    if isnothing(order)
        order = 1
        for (_, tra) in transitions
            isnothing(tra.source) && (order += 1;)
        end
    end
    transition = Transition(id, TransitionValues(nothing, d, order=order, cond=cond, act=act))
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

julia> add_transition!(machine, Transition(1, TransitionValues(nothing, "A", order=1, act="x=0"))) # input transition to state `A`
{nothing, A} transition `1`.

julia> add_transition!(machine, Transition(2, TransitionValues("A", 1, order=1))) # transition between state `A` and node `1`
{A, 1} transition `2`.
````
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
    get_node([T=Dict{Int, Node}, T=Machine], n::Int)

Get the structure of node n.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_node!(machine); add_node!(machine);

julia> get_node(machine.nodes, 1)
{0, 0} node 1.

julia> get_node(machine, 2)
{0, 0} node 2.
````
"""
function get_node(nodes::Dict{Int, Node}, n::Int)::Node
    node::Union{Node, Nothing} = get(nodes, n, nothing)
    isnothing(node) && error("Node `$n` does not exist.")
    return node
end

get_node(machine::Machine, n::Int) = get_node(machine.nodes, n)

"""
    get_transition([T=Dict{Int, Transition}, T=Machine], n::Int)

Get the structure of transition n.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_node!(machine); add_node!(machine);

julia> add_transition!(machine, 1, 2); add_transition!(machine, 2, 1);

julia> get_transition(machine.transitions, 1)
{1, 2} transition 1.

julia> get_transition(machine, 2)
{2, 1} transition 2.
````
"""
function get_transition(transitions::Dict{Int, Transition}, n::Int)::Transition
    transition::Union{Transition, Nothing} = get(transitions, n, nothing)
    isnothing(transition) && error("Transition `$n` does not exist.")
    return transition
end

get_transition(machine::Machine, n::Int) = get_transition(machine.transitions, n)

"""
    get_state([T=Dict{String, State}, T=Machine], n::String)

Get the structure of state n.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_state!(machine, "A"); add_state!(machine, "B");

julia> get_state(machine.states, "A")
{0, 0} state A.

julia> get_state(machine, "B")
{0, 0} state B.
"""
function get_state(states::Dict{String, State}, n::String)::State
    state::Union{State, Nothing} = get(states, n, nothing)
    isnothing(state) && error("State `$n` does not exist.")
    return state
end

get_state(machine::Machine, n::String) = get_state(machine.states, n)
