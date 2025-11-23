/// @description Draw GUI Event
// -----------------------------------------------------------------------------
// DRAW GUI
// -----------------------------------------------------------------------------
application_surface_draw_enable(false);

var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();

// --- 1. Context Check ---
// Recreate input surface
if (!surface_exists(surf_game)) {
    surf_game = surface_create(game_res_x, game_res_y);
    view_surface_id[0] = surf_game;
} else {
    if (view_surface_id[0] != surf_game) view_surface_id[0] = surf_game;
}

// Recreate render targets
var _check_surf = function(_surf, _w, _h) {
    if (!surface_exists(_surf)) return surface_create(_w, _h);
    return _surf;
}

// History buffers must be cleared if recreated
if (!surface_exists(surf_NTSC_T01_prev)) {
    surf_NTSC_T01_prev = surface_create(game_res_x, game_res_y);
    surface_set_target(surf_NTSC_T01_prev); draw_clear_alpha(c_black, 1.0); surface_reset_target();
}
if (!surface_exists(surf_NTSC_T07_prev)) {
    surf_NTSC_T07_prev = surface_create(game_res_x * 2, game_res_y);
    surface_set_target(surf_NTSC_T07_prev); draw_clear_alpha(c_black, 0.0); surface_reset_target();
}

surf_NTSC_T01 = _check_surf(surf_NTSC_T01, game_res_x, game_res_y);
surf_NTSC_T02 = _check_surf(surf_NTSC_T02, game_res_x, game_res_y);
surf_NTSC_T03 = _check_surf(surf_NTSC_T03, game_res_x * 4, game_res_y);
surf_NTSC_T04 = _check_surf(surf_NTSC_T04, game_res_x * 2, game_res_y);
surf_NTSC_T05 = _check_surf(surf_NTSC_T05, game_res_x * 2, game_res_y);
surf_NTSC_T06 = _check_surf(surf_NTSC_T06, game_res_x * 2, game_res_y);
surf_NTSC_T07 = _check_surf(surf_NTSC_T07, game_res_x * 2, game_res_y);
surf_NTSC_T08 = _check_surf(surf_NTSC_T08, game_res_x * 2, game_res_y);
surf_NTSC_T09 = _check_surf(surf_NTSC_T09, _gui_w, game_res_y); // BUFFER_WIDTH, Resolution_Y
surf_NTSC_T10 = _check_surf(surf_NTSC_T10, 800, game_res_y);
surf_NTSC_T11 = _check_surf(surf_NTSC_T11, 800, 600);
surf_NTSC_T12 = _check_surf(surf_NTSC_T12, 800, 600);
surf_NTSC_T13 = _check_surf(surf_NTSC_T13, 800, 600);
surf_NTSC_T14 = _check_surf(surf_NTSC_T14, _gui_w, _gui_h);

framecount++;

// --- 2. Size Definitions ---
// HLSL: #define OrgSize float4(TexSize, 1.0/TexSize)
// HLSL: #define SrcSize float4(800, 600, 1/800, 1/600)
// HLSL: #define LumSize float4(2*TexSize.x, TexSize.y, ...)
// HLSL: #define OptSize float4(BUFFER_WIDTH, BUFFER_HEIGHT, ...)

var _org_w = game_res_x; var _org_h = game_res_y;
var _src_w = 800.0;      var _src_h = 600.0;
var _lum_w = _org_w * 2; var _lum_h = _org_h;
var _opt_w = _gui_w;     var _opt_h = _gui_h;

// Helper to push size uniforms
var _push_sizes = function(_shd, _orgW, _orgH, _srcW, _srcH, _lumW, _lumH, _optW, _optH) {
    shader_set_uniform_f(shader_get_uniform(_shd, "OrgSize"), _orgW, _orgH, 1.0/_orgW, 1.0/_orgH);
    shader_set_uniform_f(shader_get_uniform(_shd, "SrcSize"), _srcW, _srcH, 1.0/_srcW, 1.0/_srcH);
    shader_set_uniform_f(shader_get_uniform(_shd, "LumSize"), _lumW, _lumH, 1.0/_lumW, 1.0/_lumH);
    shader_set_uniform_f(shader_get_uniform(_shd, "OptSize"), _optW, _optH, 1.0/_optW, 1.0/_optH);
};

// Set Texture Filtering
// ReShade logic: S01/S02 use POINT, others use LINEAR
gpu_set_tex_filter(false); 
gpu_set_tex_repeat(false);

// --- 3. Pipeline Pass Execution ---

// Pass 1: Afterglow
// In: Game, History(T01_prev) | Out: T01
surface_set_target(surf_NTSC_T01);
    shader_set(shd_pass_afterglow);
    push_all_uniforms(shd_pass_afterglow);
    _push_sizes(shd_pass_afterglow, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_afterglow, "NTSC_S01"), surface_get_texture(surf_NTSC_T01_prev));
    draw_surface(surf_game, 0, 0);
    shader_reset();
surface_reset_target();
// Copy T01 to History
surface_copy(surf_NTSC_T01_prev, 0, 0, surf_NTSC_T01);

// Pass 2: PreShader
// In: T01, Game(S00) | Out: T02
surface_set_target(surf_NTSC_T02);
    shader_set(shd_pass_preshader);
    push_all_uniforms(shd_pass_preshader);
    _push_sizes(shd_pass_preshader, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    // Textures: S00(Game), L01-L04
    texture_set_stage(shader_get_sampler_index(shd_pass_preshader, "NTSC_S00"), surface_get_texture(surf_game));
    texture_set_stage(shader_get_sampler_index(shd_pass_preshader, "NTSC_L01"), tex_lut1);
    texture_set_stage(shader_get_sampler_index(shd_pass_preshader, "NTSC_L02"), tex_lut2);
    texture_set_stage(shader_get_sampler_index(shd_pass_preshader, "NTSC_L03"), tex_lut3);
    texture_set_stage(shader_get_sampler_index(shd_pass_preshader, "NTSC_L04"), tex_lut4);
    draw_surface(surf_NTSC_T01, 0, 0);
    shader_reset();
surface_reset_target();

// Switch to Linear filtering for NTSC and Blur passes
gpu_set_tex_filter(true);

// Pass 3: NTSC Pass 1
// In: T02 | Out: T03
surface_set_target(surf_NTSC_T03);
    shader_set(shd_pass_ntsc1);
    push_all_uniforms(shd_pass_ntsc1);
    _push_sizes(shd_pass_ntsc1, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_ntsc1, "NTSC_S02"), surface_get_texture(surf_NTSC_T02));
    draw_surface_stretched(surf_NTSC_T02, 0, 0, surface_get_width(surf_NTSC_T03), surface_get_height(surf_NTSC_T03));
    shader_reset();
surface_reset_target();

// Pass 4: NTSC Pass 2
// In: T03, T02 | Out: T04
surface_set_target(surf_NTSC_T04);
    shader_set(shd_pass_ntsc2);
    push_all_uniforms(shd_pass_ntsc2);
    _push_sizes(shd_pass_ntsc2, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_ntsc2, "NTSC_S02"), surface_get_texture(surf_NTSC_T02));
    texture_set_stage(shader_get_sampler_index(shd_pass_ntsc2, "NTSC_S03"), surface_get_texture(surf_NTSC_T03));
    draw_surface_stretched(surf_NTSC_T03, 0, 0, surface_get_width(surf_NTSC_T04), surface_get_height(surf_NTSC_T04));
    shader_reset();
surface_reset_target();

// Pass 5: NTSC Pass 3
// In: T04, T03, T02 | Out: T05
surface_set_target(surf_NTSC_T05);
    shader_set(shd_pass_ntsc3);
    push_all_uniforms(shd_pass_ntsc3);
    _push_sizes(shd_pass_ntsc3, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_ntsc3, "NTSC_S02"), surface_get_texture(surf_NTSC_T02));
    texture_set_stage(shader_get_sampler_index(shd_pass_ntsc3, "NTSC_S03"), surface_get_texture(surf_NTSC_T03));
    texture_set_stage(shader_get_sampler_index(shd_pass_ntsc3, "NTSC_S04"), surface_get_texture(surf_NTSC_T04));
    draw_surface(surf_NTSC_T04, 0, 0);
    shader_reset();
surface_reset_target();

// Pass 6: Sharpness
// In: T05, T02 | Out: T06
surface_set_target(surf_NTSC_T06);
    shader_set(shd_pass_sharpness);
    push_all_uniforms(shd_pass_sharpness);
    _push_sizes(shd_pass_sharpness, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_sharpness, "NTSC_S02"), surface_get_texture(surf_NTSC_T02));
    texture_set_stage(shader_get_sampler_index(shd_pass_sharpness, "NTSC_S05"), surface_get_texture(surf_NTSC_T05));
    draw_surface(surf_NTSC_T05, 0, 0);
    shader_reset();
surface_reset_target();

// Pass 7: Luminance
// In: T06, History(T07_prev) | Out: T07
surface_set_target(surf_NTSC_T07);
    shader_set(shd_pass_luminance);
    push_all_uniforms(shd_pass_luminance);
    _push_sizes(shd_pass_luminance, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_luminance, "NTSC_S06"), surface_get_texture(surf_NTSC_T06));
    texture_set_stage(shader_get_sampler_index(shd_pass_luminance, "NTSC_S07"), surface_get_texture(surf_NTSC_T07_prev));
    draw_surface(surf_NTSC_T06, 0, 0);
    shader_reset();
surface_reset_target();
// Copy T07 to History
surface_copy(surf_NTSC_T07_prev, 0, 0, surf_NTSC_T07);

// Pass 8: Linearize
// In: T06 | Out: T08
surface_set_target(surf_NTSC_T08);
    shader_set(shd_pass_linearize);
    push_all_uniforms(shd_pass_linearize);
    _push_sizes(shd_pass_linearize, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_linearize, "NTSC_S06"), surface_get_texture(surf_NTSC_T06));
    draw_surface(surf_NTSC_T06, 0, 0);
    shader_reset();
surface_reset_target();

// Pass 9: CRT Pass 1
// In: T08 | Out: T09 (Scale to Screen Width)
surface_set_target(surf_NTSC_T09);
    shader_set(shd_pass_crt1);
    push_all_uniforms(shd_pass_crt1);
    _push_sizes(shd_pass_crt1, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_crt1, "NTSC_S08"), surface_get_texture(surf_NTSC_T08));
    draw_surface_stretched(surf_NTSC_T08, 0, 0, surface_get_width(surf_NTSC_T09), surface_get_height(surf_NTSC_T09));
    shader_reset();
surface_reset_target();

// Pass 10: Gaussian X
// In: T08 | Out: T10
surface_set_target(surf_NTSC_T10);
    shader_set(shd_pass_gauss_x);
    push_all_uniforms(shd_pass_gauss_x);
    _push_sizes(shd_pass_gauss_x, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_gauss_x, "NTSC_S08"), surface_get_texture(surf_NTSC_T08));
    draw_surface_stretched(surf_NTSC_T08, 0, 0, 800, game_res_y);
    shader_reset();
surface_reset_target();

// Pass 11: Gaussian Y
// In: T10 | Out: T11
surface_set_target(surf_NTSC_T11);
    shader_set(shd_pass_gauss_y);
    push_all_uniforms(shd_pass_gauss_y);
    _push_sizes(shd_pass_gauss_y, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_gauss_y, "NTSC_S10"), surface_get_texture(surf_NTSC_T10));
    draw_surface_stretched(surf_NTSC_T10, 0, 0, 800, 600);
    shader_reset();
surface_reset_target();

// Pass 12: Bloom Horz
// In: T08 | Out: T12
surface_set_target(surf_NTSC_T12);
    shader_set(shd_pass_bloom_h);
    push_all_uniforms(shd_pass_bloom_h);
    _push_sizes(shd_pass_bloom_h, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_bloom_h, "NTSC_S08"), surface_get_texture(surf_NTSC_T08));
    draw_surface_stretched(surf_NTSC_T08, 0, 0, 800, 600);
    shader_reset();
surface_reset_target();

// Pass 13: Bloom Vert
// In: T12 | Out: T13
surface_set_target(surf_NTSC_T13);
    shader_set(shd_pass_bloom_v);
    push_all_uniforms(shd_pass_bloom_v);
    _push_sizes(shd_pass_bloom_v, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_bloom_v, "NTSC_S12"), surface_get_texture(surf_NTSC_T12));
    draw_surface(surf_NTSC_T12, 0, 0);
    shader_reset();
surface_reset_target();

// Pass 14: CRT Pass 2
// In: T09, T08, T07 | Out: T14
surface_set_target(surf_NTSC_T14);
    shader_set(shd_pass_crt2);
    push_all_uniforms(shd_pass_crt2);
    _push_sizes(shd_pass_crt2, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_crt2, "NTSC_S09"), surface_get_texture(surf_NTSC_T09));
    texture_set_stage(shader_get_sampler_index(shd_pass_crt2, "NTSC_S08"), surface_get_texture(surf_NTSC_T08));
    texture_set_stage(shader_get_sampler_index(shd_pass_crt2, "NTSC_S07"), surface_get_texture(surf_NTSC_T07)); // Luminance
    draw_surface_stretched(surf_NTSC_T09, 0, 0, _gui_w, _gui_h);
    shader_reset();
surface_reset_target();

// Pass 15: Chromatic (Final)
// In: T14, T13, T11, T08, T07 | Out: Screen
shader_set(shd_pass_chromatic);
    push_all_uniforms(shd_pass_chromatic);
    _push_sizes(shd_pass_chromatic, _org_w, _org_h, _src_w, _src_h, _lum_w, _lum_h, _opt_w, _opt_h);
    texture_set_stage(shader_get_sampler_index(shd_pass_chromatic, "NTSC_S14"), surface_get_texture(surf_NTSC_T14));
    texture_set_stage(shader_get_sampler_index(shd_pass_chromatic, "NTSC_S13"), surface_get_texture(surf_NTSC_T13));
    texture_set_stage(shader_get_sampler_index(shd_pass_chromatic, "NTSC_S11"), surface_get_texture(surf_NTSC_T11));
    texture_set_stage(shader_get_sampler_index(shd_pass_chromatic, "NTSC_S08"), surface_get_texture(surf_NTSC_T08)); // Linearize (Gamma reading)
    texture_set_stage(shader_get_sampler_index(shd_pass_chromatic, "NTSC_S07"), surface_get_texture(surf_NTSC_T07)); // Luminance
    draw_surface_stretched(surf_NTSC_T14, 0, 0, _gui_w, _gui_h);
shader_reset();

gpu_set_tex_filter(false);