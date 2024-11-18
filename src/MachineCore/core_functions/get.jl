#
# Functions for getting components from the machine
#

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
```
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
```
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
```
"""
function get_state(states::Dict{String, State}, n::String)::State
    state::Union{State, Nothing} = get(states, n, nothing)
    isnothing(state) && error("State `$n` does not exist.")
    return state
end

get_state(machine::Machine, n::String) = get_state(machine.states, n)
