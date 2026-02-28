shader_type canvas_item;

// Glory kill-style glow tuned for pixel art.
// Hard two-tone pulse that preserves sprite detail and pixel edges.
uniform vec4 glow_color_a : source_color = vec4(1.0, 0.55, 0.1, 1.0); // Warm orange
uniform vec4 glow_color_b : source_color = vec4(1.0, 1.0, 0.7, 1.0); // Pale yellow-white
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.5;
uniform float brightness_boost : hint_range(1.0, 3.0) = 1.4;
uniform float mix_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (mix_amount > 0.0 && tex.a > 0.0) {
		// Hard step pulse: snaps between color A and B instead of smooth blend
		float raw_pulse = sin(TIME * pulse_speed);
		float pulse = step(0.0, raw_pulse); // 0 or 1, clean snap

		// Pick one of the two glow colors
		vec3 glow = mix(glow_color_a.rgb, glow_color_b.rgb, pulse);

		// Multiply-blend: tint the sprite while keeping its shading intact
		// This preserves dark pixels as dark and lights up bright pixels
		float strength = glow_strength * mix_amount;
		vec3 tinted = mix(tex.rgb, tex.rgb * glow * brightness_boost, strength);

		tex = vec4(tinted, tex.a);
	}

	COLOR = tex;
}
