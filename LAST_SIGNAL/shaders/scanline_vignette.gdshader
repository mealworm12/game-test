shader_type canvas_item;
render_mode blend_disabled;

uniform float scanline_count: hint_range(100.0, 1000.0) = 400.0;
uniform float scanline_strength: hint_range(0.0, 1.0) = 0.12;
uniform float vignette_strength: hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec2 uv = UV;
	
	// Scanlines
	float scanline = sin(uv.y * scanline_count) * 0.5 + 0.5;
	scanline = pow(scanline, 3.0);
	vec4 scan = vec4(0.0, 0.0, 0.0, (1.0 - scanline) * scanline_strength);
	
	// Vignette
	vec2 vignette_uv = uv * (1.0 - uv.yx);
	float vignette = vignette_uv.x * vignette_uv.y * 16.0;
	vignette = pow(vignette, vignette_strength);
	vec4 vig = vec4(0.0, 0.0, 0.0, (1.0 - vignette) * 0.6);
	
	COLOR = scan + vig;
}
