/*
Starburst / combo burst effect — 2D canvas_item procedural
*/
shader_type canvas_item;
render_mode blend_add;

uniform vec4 flare_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float ray_count : hint_range(4.0, 20.0) = 8.0;
uniform float lifespan : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Radial rays
    float ray = abs(sin(angle * ray_count * 0.5));
    ray = pow(ray, 3.0);

    // Falloff from center
    float radial_fade = 1.0 - smoothstep(0.0, 0.5, dist);
    float ring = smoothstep(0.45, 0.35, dist) * smoothstep(0.1, 0.2, dist);

    float intensity = (ray * radial_fade + ring * 0.4) * lifespan;
    float alpha = intensity * flare_color.a;
    COLOR = vec4(flare_color.rgb, alpha);
}
