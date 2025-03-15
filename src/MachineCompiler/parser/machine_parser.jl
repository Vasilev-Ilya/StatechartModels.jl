
function parse_node! end

for (field_name, type_name) in [(:exit_state_info, :ExitStateInfo), (:initialization_info, :InitializationInfo)]
    function parse_node!(
        machine::Machine,
        node::Node;
        $field_name::$type_name,
    )::ParseTree
        out_transitions = get_out_transitions(machine, node)
        next = Vector{ParseTree}(undef, length(out_transitions))
        for out_tran in out_transitions
            next[out_tran.values.order] = parse_transition!(machine, out_tran, $field_name=$field_name)
        end
        return FORK(next, id=node.id, type=:node)
    end
end

function parse_transition!(
    machine::Machine,
    transition::Transition;
    exit_state_info::ExitStateInfo,
)::ParseTree
    comp = get_node_or_state(machine, transition.values.destination)
    if comp isa State
        next = parse_state!(machine, comp, exit_state_info=exit_state_info)
    else
        if !isempty(comp.outports)
            next = parse_node!(machine, comp, exit_state_info=exit_state_info)
        else
            next = FORK(ParseTree[exit_state_info.tail, LEAF(id=comp.id, type=:node)])
        end
    end
end

function parse_transition!(
    machine::Machine,
    transition::Transition;
    initialization_info::InitializationInfo,
)::ParseTree
    comp = get_node_or_state(machine, transition.values.destination)
    if comp isa State
        next = parse_state!(machine, comp, initialization_info=initialization_info)
    else
        if !isempty(comp.outports)
            next = parse_node!(machine, comp, initialization_info=initialization_info)
        else
            next = FORK(ParseTree[initialization_info.tail, LEAF(id=comp.id, type=:node)])
        end
    end
    return next
end

function parse_state!(
    machine::Machine,
    state::State;
    exit_state_info::ExitStateInfo,
)::ParseTree
    
end

function parse_state!(
    machine::Machine,
    state::State;
    initialization_info::InitializationInfo,
)::ParseTree
    
end