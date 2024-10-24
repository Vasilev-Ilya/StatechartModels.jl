#
# Core functions for creating a finite state machine
#

"""
"""
function state!(
    machine::Machine; 
    name::String, 
    # entry_code::String,
    # during_code::String, 
    # exit_code::String,
    # force::Bool=false,
)::State
    states = machine.states
    isempty(name) && error("State name must not be empty.") 
    haskey(states, name) && error("A state with name `$name` already exists.")
    state = State(name, Int[], Int[])
    states[name] = state
    return state
end

"""
"""
function node!(machine::Machine)
    nodes = machine.nodes
    node = Node(length(nodes) + 1, Int[], Int[])
    push!(nodes, node)
    return node
end

"""
"""
function transition!(machine::Machine, s::ComponentId, d::ComponentId; cond::String="", act::String="")
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
    push!(transitions, transition)
    return transition
end

"""
"""
function transition!(machine::Machine, d::ComponentId; cond::String="", act::String="")
    transitions = machine.transitions
    id = length(transitions) + 1
    _fill_destination!(machine, id, d)
    in_transition = InTransition(id, TransitionValues(order, cond=cond, act=act), d=d)
    push!(transitions, in_transition)
    return in_transition
end

"""
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
"""
function get_node(nodes::Vector{Node}, n::Int)
    for node in nodes
        node.id == n && return node
    end
    error("Node $s does not exist.")
end

get_node(machine::Machine, n::Int) = get_node(machine.nodes, n)
