#
# Core structures for creating a finite state machine
#
abstract type AbstractTransition end
const ComponentId = Union{String, Int}

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

	TransitionValues(order; cond, act) = new(order, cond, act)
end

"""
    InTransition

The input transition through which data enters the machine.

Fields
    - id: unique component identifier;
    - values: changeable transition parameters;
    - destination: the input port of the component to which the transition is directed.
"""
struct InTransition <: AbstractTransition
	id::Int
	values::TransitionValues
	destination::ComponentId

	InTransition(id, values; d) = new(id, values, d)
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
struct Transition <: AbstractTransition
	id::Int
	values::TransitionValues
	source::ComponentId
    destination::ComponentId

	Transition(id, values; s, d) = new(id, values, s, d)
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
    - id: node unique identifier;
    - inports: list of component input ports;
    - outports: list of component output ports.
"""
struct Node
    id::Int
    inports::Vector{Int}
    outports::Vector{Int}
end

"""
    State

State structure of a machine.

Fields
    - id: unique state identifier (a.k.a. state name);
    - actions: actions performed by the state;
    - inports: list of component input ports;
    - outports: list of component output ports.
"""
struct State
    id::String
    # actions::StateActions
    inports::Vector{Int}
    outports::Vector{Int}
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
    Machine

Structure of a finite state machine.
"""
struct Machine
    name::String   
    states::Dict{String, State}
    nodes::Vector{Node}
    transitions::Vector{AbstractTransition}
    data::Vector{Data}

    Machine(name::String) = new(name, Dict{String, State}(), Node[], AbstractTransition[], Data[])
end

