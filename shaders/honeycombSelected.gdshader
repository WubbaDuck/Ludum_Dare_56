shader_type spatial;

const float amplitude = 0.5;
//const float frequency = 1.0;
const float speed = 5.0;
//const vec3 color = vec3(1, 0.1, 0.1);
const vec3 color = vec3(0.65, 0.2, 1.0);
const float alphaMin = 0.0;
const float alphaMax = 0.8;

render_mode blend_mix, depth_prepass_alpha, cull_back, unshaded;

void vertex() {
    // Calculate the sine wave for displacement
    float wave = abs(sin(TIME * speed));
    wave = pow(wave, 2.0) * sign(wave) * amplitude;
    
    // Displace the vertex along its normal
    VERTEX += NORMAL * max(wave, 0);
}

void fragment() {
		float wave = abs(sin(TIME * speed));
    wave = pow(wave, 2.0) * sign(wave) * amplitude;

    ALBEDO = color;
    ALPHA = mix(alphaMax, alphaMin, wave);
}