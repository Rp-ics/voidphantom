shader_type canvas_item;

uniform sampler2D screen_tex : source_color; // prende la texture assegnata
uniform float distortion_strength = 0.05;
uniform float roll_speed = 5.0;
uniform float noise_opacity = 0.3;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    uv.y += sin(uv.x * 10.0 + TIME * roll_speed) * distortion_strength;
    uv.x += sin(uv.y * 6.0 + TIME * 2.0) * (distortion_strength * 0.5);

    // campiona la texture assegnata
    vec4 col = texture(screen_tex, uv);

    float noise = rand(uv * TIME * 10.0);
    col.rgb += noise * noise_opacity;

    COLOR = col;
}
