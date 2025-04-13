module MachineAPI

    export MachineID, StateID, TransitionID, NodeID
    export Machine, State, Transition, Node, MachineComponents, MachineComponentsDicts, TransitionParameters, NodeParameters, 
        StateParameters, Data
    export add_state!, add_states!, add_transition!, add_transitions!, add_node!, add_nodes!, add_component!, add_components!,
        add_data!
    export get_machine_component, get_node, get_transition, get_state, get_out_transitions, get_node_or_state, get_substates,
        get_state_parent_tree_vector, get_in_transitions
    export change_connection!
    export check_state_is_parent
    export rm_state!, rm_states!, rm_node!, rm_nodes!, rm_transition!, rm_transitions!, rm_data!

    const DATA_SCOPES = (:INPUT, :LOCAL, :OUTPUT)

    include("api_types.jl")

    function Base.show(io::IO, ::MIME"text/plain", transition::Transition)
        s = transition.source
        d = transition.destination
        return print(io, "{$s, $d} transition `$(transition.id)`.")
    end

    function Base.show(io::IO, ::MIME"text/plain", state::State)
        n_i = length(state.inports)
        n_o = length(state.outports)
        return print(io, "{$n_i, $n_o} state `$(state.id)` with parent `$(state.parent_id)`.")
    end

    function Base.show(io::IO, ::MIME"text/plain", node::Node)
        n_i = length(node.inports)
        n_o = length(node.outports)
        return print(io, "{$n_i, $n_o} node `$(node.id)` with parent `$(node.parent_id)`.")
    end

    function Base.show(io::IO, ::MIME"text/plain", var::Data)
        return print(io, "The variable `$(var.name)` {value: $(var.value), type: $(var.data_type), scope: $(var.scope)}.")
    end

    function Base.show(io::IO, ::MIME"text/plain", machine::Machine)
        n_s = length(machine.states)
        n_t = length(machine.transitions)
        n_n = length(machine.nodes)
        return print(io, "{states: $n_s, transitions: $n_t, nodes: $n_n} machine `$(machine.id)`.")
    end

    include("common_erros.jl")
    include("api_functions/api_functions.jl")
end # module