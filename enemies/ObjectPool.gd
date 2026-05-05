extends Node

# 🔥 CONFIG
const BASE_POOL_SIZE := 10
const EXPAND_SIZE    := 5

var pools := {}    # scene → pooled objects
var active := {}   # scene → active objects


# ── GET OBJECT ─────────────────────────
func get_object(scene: PackedScene):
	# first time setup
	if not pools.has(scene):
		pools[scene] = []
		active[scene] = []
		_prewarm(scene, BASE_POOL_SIZE)

	var pool = pools[scene]
	var obj

	# 🔥 if pool empty → expand
	if pool.size() == 0:
		print("⚠️ Pool exhausted for:", scene.resource_path.get_file(), "→ expanding by", EXPAND_SIZE)
		_expand(scene, EXPAND_SIZE)

	# now guaranteed to have object
	obj = pool.pop_back()
	active[scene].append(obj)

	return obj


# ── RETURN OBJECT ──────────────────────
func return_object(scene: PackedScene, obj):
	obj.visible = false
	obj.set_physics_process(false)

	if obj.has_method("on_pool_return"):
		obj.on_pool_return()

	active[scene].erase(obj)
	pools[scene].append(obj)


# ── INTERNAL: PREWARM ──────────────────
func _prewarm(scene: PackedScene, count: int):
	for i in range(count):
		var obj = scene.instantiate()
		add_child(obj)

		obj.visible = false

		if obj.has_method("on_pool_return"):
			obj.on_pool_return()

		pools[scene].append(obj)


# ── INTERNAL: EXPAND ───────────────────
func _expand(scene: PackedScene, count: int):
	for i in range(count):
		var obj = scene.instantiate()
		add_child(obj)

		obj.visible = false

		if obj.has_method("on_pool_return"):
			obj.on_pool_return()

		pools[scene].append(obj)
