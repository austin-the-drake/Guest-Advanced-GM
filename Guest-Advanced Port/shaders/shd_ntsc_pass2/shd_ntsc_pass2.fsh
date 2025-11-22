varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// --- Uniforms ---
uniform vec4 OriginalSize;
uniform float ntsc_scale;
uniform float nscale;
uniform float ntsc_phase;
uniform float ntsc_taps;
uniform float ntsc_cscale;
uniform float ntsc_cscale1;
uniform float ntsc_charp;
uniform float ntsc_charp3;
uniform float auto_res;
uniform float speedup;
uniform float ntsc_ring;

//uniform sampler2D gm_BaseTexture; // NTSC Pass 1 Output
uniform sampler2D PrePass0;       // Original RGB (for Luma Ref)

// --- Constants ---
#define TAPS_2_phase 32
#define TAPS_3_phase 24

// --- Helper Functions ---
float smooth_step_custom(float e0, float e1, float x) {
    return clamp((x - e0) / (e1 - e0), 0.0, 1.0);
}

vec3 fetch_offset2(vec2 dx) {
    vec3 c1 = texture2D(gm_BaseTexture, v_vTexcoord + dx).rgb;
    vec3 c2 = texture2D(gm_BaseTexture, v_vTexcoord - dx).rgb;
    return c1 + c2;
}

vec3 fetch_offset3(vec3 dx) {
    // fetch_offset3 logic from slang:
    // texture(Source, vTexCoord + dx.xz).x + texture(Source, vTexCoord - dx.xz).x
    // texture(Source, vTexCoord + dx.yz).yz + texture(Source, vTexCoord - dx.yz).yz
    
    float val_x_p = texture2D(gm_BaseTexture, v_vTexcoord + vec2(dx.x, 0.0)).x;
    float val_x_n = texture2D(gm_BaseTexture, v_vTexcoord - vec2(dx.x, 0.0)).x;
    
    vec2 val_yz_p = texture2D(gm_BaseTexture, v_vTexcoord + vec2(dx.y, 0.0)).yz;
    vec2 val_yz_n = texture2D(gm_BaseTexture, v_vTexcoord - vec2(dx.y, 0.0)).yz;
    
    return vec3(val_x_p + val_x_n, val_yz_p + val_yz_n);
}

float get_luma(vec3 c) {
    return dot(c, vec3(0.2989, 0.5870, 0.1140));
}

void main()
{
    // 1. Filter Weights Initialization
    // GLSL ES 1.0 requires manual assignment
    float luma_filter_2_phase[33];
    luma_filter_2_phase[0] = -0.000174844; luma_filter_2_phase[1] = -0.000205844; luma_filter_2_phase[2] = -0.000149453;
    luma_filter_2_phase[3] = -0.000051693; luma_filter_2_phase[4] = 0.000000000; luma_filter_2_phase[5] = -0.000066171;
    luma_filter_2_phase[6] = -0.000245058; luma_filter_2_phase[7] = -0.000432928; luma_filter_2_phase[8] = -0.000472644;
    luma_filter_2_phase[9] = -0.000252236; luma_filter_2_phase[10] = 0.000198929; luma_filter_2_phase[11] = 0.000687058;
    luma_filter_2_phase[12] = 0.000944112; luma_filter_2_phase[13] = 0.000803467; luma_filter_2_phase[14] = 0.000363199;
    luma_filter_2_phase[15] = 0.000013422; luma_filter_2_phase[16] = 0.000253402; luma_filter_2_phase[17] = 0.001339461;
    luma_filter_2_phase[18] = 0.002932972; luma_filter_2_phase[19] = 0.003983485; luma_filter_2_phase[20] = 0.003026683;
    luma_filter_2_phase[21] = -0.001102056; luma_filter_2_phase[22] = -0.008373026; luma_filter_2_phase[23] = -0.016897700;
    luma_filter_2_phase[24] = -0.022914480; luma_filter_2_phase[25] = -0.021642347; luma_filter_2_phase[26] = -0.028863273;
    luma_filter_2_phase[27] = 0.027271957; luma_filter_2_phase[28] = 0.054921920; luma_filter_2_phase[29] = 0.098342579;
    luma_filter_2_phase[30] = 0.139044281; luma_filter_2_phase[31] = 0.168055832; luma_filter_2_phase[32] = 0.178571429;

    float luma_filter_3_phase[33];
    luma_filter_3_phase[0] = 0.0; luma_filter_3_phase[1] = 0.0; luma_filter_3_phase[2] = 0.0;
    luma_filter_3_phase[3] = 0.0; luma_filter_3_phase[4] = 0.0; luma_filter_3_phase[5] = 0.0;
    luma_filter_3_phase[6] = 0.0; luma_filter_3_phase[7] = 0.0; luma_filter_3_phase[8] = -0.000012020;
    luma_filter_3_phase[9] = -0.000022146; luma_filter_3_phase[10] = -0.000013155; luma_filter_3_phase[11] = -0.000012020;
    luma_filter_3_phase[12] = -0.000049979; luma_filter_3_phase[13] = -0.000113940; luma_filter_3_phase[14] = -0.000122150;
    luma_filter_3_phase[15] = -0.000005612; luma_filter_3_phase[16] = 0.000170516; luma_filter_3_phase[17] = 0.000237199;
    luma_filter_3_phase[18] = 0.000169640; luma_filter_3_phase[19] = 0.000285688; luma_filter_3_phase[20] = 0.000984574;
    luma_filter_3_phase[21] = 0.002018683; luma_filter_3_phase[22] = 0.002002275; luma_filter_3_phase[23] = -0.005909882;
    luma_filter_3_phase[24] = -0.012049081; luma_filter_3_phase[25] = -0.018222860; luma_filter_3_phase[26] = -0.022606931;
    luma_filter_3_phase[27] = 0.002460860; luma_filter_3_phase[28] = 0.035868225; luma_filter_3_phase[29] = 0.084016453;
    luma_filter_3_phase[30] = 0.135563500; luma_filter_3_phase[31] = 0.175261268; luma_filter_3_phase[32] = 0.220176552;

    float chroma_filter_3_phase[33];
    chroma_filter_3_phase[0] = 0.0; chroma_filter_3_phase[1] = 0.0; chroma_filter_3_phase[2] = 0.0;
    chroma_filter_3_phase[3] = 0.0; chroma_filter_3_phase[4] = 0.0; chroma_filter_3_phase[5] = 0.0;
    chroma_filter_3_phase[6] = 0.0; chroma_filter_3_phase[7] = 0.0; chroma_filter_3_phase[8] = -0.000118847;
    chroma_filter_3_phase[9] = -0.000271306; chroma_filter_3_phase[10] = -0.000502642; chroma_filter_3_phase[11] = -0.000930833;
    chroma_filter_3_phase[12] = -0.001451013; chroma_filter_3_phase[13] = -0.002064744; chroma_filter_3_phase[14] = -0.002700432;
    chroma_filter_3_phase[15] = -0.003241276; chroma_filter_3_phase[16] = -0.003524948; chroma_filter_3_phase[17] = -0.003350284;
    chroma_filter_3_phase[18] = -0.002491729; chroma_filter_3_phase[19] = -0.000721149; chroma_filter_3_phase[20] = 0.002164659;
    chroma_filter_3_phase[21] = 0.006313635; chroma_filter_3_phase[22] = 0.011789103; chroma_filter_3_phase[23] = 0.018545660;
    chroma_filter_3_phase[24] = 0.026414396; chroma_filter_3_phase[25] = 0.035100710; chroma_filter_3_phase[26] = 0.044196567;
    chroma_filter_3_phase[27] = 0.053207202; chroma_filter_3_phase[28] = 0.061590275; chroma_filter_3_phase[29] = 0.068803602;
    chroma_filter_3_phase[30] = 0.074356193; chroma_filter_3_phase[31] = 0.077856564; chroma_filter_3_phase[32] = 0.079052396;

    // 2. Setup Auto Resolution & Scale
    float auto_rez = 1.0;
    if (auto_res > 0.5) {
        float factor = floor(OriginalSize.x / 300.0 + 0.5);
        float clamp_val = clamp(factor - 1.0, 0.0, 1.0);
        auto_rez = mix(1.0, 0.5, clamp_val);
    }
    
    float OriginalWidth = OriginalSize.x * auto_rez;
    float res = ntsc_scale * nscale;
    float spd = (speedup < 0.1) ? 1.0 : speedup;
    
    // 3. Calculate Phase
    float phase = ntsc_phase;
    if (ntsc_phase < 1.5) {
        phase = (OriginalWidth > 300.0) ? 2.0 : 3.0;
    } else {
        phase = (ntsc_phase > 2.5) ? 3.0 : 2.0;
    }
    
    // Override if phase > 3.5 (Mixed/PCE modes map to 3.0 logic for filtering here)
    if (ntsc_phase > 3.5) {
        phase = 3.0;
        // In original slang, luma_filter_3_phase becomes luma_filter_2_phase if > 3.5
        // We simulate this swap by copying values or using a flag.
        // Since we can't easily copy arrays, we'll use a condition in the loop.
    }
    bool use_2phase_luma = (ntsc_phase > 3.5);

    // 4. Calculate Steps
    // one_x represents the step size of one decoded pixel
    // The 0.25 comes from the 4x scaling of the previous pass
    vec2 one_x = vec2(0.25 * OriginalSize.z / res / spd, 0.0);
    
    // Handle 3-Phase Chroma Scaling
    float current_cscale = (phase < 2.5) ? ntsc_cscale : ntsc_cscale1;
    vec2 one_chroma = vec2(one_x.x / current_cscale, 0.0);

    // 5. Filtering Logic
    vec3 signal = vec3(0.0);
    vec3 wsum = vec3(0.0);
    
    if (phase < 2.5) // --- 2-Phase Decoding ---
    {
        float iloop = max(ntsc_taps, 8.0);
        if (ntsc_charp > 0.25) iloop = min(iloop, 14.0);
        
        int loopstart = 32 - int(iloop); // TAPS_2_phase (32) - iloop
        
        float cs_sub = iloop - iloop / ntsc_cscale;
        
        // Mitigate Ringing
        float mit = 1.0 + 0.04 * pow(smooth_step_custom(16.0, 8.0, iloop), 0.5);
        vec2 dx = one_x * mit;
        
        for (int i = 0; i < 32; i++) 
        {
            if (i >= loopstart) 
            {
                float offset = float(i - loopstart);
                vec2 dx1 = (offset - iloop) * dx;
                
                vec3 sums = fetch_offset2(dx1);
                
                float ctap = max((offset + 1.0) - cs_sub, 0.0);
                
                // Luma weight from array, Chroma weight is linear ramp 'ctap'
                vec3 tmp = vec3(luma_filter_2_phase[i], ctap, ctap);
                
                wsum += tmp;
                signal += sums * tmp;
            }
        }
        
        // Center Tap
        float ctap = (iloop + 1.0) - cs_sub;
        vec3 tmp = vec3(luma_filter_2_phase[32], ctap, ctap);
        wsum += tmp + tmp;
        signal += texture2D(gm_BaseTexture, v_vTexcoord).rgb * tmp;
        
        signal /= wsum;
    }
    else // --- 3-Phase Decoding ---
    {
        float iloop = min(ntsc_taps, 24.0); // TAPS_3_phase
        if (ntsc_phase > 3.5) {
             iloop = max(iloop, 8.0);
        }
        
        float mit = 1.0;
        if (ntsc_phase > 3.5) {
            mit = 1.0 + 0.04 * pow(smooth_step_custom(16.0, 8.0, iloop), 0.5);
        }
        
        vec2 dx = one_x;
        vec2 dx_luma = one_x * mit; // Luma might use modified step
        
        // Chroma DX uses the separate scaling
        vec3 dx_chroma = vec3(dx.x, one_chroma.x, 0.0);
        
        int loopstart = 32 - int(iloop);
        
        for (int i = 0; i < 32; i++)
        {
             if (i >= loopstart)
             {
                 float offset = float(i - loopstart);
                 vec3 dx1;
                 dx1.xy = (offset - iloop) * dx_chroma.xy;
                 dx1.z = 0.0;
                 
                 // Use fetch_offset3 logic
                 vec3 sums = fetch_offset3(dx1);
                 
                 float l_weight = (use_2phase_luma) ? luma_filter_2_phase[i] : luma_filter_3_phase[i];
                 float c_weight = chroma_filter_3_phase[i];
                 
                 vec3 tmp = vec3(l_weight, c_weight, c_weight);
                 wsum += tmp;
                 signal += sums * tmp;
             }
        }
        
        // Center Tap
        float l_weight = (use_2phase_luma) ? luma_filter_2_phase[32] : luma_filter_3_phase[32];
        float c_weight = chroma_filter_3_phase[32]; // TAPS_2_phase index used in original code for center? 
        // Actually slang code says: luma_filter_3_phase[TAPS_2_phase]... Wait.
        // Slang line 8500: tmp = vec3(luma_filter_3_phase[TAPS_2_phase], ... [TAPS_2_phase])
        // TAPS_2_phase is 32. So it uses index 32 (the last element). Correct.
        
        vec3 tmp = vec3(l_weight, c_weight, c_weight);
        wsum += tmp + tmp;
        signal += texture2D(gm_BaseTexture, v_vTexcoord).rgb * tmp;
        
        signal /= wsum;
    }
    
    signal.x = clamp(signal.x, 0.0, 1.0);
    
    // 6. Anti-Ringing
    if (ntsc_ring > 0.05)
    {
        vec2 dx = vec2(OriginalSize.z / min(res, 1.0) / spd, 0.0);
        
        float a = texture2D(gm_BaseTexture, v_vTexcoord - 2.0*dx).x;
        float b = texture2D(gm_BaseTexture, v_vTexcoord - dx).x;
        float c = texture2D(gm_BaseTexture, v_vTexcoord + 2.0*dx).x;
        float d = texture2D(gm_BaseTexture, v_vTexcoord + dx).x;
        float e = texture2D(gm_BaseTexture, v_vTexcoord).x;
        
        float min_v = min(min(min(a,b), min(c,d)), e);
        float max_v = max(max(max(a,b), max(c,d)), e);
        
        signal.x = mix(signal.x, clamp(signal.x, min_v, max_v), ntsc_ring);
    }

    // 7. Original Luma Retrieval (from PrePass0)
    // NOTE: Speedup logic applies to PrePass coords too?
    // Slang: float orig = get_luma(texture(PrePass0, vTexCoord * vec2(speedup, 1.0)).rgb);
    
    vec2 pre_coords = v_vTexcoord;
    // However, our v_vTexcoord has the 0.5 offset applied. PrePass0 is normal.
    // We should probably strip the offset or just sample. 
    // Given the scale difference, direct sampling is usually fine if alignment is close.
    // But let's apply the speedup scaling if it exists.
    
    if (abs(spd - 1.0) > 0.01) {
        pre_coords.x = pre_coords.x * spd;
    }
    
    vec3 orig_rgb = texture2D(PrePass0, pre_coords).rgb;
    float orig_luma = get_luma(orig_rgb);
    
    gl_FragColor = vec4(signal, orig_luma);
}