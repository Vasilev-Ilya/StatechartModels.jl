machine = Machine("test_machine")

state!(machine, "A"); state!(machine, "B"); node!(machine); node!(machine);
transition!(machine, 1)
transition!(machine, 1, "A", act="x = 0")
transition!(machine, "A", 2, cond="x == 0")
transition!(machine, 2, "B")
transition!(machine, "B", "A", act="x = -1")

@testset "Core Functions" begin
    @testset "Checking the addition of components" begin
        @test length(machine.states) == 2
        @test length(machine.nodes) == 2
        @test length(machine.transitions) == 5
    end

    @testset "Components `get` operation checking" begin
        state_A = get_state(machine.states, "A")
        state_B = get_state(machine, "B")
        test_states = [(state_A, "A", ([2, 5], [3])), (state_B, "B", ([4], [5]))]
        for (state, name, ports) in test_states
            @test state.id == name
            @test state.inports == ports[1]
            @test state.outports == ports[2]
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
            @test tra.source == ports[1]
            @test tra.destination == ports[2]
            @test tra.values.order == values[1]
            @test tra.values.condition == values[2]
            @test tra.values.action == values[3]
        end
    end
end