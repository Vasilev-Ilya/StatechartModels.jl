#
# Functions for adding components to the machine
#

"""
    add_state!(machine::Machine; parameters::StateParameters)

Add state with name `name` with parameters `parameters` (see `StateParameters` struct for info) to the machine. 

# Examples
```jldoctest
julia> machine = Machine(name="simple_machine");

julia> add_state!(machine, parameters=StateParameters(id="A"))
{0, 0} state `A` with parent ``.

julia> add_state!(machine, parameters=StateParameters(id="B", parent_id="A"))
{0, 0} state `B` with parent `A`.

julia> machine
{states: 2, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function add_state!(machine::Machine; parameters::StateParameters)::State
    states = machine.states
    (; id, parent_id, entry, during, exit, order) = parameters
    isempty(id) && error("State name must not be empty.") 
    haskey(states, id) && throw_duplicated_id(id)
    
    if !isempty(parent_id)
        haskey(states, parent_id) || throw_no_component(Val(State), parent_id)
        push!(states[parent_id].substates, id)
    end
    
    state = State(id, parent_id=parent_id, substates=String[], inports=Int[], outports=Int[], entry=entry, 
        during=during, exit=exit, order=order)
    states[id] = state
    return state
end

"""
    add_node!(machine::Machine; parameters::NodeParameters=NodeParameters())

Add node with parameters `parameters` (see `NodeParameters` struct for info) to the machine.

# Examples
```jldoctest
julia> machine = Machine(name="simple_machine");

julia> add_node!(machine)
{0, 0} node `1` with parent ``.

julia> add_state!(machine, parameters=StateParameters(id="A")); add_node!(machine, parameters=NodeParameters(parent_id="A"))
{0, 0} node `2` with parent `A`.

julia> machine
{states: 1, transitions: 0, nodes: 2} machine `simple_machine`.
```
"""
function add_node!(machine::Machine; parameters::NodeParameters=NodeParameters())::Node
    nodes = machine.nodes

    (; parent_id) = parameters
    (!isempty(parent_id) && !haskey(nodes, parent_id)) && throw_no_component(Val(Node), parent_id)
    id = length(nodes) + 1
    node = Node(id, parent_id=parent_id, inports=Int[], outports=Int[])
    nodes[id] = node
    return node
end

"""
    add_transition!(machine::Machine; parameters::TransitionParameters)

Add transition with parameters `parameters` (see `TransitionParameters` struct for info) to the machine.   

# Examples
```jldoctest
julia> machine = Machine(name="simple_machine");

julia> add_state!(machine, parameters=StateParameters(id="A")); add_state!(machine, parameters=StateParameters(id="B");

julia> add_node!(machine); add_node!(machine);

julia> add_transition!(machine, parameters=TransitionParameters(source="A", destination="B", order=1)) # transition between state `A` and state `B`
{A, B} transition `1`.

julia> add_transition!(machine, parameters=TransitionParameters(source="A", destination=1, order=2, condition="x == 0")) # transition between state `A` and node `1` with condition `x == 0`
{A, 1} transition `2`.

julia> add_transition!(machine, parameters=TransitionParameters(source=2, destination="B", order=1, action="x = 0")) # transition between node `2` and state `B` with action `x = 0`
{2, B} transition `3`.

julia> add_transition!(machine, parameters=TransitionParameters(destination="A", order=1)) # input transition to state `A`
{nothing, A} transition `4`.
```
"""
function add_transition!(machine::Machine; parameters::TransitionParameters)::Transition
    transitions = machine.transitions
    id = length(transitions) + 1
    (; parent_id, source, destination, order, condition, action) = p

    if !isnothing(source)
        comp = get_node_or_state(machine, source)
        push!(comp.outports, id)
    end
    comp = get_node_or_state(machine, destination)
    push!(comp.inports, id)

    transition = Transition(id, parent_id=parent_id, source=source, destination=destination, order=order, 
        condition=condition, action=action)
    transitions[id] = transition
    return transition
end

"""
    add_states!(machine::Machine; parameters_collection::Vector{StateParameters})

Adds multiple states to the machine.   

The states to be added are stored in a vector `parameters_collection`. Each element of the vector is a `StateParameters` struct.   

# Examples
```jldoctest
julia> machine = Machine(name="simple_machine");

julia> add_states!(
        machine, 
        parameters_collection=[
            StateParameters(id="A", entry="x=0"), 
            StateParameters(id="B", during="x=1"), 
            StateParameters(id="C", exit="x=3"),
        ],
    )

julia> machine
{states: 3, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
function add_states! end

"""
    add_nodes!(machine::Machine; parameters_collection::Vector{NodeParameters})

Adds multiple nodes to the machine. 

The nodes to be added are stored in a vector `parameters_collection`. Each element of the vector is a `NodeParameters` struct.   

# Examples
```jldoctest
julia> machine = Machine(name="simple_machine");

julia> add_nodes!(machine, parameters_collection=[NodeParameters(), NodeParameters()])

julia> machine
{states: 0, transitions: 0, nodes: 2} machine `simple_machine`.
```
"""
function add_nodes! end

"""
    add_transitions!(machine::Machine; parameters_collection::Vector{TransitionParameters})

Adds multiple transitions to the machine.   

The transitions to be added are stored in a vector `parameters_collection`. Each element of the vector is a `TransitionParameters` struct.   

# Examples
```jldoctest
julia> machine = Machine(name="simple_machine");

julia> add_state!(machine, parameters=StateParameters(id="A")); add_node!(machine);

julia add_transitions!(
        machine, 
        parameters_collection=[
            TransitionParameters(destination="A", order=1, action="x=0"), 
            TransitionParameters(source="A", destination=1, order=1, condition="x==0")
        ],
    )

julia> machine
{states: 1, transitions: 2, nodes: 1} machine `simple_machine`.
```
"""
function add_transitions! end


for (func_name, subfunc_name, field_name, p_type) in [
    (:add_states!, :add_state!, :states, :StateParameters),
    (:add_nodes!, :add_node!, :nodes, :NodeParameters),
    (:add_transitions!, :add_transition!, :transitions, :TransitionParameters),
]
    @eval begin
        function $func_name(machine::Machine; parameters_collection::Vector{$p_type})
            isempty(parameters_collection) && return nothing
            components = machine.$field_name
            sizehint!(components, length(components) + length(parameters_collection))
            for parameters in parameters_collection
                $subfunc_name(machine, parameters=parameters)
            end
            return nothing
        end
    end
end

"""
    add_component!(machine::Machine; component::[State | Node | Transition])

Explicitly add a component `component` to the machine.   

**_NOTE:_** With this method, the added component will not be connected automatically. Connections must be added manually.

# Examples
```jldoctest
julia> machine = Machine(name="simple_machine");

julia> add_component!(machine, component=State("A", inports=[1], outports=[2], during="x += 1"))
{1, 1} state `A`.

julia> add_component!(machine, component=Node(1, inports=[2], outports=[]))
{1, 0} node `1`.

julia> add_transition!(machine, component=Transition(1, destination="A", order=1, action="x=0")) # input transition to state `A`
{nothing, A} transition `1`.

julia> add_transition!(machine, component=Transition(2, source="A", destination=1, order=1)) # transition between state `A` and node `1`
{A, 1} transition `2`.
```
"""
function add_component! end

for (field_name, comp_type) in [(:states, :State), (:nodes, :Node), (:transitions, :Transition)]
    @eval begin
        function add_component!(machine::Machine; component::$comp_type)::$comp_type
            components = machine.$field_name
            id = component.id
            haskey(components, id) && throw_duplicated_id(id)
            components[id] = component
            return component
        end
    end
end

"""
    add_components!(machine::Machine; components::Vector{MachineComponents})

Adds multiple components `components` to the machine.   

**_NOTE:_** With this method, the added componentw will not be connected automatically. Connections must be added manually.

# Examples
```jldoctest
julia> machine = Machine(name="simple_machine");

julia> add_component!(
           machine, 
           components=[
               State("A", inports=[1], outports=[], during="x += 1"), 
               Node(1, inports=[], outports=[]), 
               Transition(1, destination="A", order=1, action="x=0"),
           ]
       )

julia> machine
{states: 1, transitions: 1, nodes: 1} machine `simple_machine`.
```
"""
function add_components!(machine::Machine; components::Vector{MachineComponents})
    for component in components
        add_component!(machine, component=component)
    end
    return nothing
end
