# Core structure for creating a finite state machine

const ComponentName = String
const ComponentId = Base.UUID
const PortId = Base.UUID

"""
    TransitionValues

Contains changeable transition parameters.

Fields
    - order: the order of execution of the transition;
    - condition: transition condition;
    - action: action performed during transition.
"""
mutable struct TransitionValues
	order::Int
	condition::String
	action::String

	TransitionValues(order; condition, action) = new(order, condition, action)
end

"""
    InTransition

The input transition through which data enters the machine.

Fields
    - id: unique component identifier;
    - values: changeable transition parameters;
    - destination: the input port of the component to which the transition is directed.
"""
struct InTransition
	id::ComponentId
	values::TransitionValues
	destination::PortId

	InTransition(id, values; destination) = new(id, values, destination)
end

"""
    Transition

Connects the components of the machine

Fields
    - id: unique component identifier;
    - values: changeable transition parameters;
    - source: output port of the component from which the transition is directed;
    - destination: the input port of the component to which the transition is directed.
"""
struct Transition
	id::ComponentId
	values::TransitionValues
	source::PortId
    destination::PortId

	Transition(id, values, source, destination) = new(id, values, source, destination)
end

"""
    StateActions

Actions that the machine must perform.

Fields
    - entry: action performed when a state is activated;
    - during: action performed when the state is active;
    - exit: the action performed when the state is deactivated.
"""
mutable struct StateActions
    entry::String
    during::String
    exit::String

    StateActions(; entry, during, exit) = new(entry, during, exit)
end

"""
    Node

Auxiliary component.

Fields
    - name: component name;
    - inports: list of component input ports;
    - outports: list of component output ports.
"""
struct Node
    name::String
    inports::Vector{PortId}
    outports::Vector{PortId}
end

"""
    State

State structure of a machine.

Fields
    - name: component name;
    - actions: actions performed by the state;
    - inports: list of component input ports;
    - outports: list of component output ports.
"""
struct State
    name::String
    actions::StateActions
    inports::Vector{PortId}
    outports::Vector{PortId}

    State(name, actions; inports, outports) = new(name, action, inports, outports)
end

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
    State

State structure of a machine.
"""
struct Machine
    name::String
    inputs::Vector{InTransition}    
    states::Dict{ComponentName, State}
    nodes::Dict{ComponentName, Node}
    transitions::Dict{PortId, Transition}
    data::Dict{String, Data}
end

