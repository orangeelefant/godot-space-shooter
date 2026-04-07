/*
Procedural Electric Arc - canvas_item shader for 2D space shooter
*/
shader_type canvas_item;
render_mode blend_add;

uniform vec4 arc_color : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform float speed = 4.0;
uniform float intensity = 2.0;
uniform float arc_count = 3.0;

float random(vec2 seed) {
    return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float t = TIME * speed;
    float arc = 0.0;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float t2 = floor(t + fi * 0.37);
        float center = 0.5 + (random(vec2(uv.y * 6.0 + fi, t2)) - 0.5) * 0.5;
        float branch = random(vec2(fi * 2.0, t2 + 0.5)) * 0.15;
        float w = 0.015 + random(vec2(fi, t2)) * 0.01;
        arc += smoothstep(w, 0.0, abs(uv.x - center - sin(uv.y * 20.0 + t) * branch));
    }
    float fade_y = sin(uv.y * PI);
    float flicker = 0.7 + sin(t * 11.0) * 0.3;
    COLOR = vec4(arc_color.rgb * arc * intensity * flicker, arc * fade_y * arc_color.a);
}
