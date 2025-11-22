attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

varying vec2 v_vTexcoord;
varying vec2 v_vTexcoord0;
varying vec2 v_vTexcoord1;
varying vec4 v_vColour;

uniform vec4 OriginalSize;
uniform float auto_res;
uniform float speedup;

void main()
{
    vec4 object_space_pos = vec4(in_Position, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    v_vColour = in_Colour;

    // Auto Resolution Logic
    float rez = (auto_res > 0.5) ? 0.5 : 1.0;
    float spd = (speedup < 0.1) ? 1.0 : speedup;
    
    // 1. Standard Coordinate (Compensated for Decimate-by-2 in previous passes)
    // Offset = 0.5 * (One Source Pixel Width / 4.0)
    // The 4.0 accounts for the 4x encoding width
    v_vTexcoord = in_TextureCoord + vec2(0.5 * (OriginalSize.z / rez) / 4.0, 0.0);

    // 2. Uncompensated Coordinate (Scaled by speedup)
    v_vTexcoord0 = in_TextureCoord / vec2(spd, 1.0);

    // 3. Nearest-Neighbor Grid Coordinate (Center of texel)
    // Used for "Font" detection logic to snap to pixels
    vec2 tex_floor = floor(v_vTexcoord0 * OriginalSize.xy);
    v_vTexcoord1 = (tex_floor + 0.5) * OriginalSize.zw;
}