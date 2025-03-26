#
# Functions for getting components from the machine
#

"""
    get_machine_component(MC::MachineComponentsDicts; id::ComponentId)

Get the structure of machine components with `id` from some machine collection `MC`.

# Examples
```jldoctest
julia> machine = Machine(id="simple_machine");

julia> add_state!(machine, "A"); add_node!(machine); add_transition!(machine, "A", 1);

julia> get_machine_component(machine.states; id="A")
{0, 1} state A.

julia> get_machine_component(machine.nodes; id=1)
{1, 0} node 1.

julia> get_machine_component(machine.transitions; id=1)
{"A", 1} transition 1.
```
"""
get_machine_component(MC::MachineComponentsDicts; id::ComponentId) = get(MC, id, nothing)


"""
    get_state(machine::Machine; id::String)

Get the structure of state `id`.

# Examples
```jldoctest
julia> machine = Machine(id="simple_machine");

julia> add_state!(machine, "A"); add_state!(machine, "B");

julia> get_state(machine, "A")
{0, 0} state A.

julia> get_state(machine, "B")
{0, 0} state B.
```
"""
function get_state end

"""
    get_node(machine::Machine; id::Int)

Get the structure of node `id`.

# Examples
```jldoctest
julia> machine = Machine(id="simple_machine");

julia> add_node!(machine); add_node!(machine);

julia> get_node(machine, 1)
{0, 0} node 1.

julia> get_node(machine, 2)
{0, 0} node 2.
```
"""
function get_node end

"""
    get_transition(machine::Machine; id::Int)

Get the structure of transition `id`.

# Examples
```jldoctest
julia> machine = Machine(id="simple_machine");

julia> add_node!(machine); add_node!(machine);

julia> add_transition!(machine, 1, 2); add_transition!(machine, 2, 1);

julia> get_transition(machine, 1)
{1, 2} transition 1.

julia> get_transition(machine, 2)
{2, 1} transition 2.
```
"""
function get_transition end


for (fname, field_name, arg_type) in [(:get_state, :states, :String), (:get_node, :nodes, :Int), (:get_transition, :transitions, :Int)]
    @eval begin
        $fname(machine::Machine; id::$arg_type) = get_machine_component(machine.$field_name, id=id)
    end
end

"""
"""
get_node_or_state(machine::Machine; id::ComponentId) = id isa String ? get_state(machine, id=id) : get_node(machine, id=id)

"""
"""
get_out_transitions(machine::Machine; comp::Union{State, Node}) = [get_transition(machine, id=output_id) for output_id in comp.outports]

"""
"""
get_substates(states::Dict{StateId, State}, parent_name::StateId) = State[state for (_, state) in states if state.parent_id == parent_name]

get_substates(states::Dict{StateId, State}, parent_state::State) = get_substates(states, parent_state.parent_id)

"""
"""
get_in_transitions(transitions::Dict{TransitionId, Transition}, parent_name::StateId) = 
    Transition[tra for (_, tra) in transitions if isnothing(tra.source) && tra.parent_id == parent_name]