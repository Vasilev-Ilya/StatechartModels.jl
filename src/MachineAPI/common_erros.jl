#
# Сommon errors.
#

_throw_no_component(id::ComponentId, type::Symbol) = error("$type `$id` does not exist.")
throw_no_component(::Val{State}, id::String) = _throw_no_component(id, :State)
throw_no_component(::Val{Node}, id::Int) = _throw_no_component(id, :Node)
throw_no_component(::Val{Transition}, id::Int) = _throw_no_component(id, :Transition)

throw_duplicated_id(id::ComponentId) = error("A component with the name `$id` already exists.")