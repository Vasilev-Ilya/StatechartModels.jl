#
# Сommon errors.
#

throw_no_state(name::String) = error("There is no state with the name `$name`.")
throw_no_node(n::Int) = error("Node `$n` does not exist.")