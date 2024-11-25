module MachineCore

    export Machine, State, Transition, Node, MachineComponents, StateCollection, NodeCollection, TransitionCollection, 
        MachineCollection, TP, SP
    export add_state!, add_states!, add_transition!, add_transitions!, add_node!, add_nodes!, add_component!, add_components!
    export get_machine_component, get_node, get_transition, get_state, change_connection!
    export rm_state!, rm_states!, rm_node!, rm_nodes!, rm_transition!, rm_transitions!

    include("core_types.jl")

    function Base.show(io::IO, ::MIME"text/plain", transition::Transition)
        s = transition.values.source
        d = transition.values.destination
        return print(io, "{$s, $d} transition `$(transition.id)`.")
    end

    function Base.show(io::IO, ::MIME"text/plain", state::State)
        n_i = length(state.inports)
        n_o = length(state.outports)
        return print(io, "{$n_i, $n_o} state `$(state.id)`.")
    end

    function Base.show(io::IO, ::MIME"text/plain", node::Node)
        n_i = length(node.inports)
        n_o = length(node.outports)
        return print(io, "{$n_i, $n_o} node `$(node.id)`.")
    end

    function Base.show(io::IO, ::MIME"text/plain", machine::Machine)
        n_s = length(machine.states)
        n_t = length(machine.transitions)
        n_n = length(machine.nodes)
        return print(io, "{states: $n_s, transitions: $n_t, nodes: $n_n} machine `$(machine.name)`.")
    end

    include("common_erros.jl")
    include("core_functions/core_functions.jl")
end # module