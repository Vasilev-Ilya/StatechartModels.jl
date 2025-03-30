module MachineCompiler

    export parse_machine, PARSE_TREE, ParsedMachine
    
    include("Validator/Validator.jl")
    using .Validator
    include("Parser/Parser.jl")
    using .Parser
    include("CodeGenerator/CodeGenerator.jl")
    using .CodeGenerator
end # module