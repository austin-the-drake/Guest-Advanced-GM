varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// --- Uniforms ---
uniform vec4 OriginalSize; // [W, H, 1/W, 1/H]
uniform int FrameCount;
uniform float inter;       // Trigger Resolution (e.g., 375.0)
uniform float interm;      // Interlace Mode (0=Off, 1-3=Normal, 4-5=Interp)
uniform float iscan;       // Scanline Effect Strength
uniform float intres;      // Internal Resolution Y
uniform float iscans;      // Interlacing Saturation
uniform float hiscan;      // High-Res Scanline override

// Source is gm_BaseTexture (PrePass0)

vec3 plant(vec3 tar, float r)
{
    float t = max(max(tar.r, tar.g), tar.b) + 0.00001;
    return tar * r / t;
}

void main()
{
    // Sample current pixel and the pixel one source-line below
    vec3 c1 = texture2D(gm_BaseTexture, v_vTexcoord).rgb;
    vec3 c2 = texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, OriginalSize.w)).rgb;
    
    vec3 c = c1;
    float intera = 1.0; // Default: No interlacing active

    float m1 = max(max(c1.r, c1.g), c1.b);
    float m2 = max(max(c2.r, c2.g), c2.b);
    vec3 df = abs(c1 - c2);
    float d = max(max(df.r, df.g), df.b);

    // Mode 2: Adaptive contrast boost for detection
    if (abs(interm - 2.0) < 0.1) {
        d = mix(0.1 * d, 10.0 * d, step(m1 / (m2 + 0.00001), m2 / (m1 + 0.00001)));
    }

    float r = m1;
    
    float yres_div = 1.0;
    if (intres > 1.25) yres_div = intres;

    bool hscan_bool = (hiscan > 0.5);

    // Check if Interlacing logic should trigger
    // Triggers if Source Height <= trigger threshold (divided by intres scaling)
    if ((inter <= OriginalSize.y / yres_div && interm > 0.5 && abs(intres - 1.0) > 0.1 && abs(intres - 0.5) > 0.1) || hscan_bool) 
    {
        intera = 0.25; // Flag downstream that interlacing is Active
        
        float line_no = floor(mod(OriginalSize.y * v_vTexcoord.y, 2.0));
        float frame_no = floor(mod(float(FrameCount), 2.0));
        float ii = abs(line_no - frame_no); // 0 or 1 based on odd/even field

        // Modes 1, 2, 3, 6 (Standard Interlacing)
        if (interm < 3.5 || interm > 5.5)
        {
            if (abs(interm - 6.0) < 0.1) {
                c = mix(c2, c1, ii);
            }
            else
            {
                vec3 c2_processed = plant(mix(c2, c2 * c2, iscans), max(max(c2.r, c2.g), c2.b));
                r = max(m1 * ii, (1.0 - iscan) * min(m1, m2));
                
                float mix_factor = min(mix(m1, 1.0 - m2, min(m1, 1.0 - m1)) / (d + 0.00001), 1.0);
                vec3 mixed_c = mix(mix(c1, c2_processed, mix_factor), c1, ii); // Original slang logic for c2 mixed usage here implies recursive calc, but 'plant' is color saturation.
                // Re-reading slang logic carefully:
                // c2 = plant(...); 
                // c = plant( mix(mix(c1,c2, ... ), c1, ii), r);
                
                // Implemented:
                c2 = plant(mix(c2, c2 * c2, iscans), max(max(c2.r, c2.g), c2.b));
                c = plant(mix(mix(c1, c2, mix_factor), c1, ii), r);

                if (abs(interm - 3.0) < 0.1) {
                    c = (1.0 - 0.5 * iscan) * mix(c2, c1, ii);
                }
            }
        }

        // Mode 4: Interpolation
        if (abs(interm - 4.0) < 0.1) {
            c = plant(mix(c, c * c, 0.5 * iscans), max(max(c.r, c.g), c.b)) * (1.0 - 0.5 * iscan);
        }

        // Mode 5: Interpolation Mix
        if (abs(interm - 5.0) < 0.1) {
            c = mix(c2, c1, 0.5);
            c = plant(mix(c, c * c, 0.5 * iscans), max(max(c.r, c.g), c.b)) * (1.0 - 0.5 * iscan);
        }
        
        if (hscan_bool) c = c1;
    }

    gl_FragColor = vec4(c, intera);
}