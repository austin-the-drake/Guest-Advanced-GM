varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Uniforms
uniform vec4 OriginalSize; // [Width, Height, 1/Width, 1/Height]
uniform float PR;          // Persistence Red
uniform float PG;          // Persistence Green
uniform float PB;          // Persistence Blue
uniform float esrc;        // Source Selection (1.0 = History, 2.0 = Source)
uniform float bth;         // Brightness Threshold

// Texture Samplers
uniform sampler2D OriginalHistory0;      // Previous Frame (History Buffer)
uniform sampler2D AfterglowPassFeedback; // Output of this shader from previous frame

// Note: 'Source' from slang corresponds to gm_BaseTexture here (Current Stock Pass)

void main()
{
    vec2 dx = vec2(OriginalSize.z, 0.0);
    vec2 dy = vec2(0.0, OriginalSize.w);
    vec2 tex = v_vTexcoord;
    
    // 1. Sample the Base Image (Either History or Current Source)
    // Default (esrc 1.0) uses History.
    vec3 color0, color1, color2, color3, color4;

    if (esrc > 1.5)
    {
        // Sample from Source (Current Frame / gm_BaseTexture)
        color0 = texture2D(gm_BaseTexture, tex).rgb;
        color1 = texture2D(gm_BaseTexture, tex - dx).rgb;
        color2 = texture2D(gm_BaseTexture, tex + dx).rgb;
        color3 = texture2D(gm_BaseTexture, tex - dy).rgb;
        color4 = texture2D(gm_BaseTexture, tex + dy).rgb;
    }
    else
    {
        // Sample from History (OriginalHistory0)
        color0 = texture2D(OriginalHistory0, tex).rgb;
        color1 = texture2D(OriginalHistory0, tex - dx).rgb;
        color2 = texture2D(OriginalHistory0, tex + dx).rgb;
        color3 = texture2D(OriginalHistory0, tex - dy).rgb;
        color4 = texture2D(OriginalHistory0, tex + dy).rgb;
    }

    // 2. Apply Simple Blur
    vec3 color = (2.5 * color0 + color1 + color2 + color3 + color4) / 6.5;
    
    // 3. Sample Feedback (Accumulated trails from previous frame)
    vec3 accumulate = texture2D(AfterglowPassFeedback, tex).rgb;

    // 4. Calculate Threshold Mask
    float w = 1.0;
    float b = bth / 255.0;
    float c = max(max(color0.r, color0.g), color0.b);
    w = smoothstep(b, 2.0 * b, c);

    // 5. Mix with Persistence
    // The magic number 0.49 ensures trails decay over time
    vec3 result = mix(max(mix(color, accumulate, 0.49 + vec3(PR, PG, PB)) - 1.25/255.0, 0.0), color, w);

    gl_FragColor = vec4(result, w);
}