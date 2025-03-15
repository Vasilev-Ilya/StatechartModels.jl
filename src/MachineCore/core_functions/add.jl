#
# Functions for adding components to the machine
#

"""
    add_state!(machine::Machine, p::SP)

Add state with name `name` with parameters `p` (see `SP` struct for info) to the machine. 

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_state!(machine, SP("A"))
{0, 0} state `A` with parent ``.

julia> add_state!(machine, SP("B", parent="A"))
{0, 0} state `B` with parent `A`.

julia> machine
{states: 2, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function add_state!(machine::Machine, p::SP)::State
    states = machine.states
    
    name = p.id
    isempty(name) && error("State name must not be empty.") 
    haskey(states, name) && throw_duplicated_id(name)
    
    parent_name = p.parent_id
    if !isempty(parent_name)
        haskey(states, parent_name) || throw_no_component(Val(State), parent_name)
        push!(states[parent_name].substates, name)
    end
    
    state = State(String[], Int[], Int[], p)
    states[name] = state
    return state
end

"""
    add_node!(machine::Machine, p::NP=NP())

Add node with parameters `p` (see `NP` struct for info) to the machine.

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_node!(machine)
{0, 0} node `1` with parent ``.

julia> add_state!(machine, SP("A")); add_node!(machine, NP(parent="A"))
{0, 0} node `2` with parent `A`.

julia> machine
{states: 1, transitions: 0, nodes: 2} machine `simple_machine`.
```
"""
function add_node!(machine::Machine, p::NP=NP())::Node
    nodes = machine.nodes

    parent_id = p.parent_id
    (!isempty(parent_id) && !haskey(nodes, parent_id)) && throw_no_component(Val(Node), parent_id)
    id = length(nodes) + 1
    node = Node(id, p, Int[], Int[])
    nodes[id] = node
    return node
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
        comp = get_node_or_state(machine, s)
        push!(comp.outports, id)
        iszero(p.order) && (p.order = length(comp.outports);)
    end
    comp = get_node_or_state(machine, d)
    push!(comp.inports, id)

    transition = Transition(id, p)
    transitions[id] = transition
    return transition
end

"""
    add_states!(machine::Machine, parameters::Vector{SP})

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
function add_states! end

"""
    add_nodes!(machine::Machine, parameters::Vector{NP})

Adds multiple nodes to the machine. 

The nodes to be added are stored in a vector. Each element of the vector is a `NP` struct.   

# Examples
```jldoctest
julia> machine = Machine("simple_machine");

julia> add_nodes!(machine, [NP(), NP()])

julia> machine
{states: 0, transitions: 0, nodes: 2} machine `simple_machine`.
```
"""
function add_nodes! end

"""
    add_transitions!(machine::Machine, parameters::Vector{TP})

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
function add_transitions! end


for (func_name, subfunc_name, field_name, p_type) in [
    (:add_states!, :add_state!, :states, :SP),
    (:add_nodes!, :add_node!, :nodes, :NP),
    (:add_transitions!, :add_transition!, :transitions, :TP),
]
    @eval begin
        function $func_name(machine::Machine, parameters::Vector{$p_type})
            isempty(parameters) && return nothing
            components = machine.$field_name
            sizehint!(components, length(components) + length(parameters))
            for p in parameters
                $subfunc_name(machine, p)
            end
            return nothing
        end
    end
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

for (field_name, comp_type) in [(:states, :State), (:nodes, :Node), (:transitions, :Transition)]
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
