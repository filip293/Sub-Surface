// FuzzyShell.gdshader
shader_type spatial;

// ADDED blend_mix to allow for proper transparency on the shell.
render_mode unshaded, cull_disabled, blend_mix;

// --- Uniforms ---
uniform vec4 fuzz_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float fuzz_ball_size : hint_range(0.01, 2.0) = 0.8;
uniform float density : hint_range(0.1, 20.0) = 8.0;
uniform float boil_speed : hint_range(0.1, 2.0) = 0.4;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.25;
uniform float shell_thickness : hint_range(0.0, 0.5, 0.001) = 0.03;
uniform float wobble_amount : hint_range(0.0, 0.2, 0.001) = 0.01;
uniform float wobble_speed : hint_range(0.1, 10.0) = 2.5;

varying vec3 local_vertex_pos;

// --- Noise Functions (Unchanged) ---
float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 worley(vec2 p) {
    vec2 n = floor(p); vec2 f = fract(p);
    float F1 = 8.0; float F2 = 8.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = vec2(random(n + g), random(n + g + vec2(5.2, 1.3)));
            vec2 o_offset = o * 0.5 + 0.5;
            float d = distance(g + o_offset, f);
            if (d < F1) { F2 = F1; F1 = d; } else if (d < F2) { F2 = d; }
        }
    }
    return vec2(F1, F2);
}

void vertex() {
    local_vertex_pos = VERTEX;
    float jitter = (random(VERTEX.xy + TIME * wobble_speed) * 2.0 - 1.0) * wobble_amount;
    VERTEX += NORMAL * (shell_thickness + jitter);
}

void fragment() {
    if (FRONT_FACING) {
        discard;
    } else {
        vec2 uv = local_vertex_pos.xy * density + TIME * boil_speed;
        float distortion = random(uv) * distortion_strength;
        uv += distortion;

        vec2 worley_noise = worley(uv);

        // --- THIS IS THE KEY CHANGE ---
        // Instead of a soft gradient (smoothstep), we use a hard cutoff (step).
        // This creates solid, non-transparent fuzzy balls, which is what you want.
        // It checks if the noise value is less than the ball size. If it is, the result is 1.0 (solid). If not, it's 0.0 (invisible).
        float ball = step(worley_noise.x, fuzz_ball_size);

        ALBEDO = fuzz_color.rgb;
        ALPHA = ball * fuzz_color.a;

        if (ALPHA < 0.1) {
            discard;
        }
    }
}