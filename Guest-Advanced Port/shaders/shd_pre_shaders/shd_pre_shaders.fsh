varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// --- Uniforms ---
uniform vec4 OriginalSize; // [w, h, 1/w, 1/h]
uniform float TNTC;   // LUT Selection (0=Off, 1=Trinitron, 2=Inv, 3=NEC, 4=NTSC)
uniform float LS;     // LUT Size (32.0 or 64.0)
uniform float LUTLOW; // LUT Dark Range
uniform float LUTBR;  // LUT Brightness
uniform float WP;     // White Point (Color Temp)
uniform float wp_saturation; // Saturation
uniform float BP;     // Black Level
uniform float vigstr; // Vignette Strength
uniform float vigdef; // Vignette Size
uniform float sega_fix; // Sega Brightness Fix
uniform float pre_bb; // Brightness Boost
uniform float contr;  // Contrast
uniform float pre_gc; // Gamma Correction
uniform float AS;     // Afterglow Strength
uniform float agsat;  // Afterglow Saturation
uniform float CP;     // CRT Profile (EBU, P22, SMPTE, etc)
uniform float CS;     // Color Space (sRGB, DCI-P3, Rec2020)

// --- Samplers ---
// Source (StockPass) is gm_BaseTexture
uniform sampler2D AfterglowPass;
uniform sampler2D SamplerLUT1;
uniform sampler2D SamplerLUT2;
uniform sampler2D SamplerLUT3;
uniform sampler2D SamplerLUT4;

// --- Matrices ---
const mat3 Profile0 = mat3(0.412391, 0.212639, 0.019331, 0.357584, 0.715169, 0.119195, 0.180481, 0.072192, 0.950532);
const mat3 Profile1 = mat3(0.430554, 0.222004, 0.020182, 0.341550, 0.706655, 0.129553, 0.178352, 0.071341, 0.939322);
const mat3 Profile2 = mat3(0.396686, 0.210299, 0.006131, 0.372504, 0.713766, 0.115356, 0.181266, 0.075936, 0.967571);
const mat3 Profile3 = mat3(0.393521, 0.212376, 0.018739, 0.365258, 0.701060, 0.111934, 0.191677, 0.086564, 0.958385);
const mat3 Profile4 = mat3(0.392258, 0.209410, 0.016061, 0.351135, 0.725680, 0.093636, 0.166603, 0.064910, 0.850324);
const mat3 Profile5 = mat3(0.377923, 0.195679, 0.010514, 0.317366, 0.722319, 0.097826, 0.207738, 0.082002, 1.076960);

const mat3 ToSRGB   = mat3( 3.240970, -0.969244,  0.055630, -1.537383,  1.875968, -0.203977, -0.498611,  0.041555,  1.056972);
const mat3 ToModern = mat3( 2.791723, -0.894766,  0.041678, -1.173165,  1.815586, -0.130886, -0.440973,  0.032000,  1.002034);
const mat3 ToDCI    = mat3( 2.973422, -0.867605,  0.045031, -1.110433,  1.843757, -0.095697, -0.480247,  0.024743,  1.201215);
const mat3 ToAdobe  = mat3( 2.041588, -0.969244,  0.013444, -0.565007,  1.875968, -0.11836,  -0.344731,  0.041555,  1.015175);
const mat3 ToREC    = mat3( 1.716651, -0.666684,  0.017640, -0.355671,  1.616481, -0.042771, -0.253366,  0.015769,  0.942103);
const mat3 ToP3     = mat3( 2.493509, -0.829473,  0.035851, -0.931388,  1.762630, -0.076184, -0.402712,  0.023624,  0.957030);

const mat3 D65_to_D55 = mat3(0.485034, 0.250096, 0.022736, 0.348896, 0.697791, 0.116299, 0.130282, 0.052113, 0.686154);
const mat3 D65_to_D93 = mat3(0.341275, 0.175970, 0.015997, 0.364617, 0.729234, 0.121539, 0.236989, 0.094796, 1.248144);

// --- Helper Functions ---
vec3 fix_lut(vec3 lutcolor, vec3 ref) {
    float r = length(ref);
    float l = length(lutcolor);
    float m = max(max(ref.r, ref.g), ref.b);
    ref = normalize(lutcolor + 0.0000001) * mix(r, l, pow(m, 1.25));
    return mix(lutcolor, ref, LUTBR);
}

float vignette(vec2 pos) {
    vec2 b = vec2(vigdef, vigdef) * vec2(1.0, OriginalSize.x/OriginalSize.y) * 0.125;
    pos = clamp(pos, 0.0, 1.0);
    pos = abs(2.0 * (pos - 0.5));
    vec2 res = mix(vec2(0.0), vec2(1.0), smoothstep(vec2(1.0), vec2(1.0)-b, sqrt(pos)));
    res = pow(res, vec2(0.70));
    return max(mix(1.0, sqrt(res.x * res.y), vigstr), 0.0);
}

vec3 plant(vec3 tar, float r) {
    float t = max(max(tar.r, tar.g), tar.b) + 0.00001;
    return tar * r / t;
}

float contrast_fn(float x) {
    return max(mix(x, smoothstep(0.0, 1.0, x), contr), 0.0);
}

vec3 pgc(vec3 c) {
    float mc = max(max(c.r, c.g), c.b);
    float mg = pow(mc, 1.0 / pre_gc);
    return c * mg / (mc + 1e-8);
}

void main()
{
    // 1. Sample Inputs
    vec4 imgColor = texture2D(gm_BaseTexture, v_vTexcoord);
    vec4 aftglow = texture2D(AfterglowPass, v_vTexcoord);
    
    // 2. Apply Afterglow Logic
    float w = 1.0 - aftglow.w;
    float l = length(aftglow.rgb);
    aftglow.rgb = AS * w * normalize(pow(aftglow.rgb + 0.01, vec3(agsat))) * l;
    
    // 3. Basic Brightness Adjustments
    float bp = w * BP / 255.0;
    
    if (sega_fix > 0.5) imgColor.rgb = imgColor.rgb * (255.0 / 239.0);
    imgColor.rgb = min(imgColor.rgb, 1.0);
    
    vec3 color = imgColor.rgb;
    
    // 4. LUT Application
    int tntc_int = int(TNTC);
    if (tntc_int > 0)
    {
        float lutlow = LUTLOW / 255.0; 
        float invLS = 1.0 / LS;
        
        // Color correction before lookup
        vec3 lut_ref = imgColor.rgb + lutlow * (1.0 - pow(imgColor.rgb, vec3(0.333)));
        
        float lutb = lut_ref.b * (1.0 - 0.5 * invLS);
        lut_ref.rg = lut_ref.rg * (1.0 - invLS) + 0.5 * invLS;
        
        float tile1 = ceil(lutb * (LS - 1.0));
        float tile0 = max(tile1 - 1.0, 0.0);
        float f = fract(lutb * (LS - 1.0)); 
        if (f == 0.0) f = 1.0;
        
        vec2 coord0 = vec2(tile0 + lut_ref.r, lut_ref.g) * vec2(invLS, 1.0);
        vec2 coord1 = vec2(tile1 + lut_ref.r, lut_ref.g) * vec2(invLS, 1.0);
        
        vec4 color1, color2, res;
        
        // Manual Texture Selection (GLSL ES 2.0 doesn't support arrays of samplers well)
        if (tntc_int == 1) {
            color1 = texture2D(SamplerLUT1, coord0);
            color2 = texture2D(SamplerLUT1, coord1);
        } else if (tntc_int == 2) {
            color1 = texture2D(SamplerLUT2, coord0);
            color2 = texture2D(SamplerLUT2, coord1);
        } else if (tntc_int == 3) {
            color1 = texture2D(SamplerLUT3, coord0);
            color2 = texture2D(SamplerLUT3, coord1);
        } else { // tntc_int == 4
            color1 = texture2D(SamplerLUT4, coord0);
            color2 = texture2D(SamplerLUT4, coord1);
        }
        
        res = mix(color1, color2, f);
        res.rgb = fix_lut(res.rgb, imgColor.rgb);
        
        // Mix original with LUT result based on TNTC strength (clamped to 1.0)
        color = mix(imgColor.rgb, res.rgb, min(TNTC, 1.0));
    }

    // 5. Color Profile & Space Transforms
    vec3 c = clamp(color, 0.0, 1.0);
    float p = 2.2;
    mat3 m_out = ToSRGB; // Default
    
    if (CS == 1.0) { p = 2.2; m_out = ToModern; } else
    if (CS == 2.0) { p = 2.6; m_out = ToDCI;    } else
    if (CS == 3.0) { p = 2.2; m_out = ToAdobe;  } else
    if (CS == 4.0) { p = 2.4; m_out = ToREC;    } else
    if (CS == 5.0) { p = 2.2; m_out = ToP3;     }
    
    color = pow(c, vec3(p));
    
    mat3 m_in = Profile0;
    if (CP == 1.0) m_in = Profile1; else
    if (CP == 2.0) m_in = Profile2; else
    if (CP == 3.0) m_in = Profile3; else
    if (CP == 4.0) m_in = Profile4; else
    if (CP == 5.0) m_in = Profile5;
    
    color = m_in * color;
    color = m_out * color; // Matrix mult logic is Right-to-Left in math, but check GLSL operator
    // Standard GLSL mat3 * vec3 is equivalent to M * v
    
    color = clamp(color, 0.0, 1.0);
    color = pow(color, vec3(1.0/p));
    
    if (CP == -1.0) color = c; // Bypass profile

    // 6. Saturation & Contrast
    // "Plant" function logic for saturation
    vec3 scolor1 = plant(pow(color, vec3(wp_saturation)), max(max(color.r, color.g), color.b));
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 scolor2 = mix(vec3(luma), color, wp_saturation);
    color = (wp_saturation > 1.0) ? scolor1 : scolor2;

    color = plant(color, contrast_fn(max(max(color.r, color.g), color.b)));

    // 7. Color Temperature (White Point)
    p = 2.2;
    color = clamp(color, 0.0, 1.0);
    color = pow(color, vec3(p));
    
    vec3 warmer = D65_to_D55 * color;
    warmer = ToSRGB * warmer;
    
    vec3 cooler = D65_to_D93 * color;
    cooler = ToSRGB * cooler;
    
    float m = abs(WP) / 100.0;
    vec3 comp = (WP < 0.0) ? cooler : warmer;
    
    color = mix(color, comp, m);
    color = pow(max(color, 0.0), vec3(1.0/p));
    
    // 8. Final Touches
    color = pgc(color);
    
    if (BP > -0.5) {
        color = color + aftglow.rgb + bp;
    } else {
        float max_c = max(max(color.r, color.g), color.b);
        color = max(color + BP/255.0, 0.0) / (1.0 + BP/255.0 * step(-BP/255.0, max_c)) + aftglow.rgb;
    }
    
    color = min(color * pre_bb, 1.0);
    
    gl_FragColor = vec4(color, vignette(v_vTexcoord)); 
}