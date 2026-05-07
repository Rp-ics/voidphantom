shader_type canvas_item;

// Progresso da 0 (intatto) a 1 (completamente frantumato)
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Punto di impatto (0..1), utile se vuoi ancora un centro di esplosione
uniform vec2 impact_point = vec2(0.5, 0.5);

// Quanto le direzioni dei cocci sono casuali:
// 0.0 -> tutte partono radialmente dal punto d'impatto
// 1.0 -> ogni coccio ha una direzione completamente casuale
// valori intermedi mischiano i due comportamenti
uniform float randomness : hint_range(0.0, 1.0) = 0.8;

// Colore/trasparenza delle fessure tra i cocci
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);

// Semi per variare la disposizione casuale
uniform float seed = 0.0;

// Numero di frammenti (max 30)
uniform int shard_count : hint_range(5, 30) = 18;

// Forza di spostamento dei cocci
uniform float displacement_strength : hint_range(0.0, 2.0) = 0.4;

// Spessore delle crepe (in coordinate UV)
uniform float crack_width : hint_range(0.0, 0.05) = 0.007;

// Oscuramento delle crepe (0 = invisibili, 1 = nere)
uniform float crack_darkness : hint_range(0.0, 1.0) = 0.65;

// Funzione hash pseudo-casuale (dipende da seed)
float hash(float p) {
	return fract(sin(p * 127.1 + seed) * 43758.5453);
}

void fragment() {
	const int MAX_SHARDS = 30;

	int nearest = 0;
	float min_dist = 1e10;
	float second_min_dist = 1e10;
	vec2 nearest_center = vec2(0.0);
	vec2 nearest_dir = vec2(0.0);

	for (int i = 0; i < MAX_SHARDS; i++) {
		if (i >= shard_count) break;

		// Centro casuale del coccio i-esimo
		float xi = hash(float(i) * 1.3);
		float yi = hash(float(i) * 2.7);
		vec2 center = vec2(xi, yi);

		float d = distance(UV, center);

		if (d < min_dist) {
			second_min_dist = min_dist;
			min_dist = d;
			nearest = i;
			nearest_center = center;

			// Calcolo della direzione di spostamento per questo coccio
			// 1. Direzione radiale dal punto d'impatto
			vec2 radial_dir = normalize(center - impact_point + 0.0001);
			// 2. Direzione completamente casuale
			float angle = hash(float(i) * 5.37) * 6.28318;
			vec2 random_dir = vec2(cos(angle), sin(angle));
			// Miscela in base a randomness
			nearest_dir = mix(radial_dir, random_dir, randomness);
		} else if (d < second_min_dist) {
			second_min_dist = d;
		}
	}

	// Spostamento del frammento
	vec2 offset = nearest_dir * progress * displacement_strength;
	vec2 sample_uv = UV + offset;

	// Colore del frammento (fuori dai bordi → sfondo)
	vec4 color;
	if (sample_uv.x < 0.0 || sample_uv.x > 1.0 ||
		sample_uv.y < 0.0 || sample_uv.y > 1.0) {
		color = background_color;
	} else {
		color = texture(TEXTURE, sample_uv);
	}

	// Linee di crepa sui bordi dei cocci (visibili quando progress > 0)
	if (progress > 0.0) {
		float edge = 1.0 - smoothstep(0.0, crack_width, second_min_dist - min_dist);
		float darken = mix(1.0, 1.0 - crack_darkness, edge);
		color.rgb *= darken;
	}

	COLOR = color;
}