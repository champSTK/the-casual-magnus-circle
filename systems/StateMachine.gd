## StateMachine.gd
## Generic finite state machine. States are child Nodes implementing
## enter(), exit(), update(delta), physics_update(delta), handle_input(event).

extends Node

@export var initial_state: NodePath

var current_state:  Node       = null
var previous_state: Node       = null
var states:         Dictionary = {}

func _ready() -> void:
	for child: Node in get_children():
		if child.has_method("enter"):
			states[child.name] = child
			child.state_machine = self
			child.player        = get_parent()

	if initial_state:
		transition_to(get_node(initial_state).name)
	elif states.size() > 0:
		transition_to(states.keys()[0])

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func transition_to(state_name: String, data: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_warning("StateMachine: unknown state '%s'" % state_name)
		return
	if current_state:
		current_state.exit()
	previous_state = current_state
	current_state  = states[state_name]
	current_state.enter(data)

func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""
