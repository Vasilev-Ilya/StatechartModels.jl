#
# Core structures for creating a finite state machine
#
const MachineID = String
const StateID = String
const NodeID = Int
const TransitionID = Int
const ComponentId = Union{StateID, NodeID, TransitionID}

"""
    TransitionParameters

Contains changeable transition parameters.

Fields
- `parent_id`: unique parent state identifier;
- `source`: output port of the component from which the transition is directed;
- `destination`: the input port of the component to which the transition is directed.
- `order`: the order of execution of the transition;
- `condition`: transition condition;
- `action`: action performed during transition.
"""
Base.@kwdef struct TransitionParameters
    parent_id::StateID=""
    source::Union{Nothing, ComponentId}=nothing
    destination::Union{Nothing, ComponentId}
    order::Int
    condition::String=""
    action::String=""
end

"""
    Transition

Connects the components of the machine

Fields
- `id`: unique component identifier;
- `values`: changeable transition parameters.
"""
mutable struct Transition
	id::TransitionID
    parent_id::StateID
    source::Union{Nothing, ComponentId}
    destination::Union{Nothing, ComponentId}
    order::Int
    condition::String
    action::String

	function Transition(id; source, destination, order, parent_id, condition, action)
        order > 0 && throw(ArgumentError("The execution order of the transition `$id` must be positive."))
        new(id, parent_id, source, destination, order, condition, action)
    end
end

"""
    NodeParameters

Contains changeable node parameters.

Fields
- `parent_id`: unique parent state identifier;
- `history`: node is history (`true`/`false`).
"""
Base.@kwdef struct NodeParameters
    parent_id::StateID=""
    history::Bool=false
end

"""
    Node

Auxiliary component.

Fields
- `id`: node unique identifier;
- `parent_id`: unique parent state identifier;
- `inports`: list of component input ports;
- `outports`: list of component output ports;
- `history`: node is history (`true`/`false`).
"""
mutable struct Node
    id::NodeID
    parent_id::StateID
    inports::Vector{TransitionID}
    outports::Vector{TransitionID}
    history::Bool

    function Node(id; parent_id, inports, outports, history)
        new(id, parent_id, inports, outports, history)
    end
end

"""
    StateParameters

State parameters.

Fields
- `id`: unique state identifier (a.k.a. state name);
- `parent_id`: unique parent state identifier;
- `entry`: action performed when a state is activated;
- `during`: action performed when the state is active;
- `exit`: the action performed when the state is deactivated;
- `order`: order of execution of parallel state (if state is not parallel, then order is "nothing");
"""
Base.@kwdef struct StateParameters
    id::StateID
    parent_id::StateID=""
    entry::String=""
    during::String=""
    exit::String=""
    order::Union{Nothing, Int}=nothing
end

"""
    State

State structure of a machine.

Fields
- `id`: unique state identifier (a.k.a. state name);
- `parent_id`: unique parent state identifier;
- `entry`: action performed when a state is activated;
- `during`: action performed when the state is active;
- `exit`: action performed when the state is deactivated;
- `inports`: list of component input ports;
- `outports`: list of component output ports;
- `order`: order of execution of parallel state (if state is not parallel, then order is "nothing");
"""
mutable struct State
    id::StateID
    parent_id::StateID
    entry::String
    during::String
    exit::String
    inports::Vector{TransitionID}
    outports::Vector{TransitionID}
    order::Union{Nothing, Int}
    
    function State(id; parent_id, inports, outports, entry, during, exit, order)
        if !isnothing(order)
            order > 0 && throw(ArgumentError("The execution order of the parallel state `$id` must be positive."))
        end
        new(id, parent_id, entry, during, exit, inports, outports, order)
    end
end

const MachineComponents = Union{State, Node, Transition}
const MachineComponentsDicts = Union{Dict{String, State}, Dict{Int, Node}, Dict{Int, Transition}}

"""
    Data

The structure of the data variable used in the machine.
"""
Base.@kwdef struct Data
    name::String
    value::String="nothing"
    type::String=""
end

"""
    Machine
    
Creates a finite state machine structure named `id`. The structure contains the following fields:   
- `id`: unique machine identifier (a.k.a. machine name);   
- `states`: dictionary of states;   
- `nodes`: dictionary of nodes;   
- `transitions`: dictionary of transitions;   
- `data`: list of variables used in the machine.   

# Examples
```jldoctest
julia> machine = Machine(id="simple_machine")
{states: 0, transitions: 0, nodes: 0} machine `simple_machine`.
```
"""
Base.@kwdef struct Machine
    id::MachineID   
    states::Dict{StateID, State}=Dict{StateID, State}()
    nodes::Dict{NodeID, Node}=Dict{NodeID, Node}()
    transitions::Dict{TransitionID, Transition}=Dict{TransitionID, Transition}()
    data::Vector{Data}=Data[]
end
