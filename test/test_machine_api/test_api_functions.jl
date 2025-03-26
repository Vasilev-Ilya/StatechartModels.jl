machine = Machine(id="test_machine")

add_state!(machine, StateParameters("A", en="x += 1;")); add_component!(machine, State([], [], [], StateParameters("B", ex="x += 1;")));
add_node!(machine); add_component!(machine, Node(2, NodeParameters(), [], []));
add_transition!(machine, TransitionParameters(1))
add_transition!(machine, TransitionParameters(1, "A", act="x = 0"))
add_component!(machine, Transition(3, TransitionParameters("A", 2, order=1, cond="x == 0")))
push!(get_state(machine, "A").outports, 3); push!(get_node(machine, 2).inports, 3);
add_transition!(machine, TransitionParameters(2, "B"))
add_transition!(machine, TransitionParameters("B", "A", act="x = -1"))

@testset "Core Functions 1" begin
    @testset "Checking the addition of components" begin
        @test length(machine.states) == 2
        @test length(machine.nodes) == 2
        @test length(machine.transitions) == 5
    end

    @testset "Components `get` operation checking" begin
        state_A = get_state(machine, "A")
        state_B = get_state(machine, "B")
        test_states = [(state_A, "A", ([2, 5], [3]), ("x += 1;", "", "")), (state_B, "B", ([4], [5]), ("", "", "x += 1;"))]
        for (state, name, ports, actions) in test_states
            @test state.id == name
            @test state.inports == ports[1]
            @test state.outports == ports[2]
            @test state.actions.entry == actions[1]
            @test state.actions.during == actions[2]
            @test state.actions.exit == actions[3]
        end

        node_1 = get_node(machine, 1)
        node_2 = get_node(machine, 2)
        test_nodes = [(node_1, 1, ([1], [2])), (node_2, 2, ([3], [4]))]
        for (node, id, ports) in test_nodes
            @test node.id == id
            @test node.inports == ports[1]
            @test node.outports == ports[2]
        end

        tra_1 = get_transition(machine, 1)
        tra_2 = get_transition(machine, 2)
        tra_3 = get_transition(machine, 3)
        tra_4 = get_transition(machine, 4)
        tra_5 = get_transition(machine, 5)
        test_transitions = [
            (tra_1, 1, (nothing, 1), (1, "", "")), (tra_2, 2, (1, "A"), (1, "", "x = 0")), 
            (tra_3, 3, ("A", 2), (1, "x == 0", "")), (tra_4, 4, (2, "B"), (1, "", "")), 
            (tra_5, 5, ("B", "A"), (1, "", "x = -1")),
        ]
        for (tra, id, ports, values) in test_transitions
            @test tra.id == id
            @test tra.values.source == ports[1]
            @test tra.values.destination == ports[2]
            @test tra.values.order == values[1]
            @test tra.values.condition == values[2]
            @test tra.values.action == values[3]
        end
    end
end

empty!(machine)

@testset "Core Functions 2" begin
    @testset "Machine is empty" begin
        @test isempty(machine.states)
        @test isempty(machine.nodes)
        @test isempty(machine.transitions)
    end

    add_states!(machine, [StateParameters("A", en="x += 1;"), StateParameters("B", ex="x += 1;")])
    add_nodes!(machine, [NodeParameters(), NodeParameters()])
    add_transitions!(
        machine,
        [
            TransitionParameters(1),
            TransitionParameters(1, "A", act="x = 0"),
            TransitionParameters("A", 2, cond="x == 0"),
            TransitionParameters(2, "B"),
            TransitionParameters("B", "A", cond="x == 0", act="x = -1"),
        ] 
    )

    @testset "Checking the addition of components" begin
        @test length(machine.states) == 2
        @test length(machine.nodes) == 2
        @test length(machine.transitions) == 5
    end
end

empty!(machine)

@testset "Core Functions 3" begin
    add_states!(machine, [StateParameters("A", en="x += 1;"), StateParameters("B", ex="x += 1;")])
    add_transitions!(
        machine,
        [
            TransitionParameters("B"),
            TransitionParameters("A"),

            TransitionParameters("A", "B", act="1"),
            TransitionParameters("A", "B", act="2"),
            TransitionParameters("A", "B", act="3"),

            
            TransitionParameters("B", "A", act="1"),
            TransitionParameters("B", "A", act="2"),
        ] 
    )

    @test length(machine.transitions) == 7
    @testset "Checking Correct Connections" begin
        tra = get_transition(machine, 1)
        @test test_connection(tra, nothing, "B", 1)
        tra = get_transition(machine, 2)
        @test test_connection(tra, nothing, "A", 2)

        tra = get_transition(machine, 3)
        @test test_connection(tra, "A", "B", 1)
        tra = get_transition(machine, 4)
        @test test_connection(tra, "A", "B", 2)
        tra = get_transition(machine, 5)
        @test test_connection(tra, "A", "B", 3)

        tra = get_transition(machine, 6)
        @test test_connection(tra, "B", "A", 1)
        tra = get_transition(machine, 7)
        @test test_connection(tra, "B", "A", 2)
    end

    change_connection!(machine, 1, s="A", d="B")
    change_connection!(machine, 4, s="B", d="A")

    @test length(machine.transitions) == 7
    @testset "Checking Correct Reconnections" begin
        tra = get_transition(machine, 2)
        @test test_connection(tra, nothing, "A", 1)

        tra = get_transition(machine, 3)
        @test test_connection(tra, "A", "B", 1)
        tra = get_transition(machine, 5)
        @test test_connection(tra, "A", "B", 2)
        tra = get_transition(machine, 1)
        @test test_connection(tra, "A", "B", 3)
        state_A = get_state(machine, "A")
        @test length(state_A.outports) == 3
        @test !(4 in state_A.outports)

        tra = get_transition(machine, 6)
        @test test_connection(tra, "B", "A", 1)
        tra = get_transition(machine, 7)
        @test test_connection(tra, "B", "A", 2)
        tra = get_transition(machine, 4)
        @test test_connection(tra, "B", "A", 3)
        state_B = get_state(machine, "A")
        @test length(state_B.outports) == 3
    end

    add_states!(machine, [StateParameters("C"), StateParameters("D")])
    rm_states!(machine, ["A", "C"])
    add_nodes!(machine, [NodeParameters(), NodeParameters(), NodeParameters()])
    add_transition!(machine, TransitionParameters(1, 2))
    rm_node!(machine, 1)
    rm_transition!(machine, 8)
    rm_nodes!(machine, [2])
    rm_transitions!(machine, [1, 2, 3, 4, 5, 6, 7])
    rm_state!(machine, "B")
    @testset "Checking Removing Connections" begin
        @test length(machine.states) == 1
        @test get_state(machine, "D").id == "D"
        @test length(machine.nodes) == 1
        @test get_node(machine, 3).id == 3
        @test isempty(machine.transitions)
    end
end
