## Free-fly camera for exploring a set. Hold right mouse to look around.
extends Camera3D

var speed := 14.0
var _yaw := 0.0
var _pitch := 0.0
var _looking := false


func sync_from_transform() -> void:
	var e := global_transform.basis.get_euler()
	_pitch = e.x
	_yaw = e.y


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_looking = mb.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _looking else Input.MOUSE_MODE_VISIBLE
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			speed = minf(speed * 1.2, 200.0)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			speed = maxf(speed / 1.2, 1.0)
		return
	var mm := event as InputEventMouseMotion
	if mm and _looking:
		_yaw -= mm.relative.x * 0.003
		_pitch = clampf(_pitch - mm.relative.y * 0.003, -1.5, 1.5)
		rotation = Vector3(_pitch, _yaw, 0)


func _process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dir -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		dir += global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		dir -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		dir += global_transform.basis.x
	if Input.is_key_pressed(KEY_E):
		dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		dir -= Vector3.UP
	if dir != Vector3.ZERO:
		var mult := 4.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0
		global_position += dir.normalized() * speed * mult * delta
