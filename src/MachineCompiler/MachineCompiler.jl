module MachineCompiler

    const INIT_STATE_NAME = "__INIT__"

    include("Validator/Validator.jl")
    using .Validator
    include("Parser/Parser.jl")
    using .Parser
    include("CodeGenerator/CodeGenerator.jl")
    using .CodeGenerator
end # module