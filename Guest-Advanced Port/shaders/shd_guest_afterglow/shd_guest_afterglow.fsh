//
// CRT-Guest-NTSC: Pass 1 - Afterglow (Fragment)
//

struct VS_OUTPUT {
    float4 position : SV_POSITION;
    float2 texcoord : TEXCOORD0;
    float4 color    : COLOR0;
};

// -----------------------------------------------------------------------------
// Samplers
// -----------------------------------------------------------------------------

// t0: Base Game Texture (NTSC_S00)
// This is implicitly set by draw_surface(surf_game,...)
Texture2D tex_source : register(t0);
SamplerState sampler_source : register(s0);

// t1: History Texture (NTSC_S01)
// This is set via texture_set_stage() in GML
Texture2D tex_history : register(t1);
SamplerState sampler_history : register(s1);

// -----------------------------------------------------------------------------
// Uniforms
// -----------------------------------------------------------------------------

// OrgSize: x=Width, y=Height, z=1/Width, w=1/Height
uniform float4 OrgSize;      

// Persistence: RGB decay rates (Passed as a single float3 vector from GML)
uniform float3 Persistence; 

// -----------------------------------------------------------------------------
// Main
// -----------------------------------------------------------------------------

float4 main(VS_OUTPUT input) : SV_TARGET {
    float2 texcoord = input.texcoord;
    
    // Calculate neighbor offsets (1 pixel width/height)
    float2 dx = float2(OrgSize.z, 0.0);
    float2 dy = float2(0.0, OrgSize.w);
    
    float w = 1.0;
    
    // 1. Sample Input Game Image
    // 5-tap average pattern: Center + Left + Right + Up + Down
    float3 color0 = tex_source.Sample(sampler_source, texcoord).rgb;
    float3 color1 = tex_source.Sample(sampler_source, texcoord - dx).rgb;
    float3 color2 = tex_source.Sample(sampler_source, texcoord + dx).rgb;
    float3 color3 = tex_source.Sample(sampler_source, texcoord - dy).rgb;
    float3 color4 = tex_source.Sample(sampler_source, texcoord + dy).rgb;
    
    // Weighted average (Center is weighted 2.5x)
    float3 cr = (2.5 * color0 + color1 + color2 + color3 + color4) / 6.5;
    
    // 2. Sample History Buffer (Previous Frame)
    float3 a = tex_history.Sample(sampler_history, texcoord).rgb;
    
    // 3. Brightness Threshold
    // If the current pixel is very dark, we cut the trail to prevent infinite ghosting artifacts
    if ((color0.r + color0.g + color0.b) < (5.0 / 255.0)) {
        w = 0.0;
    }
    
    // 4. Apply Afterglow Logic
    // Source Logic: result = lerp(max(lerp(cr, a, 0.49 + Persistence) - decay, 0.0), cr, w);
    
    float3 decay_factor = 0.49 + Persistence;
    
    // Blend current averaged frame (cr) with history (a)
    float3 blended = lerp(cr, a, decay_factor);
    
    // Apply constant subtraction decay (1.25 / 255.0) to fade it out over time
    float3 decayed = max(blended - (1.25 / 255.0), 0.0);
    
    // Final mix: If w is 0 (dark pixel), return current frame (cr). 
    // If w is 1, return the decayed history trail.
    float3 result = lerp(decayed, cr, w);
    
    return float4(result, 1.0);
}