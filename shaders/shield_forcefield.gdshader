/*
2D Shield Forcefield - canvas_item adaptation for space shooter
Inspired by godotshaders.com/shader/bubble-forcefield
*/
shader_type canvas_item;

uniform vec4 shield_color : source_color = vec4(0.0, 0.7, 1.0, 1.0);
uniform float pulse_speed = 3.0;
uniform float edge_sharpness = 6.0;
uniform float hex_density = 12.0;

float hex_pattern(vec2 uv) {
    vec2 r = vec2(1.0, 1.732);
    vec2 h = r * 0.5;
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;
    float da = max(abs(a.x), abs(a.y) * 0.57735 + a.x * 0.5);
    float db = max(abs(b.x), abs(b.y) * 0.57735 + b.x * 0.5);
    return smoothstep(0.44, 0.46, min(da, db));
}

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float pulse = sin(TIME * pulse_speed) * 0.15 + 0.85;
    float rim = pow(dist * 2.0, edge_sharpness);
    float edge = smoothstep(0.45, 0.5, dist) * smoothstep(0.55, 0.5, dist);
    vec2 hex_uv = uv * hex_density;
    float hex = hex_pattern(hex_uv);
    float inner_glow = (1.0 - dist * 2.0) * 0.3;
    float alpha = (edge * 0.9 + hex * (1.0 - dist * 1.8) * 0.4 + inner_glow) * pulse;
    alpha = clamp(alpha, 0.0, 1.0) * shield_color.a;
    COLOR = vec4(shield_color.rgb, alpha);
}
