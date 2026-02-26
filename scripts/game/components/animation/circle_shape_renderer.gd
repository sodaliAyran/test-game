class_name CircleShapeRenderer
extends RefCounted

## Renders a circle wind-up indicator with outer boundary and growing inner fill.
## Used by WindupIndicatorComponent for circle-shaped attack indicators.

var radius: float


static func create(p_radius: float) -> CircleShapeRenderer:
	var renderer = CircleShapeRenderer.new()
	renderer.radius = p_radius
	return renderer


func draw(canvas: CanvasItem, progress: float, outer_color: Color, inner_color: Color) -> void:
	# Draw outer circle (attack area boundary)
	canvas.draw_circle(Vector2.ZERO, radius, outer_color)
	canvas.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, outer_color.lightened(0.3), 2.0)

	# Draw inner circle (grows with progress)
	if progress > 0.0:
		var inner_radius = radius * progress
		canvas.draw_circle(Vector2.ZERO, inner_radius, inner_color)
		canvas.draw_arc(Vector2.ZERO, inner_radius, 0, TAU, 32, inner_color.lightened(0.3), 2.0)
