extends Node
class_name ExecutionCameraManager

## God of War-style execution camera effect for stomp moments.
## Manages slow-mo, camera zoom, and screen shake using real-time tracking.
## Usage: ExecutionCamera.play(focus_position)

signal execution_started
signal execution_finished

@export_group("Timing (real-time seconds)")
@export var zoom_in_duration: float = 0.15
@export var hold_duration: float = 0.30
@export var zoom_out_duration: float = 0.25
@export var slow_mo_time_scale: float = 0.03

@export_group("Zoom")
@export var zoom_amount: Vector2 = Vector2(1.4, 1.4)

@export_group("Shake")
@export var shake_intensity: float = 3.0
@export var shake_decay: float = 4.0

enum Phase { INACTIVE, ZOOM_IN, HOLD, ZOOM_OUT }

var _phase: int = Phase.INACTIVE
var _phase_start_time: int = 0
var _camera: Camera2D = null
var _original_zoom: Vector2 = Vector2.ONE
var _original_offset: Vector2 = Vector2.ZERO
var _focus_offset: Vector2 = Vector2.ZERO
var _shake_start_time: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _phase == Phase.INACTIVE:
		return

	if not is_instance_valid(_camera):
		_abort()
		return

	var now = Time.get_ticks_msec()

	match _phase:
		Phase.ZOOM_IN:
			var t = _get_phase_progress(now, zoom_in_duration)
			var eased = ease(t, 0.3) # ease-out: fast start, gentle arrival
			_camera.zoom = _original_zoom.lerp(zoom_amount, eased)
			_camera.offset = _original_offset.lerp(_original_offset + _focus_offset, eased)
			_apply_shake(now)
			if t >= 1.0:
				_start_phase(Phase.HOLD, now)

		Phase.HOLD:
			var t = _get_phase_progress(now, hold_duration)
			_apply_shake(now)
			if t >= 1.0:
				_start_phase(Phase.ZOOM_OUT, now)

		Phase.ZOOM_OUT:
			var t = _get_phase_progress(now, zoom_out_duration)
			var eased = ease(t, 2.0) # ease-in: slow start, accelerating
			_camera.zoom = zoom_amount.lerp(_original_zoom, eased)
			_camera.offset = (_original_offset + _focus_offset).lerp(_original_offset, eased)
			Engine.time_scale = lerpf(slow_mo_time_scale, 1.0, eased)
			_apply_shake(now)
			if t >= 1.0:
				_finish()


func play(focus_position: Vector2) -> void:
	if _phase != Phase.INACTIVE:
		return

	_camera = get_viewport().get_camera_2d()
	if not _camera:
		return

	# Cancel any active FreezeFrame so we own time_scale
	FreezeFrame.cancel()

	_original_zoom = _camera.zoom
	_original_offset = _camera.offset

	# Calculate offset to shift view toward focus point
	var camera_center = _camera.get_screen_center_position()
	var diff = focus_position - camera_center
	_focus_offset = diff * 0.3 # Shift 30% toward focus, not fully centered

	# Start the sequence
	Engine.time_scale = slow_mo_time_scale
	_shake_start_time = Time.get_ticks_msec()
	_start_phase(Phase.ZOOM_IN, Time.get_ticks_msec())
	execution_started.emit()


func is_playing() -> bool:
	return _phase != Phase.INACTIVE


func _start_phase(phase: int, now: int) -> void:
	_phase = phase
	_phase_start_time = now


func _get_phase_progress(now: int, duration: float) -> float:
	var elapsed = (now - _phase_start_time) / 1000.0
	return clampf(elapsed / duration, 0.0, 1.0)


func _apply_shake(now: int) -> void:
	var shake_elapsed = (now - _shake_start_time) / 1000.0
	var current_intensity = shake_intensity * exp(-shake_decay * shake_elapsed)
	if current_intensity < 0.1:
		return
	var shake_offset = Vector2(
		randf_range(-current_intensity, current_intensity),
		randf_range(-current_intensity, current_intensity)
	)
	_camera.offset += shake_offset


func _finish() -> void:
	if is_instance_valid(_camera):
		_camera.zoom = _original_zoom
		_camera.offset = _original_offset
	Engine.time_scale = 1.0
	_phase = Phase.INACTIVE
	_camera = null
	execution_finished.emit()


func _abort() -> void:
	Engine.time_scale = 1.0
	_phase = Phase.INACTIVE
	_camera = null
