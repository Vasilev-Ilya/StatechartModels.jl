machine = Machine("test_machine")

add_state!(machine, "A", en="x += 1;"); add_component!(machine, State("B", [], [], ex="x += 1;"));
add_node!(machine); add_component!(machine, Node(2, [], []));
add_transition!(machine, 1)
add_transition!(machine, 1, "A", act="x = 0")
add_component!(machine, Transition(3, TransitionValues("A", 2, order=1, cond="x == 0")))
push!(get_state(machine, "A").outports, 3); push!(get_node(machine, 2).inports, 3);
add_transition!(machine, 2, "B")
add_transition!(machine, "B", "A", act="x = -1")

@testset "Core Functions" begin
    @testset "Checking the addition of components" begin
        @test length(machine.states) == 2
        @test length(machine.nodes) == 2
        @test length(machine.transitions) == 5
    end

    @testset "Components `get` operation checking" begin
        state_A = get_state(machine.states, "A")
        state_B = get_state(machine, "B")
        test_states = [(state_A, "A", ([2, 5], [3]), ("x += 1;", "", "")), (state_B, "B", ([4], [5]), ("", "", "x += 1;"))]
        for (state, name, ports, actions) in test_states
            @test state.id == name
            @test state.inports == ports[1]
            @test state.outports == ports[2]
            @test state.entry == actions[1]
            @test state.during == actions[2]
            @test state.exit == actions[3]
        end

        node_1 = get_node(machine.nodes, 1)
        node_2 = get_node(machine, 2)
        test_nodes = [(node_1, 1, ([1], [2])), (node_2, 2, ([3], [4]))]
        for (node, id, ports) in test_nodes
            @test node.id == id
            @test node.inports == ports[1]
            @test node.outports == ports[2]
        end

        tra_1 = get_transition(machine.transitions, 1)
        tra_2 = get_transition(machine.transitions, 2)
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