attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_pix_no;

// System Uniforms
uniform vec4 OriginalSize; // [Width, Height, 1/Width, 1/Height] of the SOURCE GAME
uniform float ntsc_scale;  // Default: 1.0
uniform float auto_res;    // Default: 0.0

void main()
{
    vec4 object_space_pos = vec4(in_Position, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    
    // --- Original Slang Logic ---
    // float auto_rez = mix(1.0, 0.5, clamp(params.auto_res * round(params.OriginalSize.x/300.0)-1.0, 0.0, 1.0));
    // #define ntsc_scale params.ntsc_scale * auto_rez
    // pix_no = vTexCoord * params.OriginalSize.xy * vec2(res, res/auto_rez) * vec2(4.0, 1.0);
    
    // 1. Calculate Auto-Resolution Scaling
    // If auto_res is enabled (1.0) and width > 300, we downscale logic by 0.5
    float auto_rez = 1.0;
    if (auto_res > 0.5) {
        float factor = floor(OriginalSize.x / 300.0 + 0.5); // round()
        float clamp_val = clamp(factor - 1.0, 0.0, 1.0);
        auto_rez = mix(1.0, 0.5, clamp_val);
    }
    
    // 2. Calculate Effective Scale
    float current_scale = ntsc_scale * auto_rez;
    float res = min(current_scale, 1.0);
    
    // 3. Calculate Pixel Number (Signal Coordinate)
    // The 4.0 multiplication represents the signal carrier frequency/width encoding
    vec2 scale_factor = vec2(res, res / auto_rez) * vec2(4.0, 1.0);
    v_pix_no = in_TextureCoord * OriginalSize.xy * scale_factor;
}