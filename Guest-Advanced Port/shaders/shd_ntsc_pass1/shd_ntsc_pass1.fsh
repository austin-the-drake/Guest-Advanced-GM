varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_pix_no;

//uniform sampler2D gm_BaseTexture; // The Input Texture (InterlacePass)

// --- Uniforms ---
uniform vec4 OriginalSize;
uniform int FrameCount;

// NTSC Parameters
uniform float cust_artifacting; // Default: 1.0
uniform float cust_fringing;    // Default: 1.0
uniform float ntsc_sat;         // Default: 1.0
uniform float ntsc_bright;      // Default: 1.0
uniform float ntsc_scale;       // Default: 1.0
uniform float ntsc_fields;      // Default: -1.0 (Auto)
uniform float ntsc_phase;       // Default: 1.0 (Auto)
uniform float ntsc_gamma;       // Default: 1.0
uniform float ntsc_rainbow1;    // Default: 0.0
uniform float auto_res;         // Default: 0.0

#define PI 3.14159265

// YIQ Matrix (NTSC Standard)
const mat3 yiq_mat = mat3(
    0.2989, 0.5870, 0.1140,
    0.5959, -0.2744, -0.3216,
    0.2115, -0.5229, 0.3114
);

vec3 rgb2yiq(vec3 col)
{
    return col * yiq_mat;
}

void main()
{
    // 1. Setup Constants & Logic (Previously Vertex Shader)
    
    // Re-calculate auto_rez to determine phase logic
    float auto_rez = 1.0;
    if (auto_res > 0.5) {
        float factor = floor(OriginalSize.x / 300.0 + 0.5);
        float clamp_val = clamp(factor - 1.0, 0.0, 1.0);
        auto_rez = mix(1.0, 0.5, clamp_val);
    }
    
    float OriginalWidth = OriginalSize.x * auto_rez;
    
    // Determine Phase Mode
    // 1.0 = Auto, 2.0 = 2-Phase (Genesis), 3.0 = 3-Phase (NES)
    float phase_mode;
    if (ntsc_phase < 1.5) {
        // Auto: If width > 300, use 2-Phase, else 3-Phase
        phase_mode = (OriginalWidth > 300.0) ? 2.0 : 3.0;
    } else {
        // Manual: If > 2.5 use 3-phase, else 2-phase
        phase_mode = (ntsc_phase > 2.5) ? 3.0 : 2.0;
    }
    
    // Manual overrides from original code
    if (abs(ntsc_phase - 4.0) < 0.1) phase_mode = 3.0;
    else if (abs(ntsc_phase - 5.0) < 0.1) phase_mode = 2.0;
    
    // Determine Chroma Modulation Frequency
    // 2-Phase uses 4*PI/15, others use PI/3 or PI/2
    float CHROMA_MOD_FREQ;
    if (abs(phase_mode - 2.0) < 0.1 && abs(ntsc_phase - 5.0) > 0.1) {
        CHROMA_MOD_FREQ = (4.0 * PI / 15.0);
    } else {
        if (OriginalWidth <= 300.0 || abs(phase_mode - 3.0) < 0.1) {
            CHROMA_MOD_FREQ = (PI / 3.0);
        } else {
            CHROMA_MOD_FREQ = (PI / 2.0);
        }
    }
    
    // Determine Field Merging
    // -1.0 = Auto (Merge only on 3-phase), 0.0 = No, 1.0 = Yes
    float MERGE = 0.0;
    if (ntsc_fields < -0.5 && abs(phase_mode - 3.0) < 0.1) MERGE = 1.0;
    else if (ntsc_fields > 0.5) MERGE = 1.0;
    
    // Artifact/Fringing Matrix Construction
    // mat3(col0, col1, col2) in GLSL
    float A = cust_artifacting;
    float F = cust_fringing;
    float S = ntsc_sat;
    float B = ntsc_bright;
    
    mat3 mix_mat = mat3(
        B, F, F,          // Column 0
        A, 2.0 * S, 0.0,  // Column 1
        A, 0.0, 2.0 * S   // Column 2
    );
    
    // --- 2. Pixel Processing ---
    
    // Boundary Check
    if (v_vTexcoord.x > 1.0) {
        gl_FragColor = vec4(0.0);
        return;
    }
    
    // Sample and Convert
    vec3 col = texture2D(gm_BaseTexture, v_vTexcoord).rgb;
    vec3 yiq = rgb2yiq(col);
    
    // Gamma Encode Luma (Signal Processing Gamma)
    yiq.x = pow(yiq.x, ntsc_gamma);
    float lum = yiq.x; // Save original luma for Alpha channel
    
    vec3 yiq2 = yiq; // Second field holder
    
    // --- 3. Signal Modulation (Field 1) ---
    
    float frame_float = float(FrameCount);
    
    // Calculate Chroma Phase
    float chroma_phase;
    if (phase_mode < 2.5) {
        // 2-Phase Logic
        chroma_phase = PI * (mod(v_pix_no.y, 2.0) + mod(frame_float, 2.0));
    } else {
        // 3-Phase Logic
        chroma_phase = 0.6667 * PI * (mod(v_pix_no.y, 3.0) + mod(frame_float, 2.0));
    }
    
    float mod_phase = chroma_phase + v_pix_no.x * CHROMA_MOD_FREQ;
    
    float i_mod = cos(mod_phase);
    float q_mod = sin(mod_phase);
    
    // Modulate (Mix I and Q into Y)
    yiq.yz *= vec2(i_mod, q_mod); 
    
    // Apply Crosstalk (Artifacts/Fringing)
    yiq *= mix_mat; // Vector * Matrix = Row-Vector transform
    
    // Demodulate
    yiq.yz *= vec2(i_mod, q_mod);
    
    // --- 4. Signal Modulation (Field 2 - Merging) ---
    if (MERGE > 0.5)
    {
        // Next Frame Phase
        float chroma_phase2;
        if (phase_mode < 2.5) {
            chroma_phase2 = PI * (mod(v_pix_no.y, 2.0) + mod(frame_float + 1.0, 2.0));
        } else {
            chroma_phase2 = 0.6667 * PI * (mod(v_pix_no.y, 3.0) + mod(frame_float + 1.0, 2.0));
        }
        
        float mod_phase2 = chroma_phase2 + v_pix_no.x * CHROMA_MOD_FREQ;
        
        float i_mod2 = cos(mod_phase2);
        float q_mod2 = sin(mod_phase2);
        
        yiq2.yz *= vec2(i_mod2, q_mod2);
        yiq2 *= mix_mat;
        yiq2.yz *= vec2(i_mod2, q_mod2);
        
        // Rainbow Effect Logic
        if (ntsc_rainbow1 < 0.5 || phase_mode > 2.5) {
            yiq = 0.5 * (yiq + yiq2); // Full Average
        } else {
            yiq.x = 0.5 * (yiq.x + yiq2.x); // Luma Average Only
        }
    }

    // Output: Encoded YIQ in RGB channels, Original Luma in Alpha
    gl_FragColor = vec4(yiq, lum);
}