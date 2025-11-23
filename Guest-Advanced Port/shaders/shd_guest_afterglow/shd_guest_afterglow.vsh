//
// CRT-Guest-NTSC: Pass 1 - Afterglow (Vertex)
//

struct VS_INPUT {
    float3 position : POSITION;
    float2 texcoord : TEXCOORD0;
    float4 color    : COLOR0;
};

struct VS_OUTPUT {
    float4 position : SV_POSITION;
    float2 texcoord : TEXCOORD0;
    float4 color    : COLOR0;
};

// Entry point must be named 'main'
VS_OUTPUT main(VS_INPUT input) {
    VS_OUTPUT output;
    
    float4 pos = float4(input.position, 1.0);
    
    // Transform position by WorldViewProjection matrix
    output.position = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], pos);
    
    // Pass-through texture coordinates and color
    output.texcoord = input.texcoord;
    output.color    = input.color;
    
    return output;
}