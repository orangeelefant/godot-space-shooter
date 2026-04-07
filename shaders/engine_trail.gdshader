/*
Engine trail / exhaust glow for player ship - 2D canvas_item
*/
shader_type canvas_item;
render_mode blend_add;

uniform vec4 trail_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.6, 0.9, 1.0, 1.0);
uniform float speed = 3.0;
uniform float flicker_speed = 9.0;
uniform float length_scale = 1.0;

void fragment() {
    vec2 uv = UV;
    // uv.x=0 is the back of the trail, uv.x=1 is toward the ship
    float trail = pow(1.0 - uv.x, 1.5) * length_scale;
    float center = smoothstep(0.18, 0.0, abs(uv.y - 0.5));
    float outer = smoothstep(0.42, 0.0, abs(uv.y - 0.5));
    float flicker = 0.75 + sin(TIME * flicker_speed + uv.x * 8.0) * 0.25;
    float noise = sin(uv.x * 15.0 - TIME * speed) * 0.5 + 0.5;
    float core = center * trail * flicker;
    float glow = outer * trail * 0.4 * noise;
    vec3 col = mix(trail_color.rgb, core_color.rgb, core);
    COLOR = vec4(col, (core + glow) * trail_color.a);
}
