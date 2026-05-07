shader_type canvas_item;

uniform vec2 circle_pos = vec2(0.5, 0.5); // centro del cerchio in UV
uniform float circle_radius : hint_range(0.0, 1.0) = 0.3; // raggio del cerchio (0–1, in UV)
uniform float circle_softness : hint_range(0.0, 0.5) = 0.05; // sfumatura bordo
uniform vec4 dark_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // colore dello schermo scuro

void fragment() {
    // full-screen UV
    vec2 uv = SCREEN_UV;

    // Correggiamo l'aspect ratio per evitare ovali
    vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
    vec2 corrected_uv = (uv - circle_pos) * aspect;

    // Distanza radiale corretta
    float dist = length(corrected_uv);

    // Maschera circolare con bordo sfumato
    float mask = smoothstep(circle_radius, circle_radius - circle_softness, dist);

    // Invertiamo la maschera: il cerchio resta trasparente
    float inverse_mask = 1.0 - mask;

    // Applicazione del colore scuro
    COLOR = vec4(dark_color.rgb, dark_color.a * inverse_mask);
}
