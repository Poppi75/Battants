shader_type canvas_item;

uniform bool cloak_active = false;

// REQUIRED in Godot 4
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float distortion_strength : hint_range(0.0, 0.4) = 0.1;
uniform float visibility : hint_range(0.0, 1.0) = 0.5;
uniform float noise_scale = 50.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec4 final_color = tex;

    if (cloak_active) {
        // --- Distortion ---
        float wave = sin(UV.y * noise_scale + TIME * 5.0) * 0.01;
        vec2 offset = vec2(
            wave,
            cos(UV.x * noise_scale + TIME * 5.0) * 0.01
        );

        offset *= distortion_strength * 50.0;

        // --- Sample screen ---
        vec2 screen_uv = SCREEN_UV + offset;
        vec4 screen_color = texture(SCREEN_TEXTURE, screen_uv);

        // --- Blend ---
        float alpha = tex.a;
        vec4 cloaked = mix(screen_color, tex, visibility);

        cloaked.a = alpha * 0.3;

        final_color = cloaked;
    }

    COLOR = final_color;
}