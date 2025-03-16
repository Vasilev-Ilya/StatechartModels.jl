#
# Test MachineAPI
#
function test_connection(tra, s, d, order)
    return tra.values.source == s && tra.values.destination == d && tra.values.order == order
end

include("test_api_functions.jl")