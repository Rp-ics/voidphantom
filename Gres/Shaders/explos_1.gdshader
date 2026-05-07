shader_type canvas_item;

// Parametri controllabili
uniform float progress : hint_range(0, 1) = 0.0;
uniform int fragments_x = 16;
uniform int fragments_y = 16;
uniform float explosion_power = 2.0;
uniform float rotation_power = 1.0;
uniform float gravity = 0.5;
uniform vec2 center = vec2(0.5, 0.5);

// Texture per effetti aggiuntivi
uniform sampler2D noise_texture;

void fragment() {
    // Calcola le dimensioni di ogni frammento
    vec2 fragment_size = vec2(1.0 / float(fragments_x), 1.0 / float(fragments_y));

    // Identifica il frammento corrente
    vec2 fragment_uv = floor(UV / fragment_size) * fragment_size;
    vec2 local_uv = (UV - fragment_uv) / fragment_size;

    // Centro del frammento
    vec2 fragment_center = fragment_size * 0.5 + fragment_uv;

    // Direzione dell'esplosione dal centro
    vec2 explosion_dir = normalize(fragment_center - center);

    // Distanza dal centro dell'esplosione
    float distance_from_center = distance(fragment_center, center);

    // Applica rumore per variabilità
    float noise = texture(noise_texture, fragment_uv).r * 2.0 - 1.0;

    // Calcola lo spostamento del frammento
    vec2 displacement = explosion_dir * explosion_power * progress * distance_from_center;

    // Aggiungi effetto gravità
    displacement.y += gravity * progress * progress;

    // Calcola la rotazione
    float rotation = progress * rotation_power * (noise + 0.5) * 6.28;

    // Applica rotazione alle coordinate UV locali
    vec2 rotated_uv = local_uv - vec2(0.5);
    rotated_uv = vec2(
        rotated_uv.x * cos(rotation) - rotated_uv.y * sin(rotation),
        rotated_uv.x * sin(rotation) + rotated_uv.y * cos(rotation)
    );
    rotated_uv += vec2(0.5);

    // Calcola le UV finali con lo spostamento
    vec2 final_uv = fragment_uv + rotated_uv * fragment_size;

    // Leggi il colore dalla texture originale
    vec4 color = texture(TEXTURE, final_uv);

    // Dissolvenza in base al progresso
    color.a *= (1.0 - progress * 0.8);

    COLOR = color;
}