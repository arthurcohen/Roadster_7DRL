shader_type spatial;

uniform vec2 uv_scale;
uniform sampler2D environment_map;

uniform vec3 fields_albedo : source_color;
uniform vec3 desert_albedo : source_color;
uniform vec3 mountain_albedo : source_color;

const int FIELDS = 0;
const int DESERT = 1;
const int MOUNTAIN = 2;

int get_biome(vec3 environment_data) {
	float temperature = environment_data.r;
	float altitude = environment_data.g;
	float humidity = environment_data.b;
	
	if (humidity < 0.6 && altitude < 0.5 && temperature > 0.6) {
		return DESERT;
	}
	
	if (false) {
		return MOUNTAIN;
	}	
	
	return FIELDS;
}


void fragment() {	
	vec3 environment_data = textureLod(environment_map, UV * uv_scale, 0.0).rgb;
	
	int biome = get_biome(environment_data);
	
	if (biome == MOUNTAIN) {
		ALBEDO = mountain_albedo;
	} else if (biome == DESERT) {
		ALBEDO = desert_albedo;
	} else if (biome == FIELDS){
		ALBEDO = fields_albedo;
	}
}
