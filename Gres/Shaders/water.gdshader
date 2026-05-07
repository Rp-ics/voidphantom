shader_type canvas_item;

uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_strength : hint_range(0.0, 0.1) = 0.02;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.015;
uniform vec3 water_tint : source_color = vec3(0.1, 0.17, 0.14);
uniform float tint_power : hint_range(0.0, 1.0) = 0.6;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// Blending
uniform int blend_mode : hint_range(0, 4) = 0;
uniform float alpha_override : hint_range(0.0, 1.0) = 1.0;


// Funzione blend
vec3 blend_modes(vec3 base, vec3 blend, int mode) {
    if (mode == 0) return mix(base, blend, 0.5);               // MIX
    if (mode == 1) return base + blend;                        // ADD
    if (mode == 2) return base * blend;                        // MULTIPLY
    if (mode == 3) return 1.0 - (1.0 - base)*(1.0 - blend);    // SCREEN
    if (mode == 4) return mix(
        2.0 * base * blend,
        1.0 - 2.0 * (1.0 - base)*(1.0 - blend),
        step(0.5, base)
    );                                                        // OVERLAY
    return base;
}

void fragment() {
    vec2 uv = SCREEN_UV;

    float t = TIME * wave_speed;

    // --- WAVE (LEGGERISSIMO) ---
    float wave1 = sin(uv.y * 18.0 + t * 1.2);
    float wave2 = cos(uv.x * 22.0 + t * 0.8);
    float wave3 = sin((uv.x + uv.y) * 12.0 + t * 1.5);

    float wave_combined = (wave1 + wave2 + wave3) * 0.33;

    // --- DISTORSIONE ACQUA ---
    vec2 distortion = vec2(
        wave_combined * distortion_strength,
        wave2 * wave_strength
    );

    vec3 base_col = texture(screen_texture, uv + distortion).rgb;

    // Tint acqua
    vec3 tinted = mix(base_col, water_tint, tint_power);

    // Piccolo highlight morbido
    float highlight = pow(max(wave_combined, 0.0), 2.0);
    vec3 fx_col = tinted + highlight * 0.15;

    // Blend finale
    vec3 final = blend_modes(tinted, fx_col, blend_mode);

    final = clamp(final, 0.0, 1.0);

    float alpha = texture(TEXTURE, UV).a * alpha_override;

    COLOR = vec4(final, alpha);
}
