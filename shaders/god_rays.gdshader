/*
God rays - adapted from godotshaders.com/shader/god-rays
canvas_item version for 2D space shooter background
*/
shader_type canvas_item;

uniform float angle = -0.3;
uniform float position = -0.2;
uniform float spread : hint_range(0.0, 1.0) = 0.5;
uniform float cutoff : hint_range(-1.0, 1.0) = 0.1;
uniform float falloff : hint_range(0.0, 1.0) = 0.2;
uniform float edge_fade : hint_range(0.0, 1.0) = 0.15;
uniform float speed = 1.0;
uniform float ray1_density = 8.0;
uniform float ray2_density = 30.0;
uniform float ray2_intensity : hint_range(0.0, 1.0) = 0.3;
uniform vec4 color : source_color = vec4(0.1, 0.3, 0.8, 0.15);
uniform float seed = 5.0;

float random(vec2 _uv) {
    return fract(sin(dot(_uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(in vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

mat2 rotate(float _angle) {
    return mat2(vec2(cos(_angle), -sin(_angle)), vec2(sin(_angle), cos(_angle)));
}

vec4 screen(vec4 base, vec4 blend) {
    return 1.0 - (1.0 - base) * (1.0 - blend);
}

void fragment() {
    vec2 transformed_uv = (rotate(angle) * (UV - vec2(0.5 + position, 0.5))) / ((UV.y + spread) - (UV.y * spread)) + 0.5;
    vec2 ray1 = vec2(transformed_uv.x * ray1_density + sin(TIME * 0.1 * speed) * (ray1_density * 0.2) + seed, 1.0);
    vec2 ray2 = vec2(transformed_uv.x * ray2_density + sin(TIME * 0.2 * speed) * (ray1_density * 0.2) + seed, 1.0);
    float cut = step(cutoff, transformed_uv.x) * step(cutoff, 1.0 - transformed_uv.x);
    float rays = clamp(noise(ray1) + (noise(ray2) * ray2_intensity), 0.0, 1.0);
    rays *= smoothstep(0.0, falloff, (1.0 - UV.y));
    rays *= smoothstep(0.0, edge_fade, transformed_uv.x);
    rays *= smoothstep(0.0, edge_fade, 1.0 - transformed_uv.x);
    rays *= cut;
    vec4 ray_color = vec4((vec3(1.0) - color.rgb) * rays, rays);
    COLOR = screen(color * cut, ray_color);
    COLOR.a = rays * color.a;
}
