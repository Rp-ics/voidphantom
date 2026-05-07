shader_type canvas_item;

// Controllo principale: 0 = nessuna rottura, 1 = massima frantumazione
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Punto da cui partono le crepe (in coordinate UV, 0..1)
uniform vec2 impact_point = vec2(0.5, 0.5);

// Colore/trasparenza delle fessure tra i cocci
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);

// Semi per randomizzare la distribuzione dei frantumi
uniform float seed = 0.0;

// Numero di cocci (modifica secondo necessità, massimo 30)
uniform int shard_count : hint_range(5, 30) = 15;

// Quanto si allontanano i frammenti (moltiplica progress)
uniform float displacement_strength : hint_range(0.0, 2.0) = 0.35;

// Spessore delle linee di crepa (in UV)
uniform float crack_width : hint_range(0.0, 0.05) = 0.008;

// Oscuramento delle crepe (0 = invisibili, 1 = nere)
uniform float crack_darkness : hint_range(0.0, 1.0) = 0.7;

// Funzione hash pseudo-casuale
float hash(float p) {
	return fract(sin(p * 127.1 + seed) * 43758.5453);
}

void fragment() {
	const int MAX_SHARDS = 30;

	int nearest = 0;
	float min_dist = 1e10;
	float second_min_dist = 1e10;
	vec2 nearest_center = vec2(0.0);

	// Trova il coccio più vicino (e il secondo più vicino)
	for (int i = 0; i < MAX_SHARDS; i++) {
		if (i >= shard_count) break;

		// Posizione casuale del centro del coccio i-esimo
		float xi = hash(float(i) * 1.3);
		float yi = hash(float(i) * 2.7);
		vec2 center = vec2(xi, yi);

		float d = distance(UV, center);

		if (d < min_dist) {
			second_min_dist = min_dist;
			min_dist = d;
			nearest = i;
			nearest_center = center;
		} else if (d < second_min_dist) {
			second_min_dist = d;
		}
	}

	// Direzione di allontanamento dal punto d'impatto
	vec2 dir = normalize(nearest_center - impact_point + 0.0001);
	vec2 offset = dir * progress * displacement_strength;
	vec2 sample_uv = UV + offset;

	// Colore di base (frammento spostato)
	vec4 color;
	if (sample_uv.x < 0.0 || sample_uv.x > 1.0 ||
		sample_uv.y < 0.0 || sample_uv.y > 1.0) {
		// Fuori dalla texture → sfondo
		color = background_color;
	} else {
		color = texture(TEXTURE, sample_uv);
	}

	// Disegna le crepe sui bordi quando progress > 0
	if (progress > 0.0) {
		float edge = 1.0 - smoothstep(0.0, crack_width, second_min_dist - min_dist);
		float darken = mix(1.0, 1.0 - crack_darkness, edge);
		color.rgb *= darken;
	}

	COLOR = color;
}