attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Uniforms
uniform vec4 OriginalSize; // [w, h, 1/w, 1/h]
uniform float auto_res;
uniform float speedup;

void main()
{
    vec4 object_space_pos = vec4(in_Position, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    
    // --- Original Slang Logic for Offset ---
    // vTexCoord = TexCoord + vec2(0.5 / speedup * (params.OriginalSize.z/auto_rez)/4.0, 0.0);
    
    // Calculate Auto Resolution Factor
    float auto_rez = 1.0;
    if (auto_res > 0.5) {
        float factor = floor(OriginalSize.x / 300.0 + 0.5);
        float clamp_val = clamp(factor - 1.0, 0.0, 1.0);
        auto_rez = mix(1.0, 0.5, clamp_val);
    }
    
    float spd = (speedup < 0.1) ? 1.0 : speedup;
    
    // Calculate Half-Texel Offset for the 4x width source
    // This centers the FIR filter taps on the signal peaks
    float one_x = OriginalSize.z / auto_rez; // 1.0 / width
    vec2 offset = vec2(0.5 / spd * one_x / 4.0, 0.0);
    
    v_vTexcoord = in_TextureCoord + offset;
}