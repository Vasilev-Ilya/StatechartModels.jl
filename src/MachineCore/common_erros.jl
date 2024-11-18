#
# Сommon errors.
#

throw_no_state(name::String) = error("There is no state with the name `$name`.")
throw_no_node(n::Int) = error("Node `$n` does not exist.")
throw_no_transition(n::Int) = error("Transition `$n` does not exist.")
throw_duplicated_id(id::ComponentId) = error("A component with the name `$id` already exists.")