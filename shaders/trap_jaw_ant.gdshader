shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

// 0 = fully normal (visible), 1 = fully cloaked
uniform float cloak_progress : hint_range(0.0, 1.0) = 0.0;

uniform float distortion = 0.02;
uniform float speed = 1.5;
uniform float opacity = 0.06;

// Chunk controls
uniform float chunk_scale = 28.0;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.03;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x)
		+ (c - a) * u.y * (1.0 - u.x)
		+ (d - b) * u.x * u.y;
}

void fragment() {
	// Sprite sample
	vec4 sprite_col = texture(TEXTURE, UV);
	float mask = sprite_col.a;

	// Cloak sample (screen distortion)
	vec2 n_uv = UV * 8.0 + TIME * speed;
	float n1 = noise(n_uv);
	float n2 = noise(n_uv + 5.2);
	vec2 offset = (vec2(n1, n2) - 0.5) * distortion;

	vec4 cloak_col = textureLod(screen_texture, SCREEN_UV + offset, 0.0);

	// Cloak alpha only where sprite exists
	cloak_col.a = mask * opacity;

	// --- Chunky piece mask (0..1) ---
	vec2 cell = floor(UV * chunk_scale);
	float r = hash(cell);

	float t0 = cloak_progress - edge_softness;
	float t1 = cloak_progress + edge_softness;
	float piece_mask = smoothstep(r - edge_softness, r + edge_softness, cloak_progress) * mask;

	// --- Prevent RGB bleed (premultiply, mix, unpremultiply) ---
	vec4 A = vec4(sprite_col.rgb * sprite_col.a, sprite_col.a);
	vec4 B = vec4(cloak_col.rgb * cloak_col.a, cloak_col.a);

	vec4 out_pm = mix(A, B, piece_mask);

	// Unpremultiply safely
	vec3 out_rgb = (out_pm.a > 0.0001) ? (out_pm.rgb / out_pm.a) : vec3(0.0);

	// Use the blended alpha (not the original mask)
	COLOR = vec4(out_rgb, out_pm.a);
}