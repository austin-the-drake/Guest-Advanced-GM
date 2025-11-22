/// @description Execute Full Shader Pipeline

// --- 1. Resolution Enforcement (1:1 Pixel Mapping) ---
var _win_w = window_get_width();
var _win_h = window_get_height();

// Force the App Surface and GUI layer to match the Window exactly.
// This prevents GM's backend from stretching our final result.
if (surface_get_width(application_surface) != _win_w || surface_get_height(application_surface) != _win_h) {
    surface_resize(application_surface, _win_w, _win_h);
    display_set_gui_size(_win_w, _win_h);
}

output_width = _win_w;
output_height = _win_h;

// --- 2. Surface Management & Recovery ---
// Function to check surface existence and re-create if lost
var _check_surf = function(_surf, _w, _h, _format) {
    if (!surface_exists(_surf)) {
        return surface_create(_w, _h, _format);
    }
    return _surf;
}

// Input Surface (Game World)
// If this was lost, we recreate it and immediately re-attach it to the view.
if (!surface_exists(surf_game)) {
    surf_game = surface_create(game_width, game_height);
    view_set_surface_id(0, surf_game);
} else {
    // Ensure the view is still pointed at our surface (just in case room changed)
    if (view_get_surface_id(0) != surf_game) {
        view_set_surface_id(0, surf_game);
    }
}

// History Buffer Recovery
for (var i = 0; i < history_size; i++) {
    surf_history[i] = _check_surf(surf_history[i], game_width, game_height, surface_rgba8unorm);
}

// Feedback Buffer Recovery
for (var i = 0; i < 2; i++) {
    surf_afterglow[i] = _check_surf(surf_afterglow[i], game_width, game_height, surf_format);
    surf_avglum[i]    = _check_surf(surf_avglum[i], 1, 1, surf_format); // 1x1 Pixel for AvgLuma
}

// Intermediate Surface Recovery (Resolutions defined in .slangp)
// Stock/Pre-processing
surf_stock_pass   = _check_surf(surf_stock_pass, game_width, game_height, surface_rgba8unorm);
surf_prepass0     = _check_surf(surf_prepass0, game_width, game_height, surf_format);
surf_interlace    = _check_surf(surf_interlace, game_width, game_height, surf_format);

// NTSC Chain (Scaling rules from slangp)
// Pass 5: scale_x = 4.0
surf_ntsc_1       = _check_surf(surf_ntsc_1, game_width * 4.0, game_height, surf_format); 
// Pass 6: scale_x = 0.5 (Relative to source, so 4.0 * 0.5 = 2.0x game width)
surf_ntsc_2       = _check_surf(surf_ntsc_2, game_width * 2.0, game_height, surf_format);
surf_ntsc_3       = _check_surf(surf_ntsc_3, game_width, game_height, surf_format);
surf_ntsc_sharpen = _check_surf(surf_ntsc_sharpen, game_width, game_height, surf_format);

// Linearize Chain
surf_prepass      = _check_surf(surf_prepass, game_width, game_height, surf_format);
surf_linearize    = _check_surf(surf_linearize, game_width, game_height, surf_format);

// CRT Pass 1 (Viewport Size)
surf_pass1        = _check_surf(surf_pass1, output_width, output_height, surf_format);

// Glow/Bloom Chain (Absolute Size 800x600 from slangp)
surf_gauss_h      = _check_surf(surf_gauss_h, bloom_width, game_height, surf_format);
surf_glow         = _check_surf(surf_glow, bloom_width, bloom_height, surf_format);
surf_bloom_h      = _check_surf(surf_bloom_h, bloom_width, game_height, surf_format);
surf_bloom        = _check_surf(surf_bloom, bloom_width, bloom_height, surf_format);

// CRT Pass 2 (Viewport Size)
surf_pass2        = _check_surf(surf_pass2, output_width, output_height, surf_format);


// --- 3. Input Capture (Entry Point) ---
// Calculate History Indices
var _curr_hist_idx = history_idx;
var _prev_hist_idx = (history_idx - 1 + history_size) % history_size;

// Pass 0: Input -> History (NEAREST)
// slangp: filter_linear0 = false
gpu_set_tex_filter(false); 
surface_set_target(surf_history[_curr_hist_idx]);
    // We draw the Game Surface (which View 0 has just finished rendering to)
    // directly into our history buffer.
    draw_surface(surf_game, 0, 0);
surface_reset_target();

// Pass 1: History -> StockPass (NEAREST)
// slangp: filter_linear1 = false
surface_set_target(surf_stock_pass);
    draw_surface(surf_history[_curr_hist_idx], 0, 0);
surface_reset_target();


// --- 4. Shader Pipeline Execution ---

// Pass 2: Afterglow (LINEAR)
// Inputs: StockPass, History, Feedback(Afterglow[Read])
gpu_set_tex_filter(true);
surface_set_target(surf_afterglow[pingpong_write]);
    shader_set(shd_afterglow);
    push_shader_params(shd_afterglow, surf_stock_pass);
    texture_set_stage(s_afterglow_history, surface_get_texture(surf_history[_prev_hist_idx]));
    texture_set_stage(s_afterglow_feedback, surface_get_texture(surf_afterglow[pingpong_read]));
    
    draw_surface(surf_stock_pass, 0, 0);
    shader_reset();
surface_reset_target();

// Pass 3: Pre-Shaders Afterglow (LINEAR)
// Inputs: AfterglowPass
surface_set_target(surf_prepass0);
    shader_set(shd_pre_shaders);
    push_shader_params(shd_pre_shaders, surf_afterglow[pingpong_write]);
    texture_set_stage(s_preshader_stock, surface_get_texture(surf_stock_pass));
    texture_set_stage(s_preshader_lut1, tex_lut1);
    texture_set_stage(s_preshader_lut2, tex_lut2);
    texture_set_stage(s_preshader_lut3, tex_lut3);
    texture_set_stage(s_preshader_lut4, tex_lut4);
    
    draw_surface(surf_afterglow[pingpong_write], 0, 0);
    shader_reset();
surface_reset_target();

// Pass 4: Interlace NTSC (LINEAR)
// Inputs: PrePass0
surface_set_target(surf_interlace);
    shader_set(shd_interlace);
    push_shader_params(shd_interlace, surf_prepass0);
    draw_surface(surf_prepass0, 0, 0);
    shader_reset();
surface_reset_target();

// Pass 5: NTSC Pass 1 (NEAREST)
// Inputs: InterlacePass
// Scale: 4.0x Width
gpu_set_tex_filter(false);
surface_set_target(surf_ntsc_1);
    shader_set(shd_ntsc_pass1);
    push_shader_params(shd_ntsc_pass1, surf_interlace);
    draw_surface_stretched(surf_interlace, 0, 0, game_width * 4.0, game_height);
    shader_reset();
surface_reset_target();

// Pass 6: NTSC Pass 2 (LINEAR)
// Inputs: NTSC Pass 1
// Scale: 0.5x Width (Relative to source)
gpu_set_tex_filter(true);
surface_set_target(surf_ntsc_2);
    shader_set(shd_ntsc_pass2);
    push_shader_params(shd_ntsc_pass2, surf_ntsc_1);
    texture_set_stage(s_ntsc2_prepass0, surface_get_texture(surf_prepass0));
    
    draw_surface_stretched(surf_ntsc_1, 0, 0, game_width * 2.0, game_height);
    shader_reset();
surface_reset_target();

// Pass 7: NTSC Pass 3 (LINEAR)
// Inputs: NTSC Pass 2
// Scale: Back to 1.0x (Game Resolution)
surface_set_target(surf_ntsc_3);
    shader_set(shd_ntsc_pass3);
    push_shader_params(shd_ntsc_pass3, surf_ntsc_2);
    texture_set_stage(s_ntsc3_npass1, surface_get_texture(surf_ntsc_1));
    texture_set_stage(s_ntsc3_prepass0, surface_get_texture(surf_prepass0));
    
    draw_surface_stretched(surf_ntsc_2, 0, 0, game_width, game_height);
    shader_reset();
surface_reset_target();

// Pass 8: Custom Fast Sharpen (LINEAR)
// Inputs: NTSC Pass 3
surface_set_target(surf_ntsc_sharpen);
    shader_set(shd_fast_sharpen);
    push_shader_params(shd_fast_sharpen, surf_ntsc_3);
    texture_set_stage(s_sharpen_prepass0, surface_get_texture(surf_prepass0));
    
    draw_surface(surf_ntsc_3, 0, 0);
    shader_reset();
surface_reset_target();

// Pass 9: Stock (PrePass Alias Copy) (LINEAR)
surface_set_target(surf_prepass);
    draw_surface(surf_ntsc_sharpen, 0, 0);
surface_reset_target();

// Pass 10: Average Luminance (Feedback) (LINEAR)
// Inputs: PrePass
// Note: In real shader, this downsamples to 1x1.
surface_set_target(surf_avglum[pingpong_write]);
    shader_set(shd_avg_lum);
    push_shader_params(shd_avg_lum, surf_prepass);
    texture_set_stage(s_avglum_feedback, surface_get_texture(surf_avglum[pingpong_read]));
    
    draw_surface_stretched(surf_prepass, 0, 0, 1, 1);
    shader_reset();
surface_reset_target();

// Pass 11: Linearize (LINEAR)
// Inputs: PrePass, InterlacePass
surface_set_target(surf_linearize);
    shader_set(shd_linearize);
    push_shader_params(shd_linearize, surf_prepass);
    texture_set_stage(s_linearize_interlace, surface_get_texture(surf_interlace));
    
    draw_surface(surf_prepass, 0, 0);
    shader_reset();
surface_reset_target();

// Pass 12: CRT Guest Advanced NTSC Pass 1 (LINEAR)
// Inputs: LinearizePass
// Scale: Viewport (Output Size)
surface_set_target(surf_pass1);
    shader_set(shd_crt_pass1);
    push_shader_params(shd_crt_pass1, surf_linearize);
    draw_surface_stretched(surf_linearize, 0, 0, output_width, output_height);
    shader_reset();
surface_reset_target();

// Pass 13: Gaussian Horizontal (LINEAR)
// Inputs: LinearizePass
surface_set_target(surf_gauss_h);
    shader_set(shd_gauss_h);
    push_shader_params(shd_gauss_h, surf_linearize);
    draw_surface_stretched(surf_linearize, 0, 0, bloom_width, game_height);
    shader_reset();
surface_reset_target();

// Pass 14: Gaussian Vertical (GlowPass) (LINEAR)
// Inputs: Gaussian Horizontal
surface_set_target(surf_glow);
    shader_set(shd_gauss_v);
    push_shader_params(shd_gauss_v, surf_gauss_h);
    draw_surface_stretched(surf_gauss_h, 0, 0, bloom_width, bloom_height);
    shader_reset();
surface_reset_target();

// Pass 15: Bloom Horizontal (LINEAR)
// Inputs: LinearizePass
surface_set_target(surf_bloom_h);
    shader_set(shd_bloom_h);
    push_shader_params(shd_bloom_h, surf_linearize);
    draw_surface_stretched(surf_linearize, 0, 0, bloom_width, game_height);
    shader_reset();
surface_reset_target();

// Pass 16: Bloom Vertical (BloomPass) (LINEAR)
// Inputs: Bloom Horizontal
surface_set_target(surf_bloom);
    shader_set(shd_bloom_v);
    push_shader_params(shd_bloom_v, surf_bloom_h);
    draw_surface_stretched(surf_bloom_h, 0, 0, bloom_width, bloom_height);
    shader_reset();
surface_reset_target();

// Pass 17: CRT Guest Advanced NTSC Pass 2 (LINEAR)
// Inputs: Pass1, Linearize, Bloom, PrePass
surface_set_target(surf_pass2);
    shader_set(shd_crt_pass2);
    push_shader_params(shd_crt_pass2, surf_pass1);
    texture_set_stage(s_crt2_linearize, surface_get_texture(surf_linearize));
    texture_set_stage(s_crt2_avglum, surface_get_texture(surf_avglum[pingpong_write]));
    texture_set_stage(s_crt2_bloom, surface_get_texture(surf_bloom));
    texture_set_stage(s_crt2_prepass, surface_get_texture(surf_prepass));
    
    draw_surface(surf_pass1, 0, 0);
    shader_reset();
surface_reset_target();


// --- 5. Final Output (LINEAR) ---
// Shader: shaders/guest/advanced/deconvergence-ntsc.slang
// Inputs: Pass2 (Source), Stock, Glow, Bloom, PrePass0, Linearize, AvgLum
// Target: Screen (Backbuffer/GUI Layer)

shader_set(shd_deconvergence);
    push_shader_params(shd_deconvergence, surf_pass2);
    texture_set_stage(s_decon_source, surface_get_texture(surf_pass2));
    texture_set_stage(s_decon_linearize, surface_get_texture(surf_linearize));
    texture_set_stage(s_decon_avglum, surface_get_texture(surf_avglum[pingpong_write]));
    texture_set_stage(s_decon_glow, surface_get_texture(surf_glow));
    texture_set_stage(s_decon_bloom, surface_get_texture(surf_bloom));
    texture_set_stage(s_decon_prepass0, surface_get_texture(surf_prepass0));
    texture_set_stage(s_decon_stock, surface_get_texture(surf_stock_pass));

    // Disable blending to overwrite the backbuffer with opaque pixels (faster + correct)
    gpu_set_blendenable(false);
    draw_surface_stretched(surf_pass2, 0, 0, output_width, output_height);
    gpu_set_blendenable(true);
shader_reset();


// --- 6. Maintenance ---
// Advance frame counter
frame_count++;

// Advance History Buffer Index
history_idx = (history_idx + 1) % history_size;

// Swap Ping-Pong Buffers
var _temp = pingpong_read;
pingpong_read = pingpong_write;
pingpong_write = _temp;