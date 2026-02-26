class_name LineShapeRenderer
extends RefCounted

## Renders a line wind-up indicator as a thin flashing line that goes solid near the end.
## Used by WindupIndicatorComponent for directional/dash attack indicators.
## The indicator is drawn from Vector2.ZERO toward direction * length.

var direction: Vector2  ## Normalized direction of the line
var length: float       ## Full length of the dash/attack
var width: float = 4.0  ## Width of the indicator

const FLASH_CYCLES: float = 4.0  ## Number of flash cycles during windup
const SOLID_THRESHOLD: float = 0.8  ## Progress at which line goes fully solid


static func create(p_direction: Vector2, p_length: float, p_width: float = 4.0) -> LineShapeRenderer:
	var renderer = LineShapeRenderer.new()
	renderer.direction = p_direction.normalized()
	renderer.length = p_length
	renderer.width = p_width
	return renderer


func draw(canvas: CanvasItem, progress: float, _outer_color: Color, inner_color: Color) -> void:
	var end_point = direction * length

	var alpha: float
	if progress >= SOLID_THRESHOLD:
		# Final phase: solid red
		alpha = 0.9
	else:
		# Flashing phase: oscillate alpha using progress
		var flash = sin(progress * FLASH_CYCLES * TAU)
		alpha = remap(flash, -1.0, 1.0, 0.15, 0.5)

	var color = Color(inner_color.r, inner_color.g, inner_color.b, alpha)
	canvas.draw_line(Vector2.ZERO, end_point, color, width)
