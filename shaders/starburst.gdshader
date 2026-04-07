/*
Starburst / impact flare — canvas_item 2D
Used for powerup collection and combo milestones
*/
shader_type canvas_item;
render_mode blend_add;

uniform vec4 flare_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform float ray_count = 8.0;
uniform float speed = 2.0;
uniform float lifespan = 1.0;  // set via set_shader_parameter each frame

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    float rays = pow(max(0.0, cos(angle * ray_count + TIME * speed)), 6.0);
    float ring = smoothstep(0.04, 0.0, abs(dist - 0.25)) * 0.6;
    float core = smoothstep(0.12, 0.0, dist);
    float value = (rays * (1.0 - dist * 1.8) + ring + core) * lifespan;
    COLOR = vec4(flare_color.rgb, value * flare_color.a);
}
