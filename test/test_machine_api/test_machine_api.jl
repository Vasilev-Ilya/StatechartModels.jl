#
# Test MachineAPI
#
function test_connection(tra, s, d, order)
    return tra.source == s && tra.destination == d && tra.order == order
end

include("test_api_functions.jl")