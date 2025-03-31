#
# Parser
#
module Parser
    using FiniteAutomaton.MachineAPI
    
    export parse_machine, PARSE_TREE, ParsedMachine

    include("types.jl")
    include("utility_functions.jl")
    include("machine_parser.jl")
end # module