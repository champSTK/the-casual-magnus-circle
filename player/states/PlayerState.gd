## PlayerState.gd
## Base class for all player states. Every state script extends this.
## Provides empty default implementations so states only override what they need.

extends Node
class_name PlayerState

# Set by StateMachine._ready()
var state_machine: Node = null
var player: CharacterBody2D = null

# ── Interface ─────────────────────────────────────────────────
func enter(_data: Dictionary = {}) -> void:
	pass   # called when entering this state

func exit() -> void:
	pass   # called when leaving this state

func update(_delta: float) -> void:
	pass   # called every _process frame

func physics_update(_delta: float) -> void:
	pass   # called every _physics_process frame

func handle_input(_event: InputEvent) -> void:
	pass   # called for unhandled input events
