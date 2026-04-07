/*
Slash arc effect — 2D canvas_item procedural
Inspired by procedural cyclic slash concept
*/
shader_type canvas_item;
render_mode blend_add;

uniform vec4 slash_color : source_color = vec4(0.8, 0.3, 1.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float arc_width = 0.08;
uniform float rotation_offset = 0.0;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x) + rotation_offset;
    // Arc band at radius ~0.4, spanning ~120 degrees
    float arc_radius = 0.35 * progress;
    float radial = smoothstep(arc_width, 0.0, abs(dist - arc_radius));
    float angular_mask = smoothstep(-1.1, -0.8, angle) * smoothstep(0.5, 0.2, angle);
    float core = radial * angular_mask;
    float glow = smoothstep(arc_width * 2.5, 0.0, abs(dist - arc_radius)) * angular_mask * 0.4;
    float alpha = (core + glow) * progress;
    COLOR = vec4(slash_color.rgb, alpha * slash_color.a);
}
