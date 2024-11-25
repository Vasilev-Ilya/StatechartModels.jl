#
# Core structures for creating a finite state machine
#
const ComponentId = Union{String, Int}
abs

"""
    TP

Contains changeable transition parameters.

Fields
- `source`: output port of the component from which the transition is directed;
- `destination`: the input port of the component to which the transition is directed.
- `order`: the order of execution of the transition;
- `condition`: transition condition;
- `action`: action performed during transition.
"""
mutable struct TP
    source::Union{Nothing, ComponentId}
    destination::Union{Nothing, ComponentId}
    order::Int
    condition::String
    action::String

    TP(d::ComponentId; order=0, cond="", act="") = new(nothing, d, order, cond, act)
    TP(s::ComponentId, d::ComponentId; order=0, cond="", act="") = new(s, d, order, cond, act)
end

"""
    Transition

Connects the components of the machine

Fields
- `id`: unique component identifier;
- `values`: changeable transition parameters.
"""
struct Transition
	id::Int
	values::TP

	Transition(id, values) = new(id, values)
end

"""
    Node

Auxiliary component.

Fields
- `id`: node unique identifier;
- `inports`: list of component input ports;
- `outports`: list of component output ports.
"""
struct Node
    id::Int
    inports::Vector{Int}
    outports::Vector{Int}
end

"""
    SP

State parameters.

Fields
- `id`: unique state identifier (a.k.a. state name);
- `entry`: action performed when a state is activated;
- `during`: action performed when the state is active;
- `exit`: the action performed when the state is deactivated.
"""
mutable struct SP
    id::String
    entry::String
    during::String
    exit::String

    SP(id; en="", du="", ex="") = new(id, en, du, ex)
end

"""
    State

State structure of a machine.

Fields
- `inports`: list of component input ports;
- `outports`: list of component output ports;
- `values`: changeable state parameters.
"""
mutable struct State
    id::String
    inports::Vector{Int}
    outports::Vector{Int}
    entry::String
    during::String
    exit::String

    State(id, inports, outports, entry, during, exit) = new(id, inports, outports, entry, during, exit)
    function State(inports::Vector, outports::Vector, values::SP)
        new(values.id, inports, outports, values.entry, values.during, values.exit)
    end
end

const MachineComponents = Union{State, Node, Transition}
const StateCollection = Dict{String, State}
const NodeCollection = Dict{Int, Node}
const TransitionCollection = Dict{Int, Transition}
const MachineCollection = Union{StateCollection, NodeCollection, TransitionCollection}

"""
    Data

The structure of the data variable used in the machine.
"""
struct Data
    name::String
    value::String
    type::String
end

"""
    Machine(name::String)
    
Creates a finite state machine structure named `name`. The structure contains the following fields:   
- `name`: machine name;   
- `states`: dictionary of states;   
- `nodes`: dictionary of nodes;   
- `transitions`: dictionary of transitions;   
- `data`: list of variables used in the machine.   

# Examples
```jldoctest
julia> machine = Machine("simple_machine")
{states: 0, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
struct Machine
    name::String   
    states::StateCollection
    nodes::NodeCollection
    transitions::TransitionCollection
    data::Vector{Data}

    Machine(name::String) = new(name, Dict{String, State}(), Dict{Int, Node}(), Dict{Int, Transition}(), Data[])
end

