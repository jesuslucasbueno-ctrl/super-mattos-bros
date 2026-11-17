shader_type canvas_item;
render_mode unshaded;

uniform bool ativo = false;
uniform vec4 cor_neon : source_color = vec4(1.0, 0.02, 0.04, 1.0);
// Normalized bounds of the current atlas frame, excluding neighboring frames.
uniform vec4 frame_uv = vec4(0.0, 0.0, 1.0, 1.0);
varying vec4 modulate_color;

void vertex() {
    modulate_color = COLOR;
}

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    float outline = 0.0;
    float halo = 0.0;
    vec2 inset = TEXTURE_PIXEL_SIZE * 0.5;
    vec2 lower = frame_uv.xy + inset;
    vec2 upper = frame_uv.xy + frame_uv.zw - inset;
    if (ativo) {
        for (int y = -3; y <= 3; y++) {
            for (int x = -3; x <= 3; x++) {
                float distance_px = length(vec2(float(x), float(y)));
                if (distance_px > 0.0 && distance_px <= 3.0) {
                    vec2 sample_uv = UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE;
                    float a = 0.0;
                    if (all(greaterThanEqual(sample_uv, lower)) && all(lessThanEqual(sample_uv, upper))) {
                        a = texture(TEXTURE, sample_uv).a;
                    }
                    if (distance_px <= 1.5) {
                        outline = max(outline, a);
                    }
                    halo = max(halo, a * (1.0 - distance_px / 4.0) * 0.45);
                }
            }
        }
    }
    float effect_alpha = max(outline, halo) * cor_neon.a * (1.0 - base.a);
    // Only this overlay ignores lighting; the cherry itself remains shaded.
    COLOR = vec4(cor_neon.rgb, effect_alpha) * modulate_color;
}
