varying vec2 v_vTexcoord;
varying vec2 v_vTexcoord0;
varying vec2 v_vTexcoord1;
varying vec4 v_vColour;

uniform vec4 OriginalSize;
uniform int FrameCount;

// Parameters
uniform float ntsc_phase;
uniform float ntsc_sharp;
uniform float ntsc_fonts;
uniform float ntsc_charp;
uniform float ntsc_charp3;
uniform float ntsc_shape;
uniform float ntsc_gamma;
uniform float ntsc_rainbow1;
uniform float speedup;
uniform float auto_res;
uniform float RFNOISE;
uniform float RFNOISE1;
uniform float RFNOISE2;

// Samplers
//uniform sampler2D gm_BaseTexture; // Source (Pass 2 Output: YIQ)
uniform sampler2D NPass1;         // Pass 1 Output (Encoded: Luma in Alpha)
uniform sampler2D PrePass0;       // Original Image (RGB)

// Matrices
const mat3 yiq2rgb_mat = mat3(
   1.0, 0.956, 0.6210,
   1.0, -0.2720, -0.6474,
   1.0, -1.1060, 1.7046
);

const mat3 yiq_mat = mat3(
    0.2989, 0.5870, 0.1140,
    0.5959, -0.2744, -0.3216,
    0.2115, -0.5229, 0.3114
);

// Functions
vec3 yiq2rgb(vec3 yiq) { return yiq * yiq2rgb_mat; }
vec3 rgb2yiq(vec3 col) { return col * yiq_mat; }

float smooth_step_custom(float e0, float e1, float x) {
    return clamp((x - e0) / (e1 - e0), 0.0, 1.0);
}

// Pseudo-Random Noise
vec2 psrnd(vec2 coord, float frame) {
    vec3 p = vec3(coord * 16758.5453, frame);
    float x = fract(sin(dot(p, vec3(12.9898, 78.233, 3.183))) * 43758.5453);
    float y = fract(sin(dot(p, vec3(25.9796, 14.113, 11.271))) * 96321.9124);
    return vec2(x, y);
}

vec3 Noise(vec2 coord, float frame) {
    vec2 rnd = psrnd(coord, frame);
    vec3 p = vec3(rnd * 758.5453, frame);
    
    float res1 = fract(sin(dot(p, vec3(12.989835, 78.23341, 0.16453))) * 43758.54531);
    float res2 = fract(sin(dot(p, vec3(39.34679, 11.13523, 83.15573))) * 39459.32423);
    float res3 = fract(sin(dot(p, vec3(73.15691, 52.23504, 09.15197))) * 60493.84731);
    
    float rf_sq = RFNOISE * RFNOISE + 0.00001;
    
    float lns = float(abs(res1 - 0.5) < 0.2 * rf_sq);
    float cny = float(abs(res2 - 0.5) < 0.5 * rf_sq);
    float cnz = float(abs(res3 - 0.5) < 0.5 * rf_sq);
    
    lns = lns * smooth_step_custom(0.5 - 0.2 * rf_sq, 0.5 + 0.2 * rf_sq, res1) * 0.66 - 0.33 * lns;
    cny = cny * smooth_step_custom(0.5 - 0.5 * rf_sq, 0.5 + 0.5 * rf_sq, res2) - 0.5 * cny;
    cnz = cnz * smooth_step_custom(0.5 - 0.5 * rf_sq, 0.5 + 0.5 * rf_sq, res3) - 0.5 * cnz;
    
    return vec3(lns, cny, cnz);
}

void main()
{
    // 1. High-Speed Bypass
    // If speedup > 1.25 and resolution is high, skip processing
    float spd = (speedup < 0.1) ? 1.0 : speedup;
    
    if (spd > 1.25 && ((OriginalSize.y > 500.0) || (1.0/OriginalSize.w > 820.0))) // 1/w is height? No, .w is 1/height usually. 
    {
       vec3 signal = texture2D(gm_BaseTexture, v_vTexcoord0).rgb;
       signal.x = pow(signal.x, 1.0 / ntsc_gamma);   
       gl_FragColor = vec4(clamp(yiq2rgb(signal), 0.0, 1.0), 1.0);
       return;
    }

    // 2. Setup Coordinates
    float auto_rez = (auto_res > 0.5) ? 0.5 : 1.0;
    float OriginalWidth = OriginalSize.x * auto_rez;

    vec2 xx = vec2(0.5000 * OriginalSize.z / auto_rez / spd, 0.0);
    vec2 dx = vec2(0.0625 * OriginalSize.z / auto_rez / spd, 0.0);
    
    vec2 texcoord0 = v_vTexcoord1;
    vec2 texcoord = v_vTexcoord0 - 2.0 * dx; // v_vTexcoord0 used here to match 'vTex' logic in slang
    vec2 vTex = v_vTexcoord0;

    // 3. Phase Logic
    float phase = ntsc_phase;
    if (phase < 1.5) {
        phase = (OriginalWidth > 300.0) ? 2.0 : 3.0;
    } else {
        phase = (ntsc_phase > 2.5) ? 3.0 : 2.0;
    }
    if (ntsc_phase > 3.5) phase = 3.0;
    
    // 4. Edge Detection (Using NPass1 Luma)
    // Threshold depends on phase
    float th = (phase < 2.5) ? 0.025 : 0.0075;
    
    // Sample neighbors from Pass 1 (Encoded Luma in Alpha)
    float ca = texture2D(NPass1, texcoord0 - xx - xx).a;
    float c0 = texture2D(NPass1, texcoord0 - xx).a;
    float c1 = texture2D(NPass1, texcoord0).a;
    float c2 = texture2D(NPass1, texcoord0 + xx).a;
    float cb = texture2D(NPass1, texcoord0 + xx + xx).a;
    
    float line0 = smooth_step_custom(th, 0.0, min(abs(c1 - c0), abs(c2 - c1)));
    float line1 = max(smooth_step_custom(th, 0.0, min(abs(ca - c0), abs(c2 - cb))), line0);
    float line2 = max(smooth_step_custom(th, 0.0, min(abs(ca - c2), abs(c0 - cb))), line1);
    
    // 5. Font/Checkerboard Detection
    float diffboost = 0.0;
    
    if (ntsc_fonts > 0.255)
    {
        vec2 yy = vec2(0.0, OriginalSize.w);
        vec2 xx_step = vec2(OriginalSize.z / auto_rez / spd, 0.0);
        
        float b1 = texture2D(NPass1, texcoord0 - yy).a;
        float d1 = texture2D(NPass1, texcoord0 + yy).a;
        float d2 = texture2D(NPass1, texcoord0 + xx_step + yy).a; // Corrected xx logic
        
        float maxdif = float(0.5 * ((abs(c0 - c1) + abs(c1 - c2))) > (1.0 - ntsc_fonts));
        
        float linecb = smooth_step_custom(0.1, 0.0, max(abs(c1 - b1), abs(c1 - d1)));
        
        // Checkerboard Check
        if (abs(c1 - b1) < 0.05 || abs(c2 - d2) < 0.05) linecb = 0.0; // Equivalent to * float(...)
        
        float xdif1 = 0.0;
        float xdif2 = 0.0;
        float th_font = 0.25;
        
        for (int i = 0; i < 10; i++) 
        {
            float fi = float(i) + 0.5;
            float fj = fi + 1.0;
            
            float s_ca = texture2D(gm_BaseTexture, texcoord - fi * xx_step).x;
            float s_c0 = texture2D(gm_BaseTexture, texcoord - fj * xx_step).x;
            float s_c2 = texture2D(gm_BaseTexture, texcoord + fi * xx_step).x;
            float s_cb = texture2D(gm_BaseTexture, texcoord + fj * xx_step).x;
            
            xdif1 = max(abs(s_ca - s_c0) - th_font, xdif1);
            xdif2 = max(abs(s_cb - s_c2) - th_font, xdif2);
        }
        
        float linex = smooth_step_custom(0.0, 0.125, min(xdif1, xdif2));
        
        diffboost = min(linex * linecb * maxdif, 0.625);
    }
    
    // 6. Rainbow Effect Logic
    vec3 ref = texture2D(gm_BaseTexture, texcoord).rgb; // Current YIQ
    vec2 orig = ref.yz;
    
    if (ntsc_rainbow1 > 0.5 && (phase < 2.5 || abs(ntsc_phase - 5.0) < 0.1))
    {
        float ybool = 1.0;
        if ((ntsc_rainbow1 < 1.5) && (line0 > 0.5)) ybool = 0.0;
        else if ((ntsc_rainbow1 < 2.5) && (line2 > 0.5)) ybool = 0.0;
        
        float line_no = floor(mod(OriginalSize.y * v_vTexcoord.y, 2.0));
        float frame_no = floor(mod(float(FrameCount), 2.0));
        float ii = abs(line_no - frame_no);
        
        float dy = ii * OriginalSize.w * ybool;
        
        vec2 ref1 = texture2D(gm_BaseTexture, texcoord - vec2(0.0, dy)).yz;
        vec2 ref2 = texture2D(gm_BaseTexture, texcoord + vec2(0.0, dy)).yz;
        
        vec2 rdf1 = abs(orig - ref1);
        vec2 rdf2 = abs(orig - ref2);
        
        vec2 rdf_ratio = rdf1 / max(rdf1 + rdf2, 0.0000001);
        ref.yz = mix(ref1, ref2, rdf_ratio);
    }
    
    // 7. Adaptive Sharpness Calculation
    float lum1 = min(texture2D(NPass1, vTex - dx).a, texture2D(NPass1, vTex + dx).a);
    float lum2 = ref.x; // Luma from Pass 2
    
    // Sample YIQ neighbors again for differences
    vec3 l1_vec = texture2D(gm_BaseTexture, texcoord + xx).rgb;
    vec3 l2_vec = texture2D(gm_BaseTexture, texcoord - xx).rgb;
    vec3 l3_vec = abs(l1_vec - l2_vec);
    
    float dif = max(max(max(l3_vec.x, l3_vec.y), max(l3_vec.z, abs(l1_vec.x*l1_vec.x - l2_vec.x*l2_vec.x))), diffboost);
    float dff = pow(dif, 0.125);
    
    float lc = smooth_step_custom(0.20, 0.10, abs(lum2 - lum1)) * dff;
    
    float tmp = smooth_step_custom(0.05 - 0.03 * lc, 0.425 - 0.375 * lc, dif);
    float tmp1 = pow((tmp + 0.1) / 1.1, 0.25);
    
    float sweight = mix(tmp, tmp1, line0);
    float sweighr = mix(tmp, tmp1, line2);
    
    vec3 signal = ref;
    float abs_ntsc_sharp = abs(ntsc_sharp);
    
    if (abs_ntsc_sharp > 0.25)
    {
        float mixer = sweight;
        if (ntsc_sharp > 0.25) mixer = sweighr;
        
        mixer *= 0.1 * abs_ntsc_sharp;
        
        float lummix = mix(lum2, lum1, mixer);
        float lm1 = mix(lum2 * lum2, lum1 * lum1, mixer);
        lm1 = sqrt(lm1);
        
        float lm2 = mix(sqrt(lum2), sqrt(lum1), mixer);
        lm2 = lm2 * lm2;
        
        float k1 = abs(lummix - lm1) + 0.00001;
        float k2 = abs(lummix - lm2) + 0.00001;
        
        signal.x = min((k2 * lm1 + k1 * lm2) / (k1 + k2), 1.0);
        signal.x = min(signal.x, max(ntsc_shape * signal.x, lum2));
    }
    
    // 8. Chroma Restoration (ntsc_charp)
    if ((ntsc_charp + ntsc_charp3) > 0.25)
    {
        float dx_scalar = 0.0625 * OriginalSize.z / auto_rez;
        float texcoordx = OriginalSize.x * (v_vTexcoord.x + dx_scalar) - 0.5;
        float fpx = fract(texcoordx);
        
        // Reconstruct aligned coordinate
        float aligned_x = (floor(texcoordx) + 0.5) * OriginalSize.z; // 1/Width
        vec2 charp_coord = vec2(aligned_x, texcoord.y);
        
        float mixer = sweight;
        if (ntsc_sharp > 0.25) mixer = sweighr;
        
        mixer = mix(smooth_step_custom(0.075, 0.125, max(l3_vec.y, l3_vec.z)), smooth_step_custom(0.015, 0.0275, dif), line2) * mixer;
        
        mixer *= 0.1 * ((phase < 2.5) ? ntsc_charp : ntsc_charp3);
        
        // Sample Original Image (PrePass0)
        vec3 col_orig_1 = texture2D(PrePass0, charp_coord).rgb;
        vec3 col_orig_2 = texture2D(PrePass0, charp_coord + vec2(16.0 * dx_scalar, 0.0)).rgb;
        
        vec3 orig_ch = rgb2yiq(mix(col_orig_1, col_orig_2, clamp(1.5 * fpx - 0.25, 0.0, 1.0)));
        
        signal.yz = mix(signal.yz, orig_ch.yz, mixer);
    }
    
    // 9. RF Noise
    float RF_SUM = RFNOISE1 + RFNOISE2;
    if (RF_SUM > 0.005) 
    {
        vec3 ns = Noise(v_vTexcoord, float(FrameCount));
        float Y = mix(0.375, 1.0, pow(signal.x, 0.2));
        
        signal.x = clamp(signal.x + RFNOISE1 * ns.x, 0.0, 1.0);
        signal.y = clamp(signal.y + Y * RFNOISE2 * (0.325 + 1.325 * abs(signal.y)) * ns.y, -0.60, 0.60);
        signal.z = clamp(signal.z + Y * RFNOISE2 * (0.325 + 1.325 * abs(signal.z)) * ns.z, -0.53, 0.53);
    }

    // 10. Final Output
    signal.x = pow(signal.x, 1.0 / ntsc_gamma);
    signal = clamp(yiq2rgb(signal), 0.0, 1.0);
    
    // Determine Alpha output (used for debug or further chaining?)
    // Slang: sweighr = (phase == 2.0 || params.ntsc_phase > 3.5) ? sweighr : 1.0;
    float final_alpha = (abs(phase - 2.0) < 0.1 || ntsc_phase > 3.5) ? sweighr : 1.0;

    gl_FragColor = vec4(signal, final_alpha);
}