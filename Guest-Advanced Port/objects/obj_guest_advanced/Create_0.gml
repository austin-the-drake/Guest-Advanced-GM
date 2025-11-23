/// @description Create Event
// -----------------------------------------------------------------------------
// CONFIGURATION
// -----------------------------------------------------------------------------
game_res_x = 320;
game_res_y = 240;
framecount = 0;

// -----------------------------------------------------------------------------
// SURFACE MANAGEMENT
// -----------------------------------------------------------------------------
surf_game = -1; // Input View

// Render Targets (T01 - T14)
surf_NTSC_T01 = -1; surf_NTSC_T01_prev = -1; // Afterglow + History
surf_NTSC_T02 = -1; // PreShader
surf_NTSC_T03 = -1; // Signal 1
surf_NTSC_T04 = -1; // Signal 2
surf_NTSC_T05 = -1; // Signal 3
surf_NTSC_T06 = -1; // Sharpness
surf_NTSC_T07 = -1; surf_NTSC_T07_prev = -1; // Luminance + History
surf_NTSC_T08 = -1; // Linearize
surf_NTSC_T09 = -1; // CRT Pass 1
surf_NTSC_T10 = -1; // Gaussian X
surf_NTSC_T11 = -1; // Gaussian Y
surf_NTSC_T12 = -1; // Bloom Horz
surf_NTSC_T13 = -1; // Bloom Vert
surf_NTSC_T14 = -1; // CRT Pass 2

// -----------------------------------------------------------------------------
// RESOURCES (LUTs)
// -----------------------------------------------------------------------------
// Ensure these sprites are loaded and not on separate texture pages
tex_lut1 = sprite_get_texture(spr_crt_lut1, 0);
tex_lut2 = sprite_get_texture(spr_crt_lut2, 0);
tex_lut3 = sprite_get_texture(spr_crt_lut3, 0);
tex_lut4 = sprite_get_texture(spr_crt_lut4, 0);

// -----------------------------------------------------------------------------
// SHADER ASSETS (Placeholders)
// -----------------------------------------------------------------------------
// We map the specific afterglow shader here. 
// The rest default to passthrough until ported.
var _pt = shd_passthrough; 

shd_pass_afterglow  = shd_guest_afterglow; // <--- Ported Shader 1
shd_pass_preshader  = _pt;
shd_pass_ntsc1      = _pt;
shd_pass_ntsc2      = _pt;
shd_pass_ntsc3      = _pt;
shd_pass_sharpness  = _pt;
shd_pass_luminance  = _pt;
shd_pass_linearize  = _pt;
shd_pass_crt1       = _pt;
shd_pass_gauss_x    = _pt;
shd_pass_gauss_y    = _pt;
shd_pass_bloom_h    = _pt;
shd_pass_bloom_v    = _pt;
shd_pass_crt2       = _pt;
shd_pass_chromatic  = _pt;

// -----------------------------------------------------------------------------
// UNIFORMS (Default values from .fx)
// -----------------------------------------------------------------------------
u_internal_res = 1.0; 

// NTSC
u_cust_artifacting = 1.0; u_cust_fringing = 1.0; u_ntsc_fields = 1.0;
u_ntsc_phase = 1.0; u_ntsc_scale = 1.0; u_ntsc_taps = 32.0;
u_ntsc_cscale1 = 1.0; u_ntsc_cscale2 = 1.0; u_ntsc_sat = 1.0;
u_ntsc_brt = 1.0; u_ntsc_gamma = 1.0; u_ntsc_rainbow = 0.0;
u_ntsc_ring = 0.5; u_ntsc_shrp = 0.0; u_ntsc_shpe = 0.8;
u_ntsc_charp1 = 0.0; u_ntsc_charp2 = 0.0;

// Sharpen
u_CSHARPEN = 0.0; u_CCONTR = 0.05; u_CDETAILS = 1.0;
u_DEBLUR = 1.0; u_DREDGE = 0.9; u_DSHARP = 0.0;

// Afterglow
u_PR = 0.32; u_PG = 0.32; u_PB = 0.32; u_AS = 0.2; u_ST = 0.5;

// Color/LUT
u_CS = 0.0; u_CP = 0.0; u_TNTC = 0.0; u_LUTLOW = 5.0;
u_LUTBR = 1.0; u_WP = 0.0; u_wp_saturation = 1.0;
u_pre_bb = 1.0; u_contra = 0.0; u_sega_fix = 0.0; u_BP = 0.0;

// Vignette
u_vigstr = 0.0; u_vigdef = 1.0; u_lsmooth = 0.7;

// Gamma/Interlace
u_gamma_i = 2.00; u_gamma_o = 1.95; u_interr = 400.0; u_interm = 4.0;
u_iscanb = 0.2; u_iscans = 0.25; u_hiscan = 0.0; u_intres = 0.0;
u_downsample_levelx = 0.0; u_downsample_levely = 0.0;

// Blur
u_HSHARPNESS = 1.6; u_LIGMA_H = 0.8; u_S_SHARP = 1.1;
u_SHARP = 1.2; u_MAXS = 0.18; u_SSRNG = 0.3;

// Glow
u_m_glow = 0.0; u_m_glow_cutoff = 0.12; u_m_glow_low = 0.35;
u_m_glow_high = 5.0; u_m_glow_dist = 1.0; u_m_glow_mask = 1.0;
u_FINE_GAUSS = 1.0; u_SIZEH = 6.0; u_SIGMA_H = 1.2;
u_SIZEV = 6.0; u_SIGMA_V = 1.2; u_glow = 0.08;

// Bloom
u_FINE_BLOOM = 1.0; u_SIZEX = 3.0; u_SIGMA_X = 0.75;
u_SIZEY = 3.0; u_SIGMA_Y = 0.60; u_blm_1 = 0.0;
u_b_mask = 0.0; u_mask_bloom = 0.0; u_bloom_dist = 0.0;
u_halation = 0.0; u_h_mask = 0.5; u_blm_2 = 0.0; u_OS = 1.0;

// Masks
u_shadow_msk = 1.0; u_maskstr = 0.3; u_mcut = 1.1; u_maskboost = 1.0;
u_masksize = 1.0; u_mask_zoom = 0.0; u_zoom_mask = 0.0; u_mshift = 0.0;
u_mask_layout = 0.0; u_mask_drk = 0.5; u_mask_lgt = 1.5; u_mask_gamma = 2.4;
u_slotmask1 = 0.0; u_slotmask2 = 0.0; u_slotwidth = 0.0; u_double_slot = 2.0;
u_slotms = 1.0; u_smoothmask = 0.0; u_smask_mit = 0.0; u_bmask = 0.0;
u_mclip = 0.0; u_pr_scan = 0.1; u_maskmid = 0.0; u_edgemask = 0.0;

// Scanlines
u_clp = 0.0; u_gsl = 0.0; u_scanline1 = 6.0; u_scanline2 = 8.0;
u_beam_min = 1.3; u_beam_max = 1.0; u_tds = 0.0; u_beam_size = 0.6;
u_scans = 0.5; u_scan_falloff = 1.0; u_spike = 1.0; u_scangamma = 2.4;
u_rolling_scan = 0.0; u_no_scanlines = 0.0;

// Geom/Color
u_gamma_c = 1.0; u_gamma_d = 1.0; u_brightboost1 = 1.4; u_brightboost2 = 1.1;
u_IOS = 0.0; u_csize = 0.0; u_bsize = 0.0; u_sborder = 0.75;
u_barspeed = 50.0; u_barintensity = 0.0; u_bardir = 0.0;
u_warpx = 0.0; u_warpy = 0.0; u_c_shape = 0.25;
u_overscanx = 0.0; u_overscany = 0.0;
u_dctypex = 0.0; u_dctypey = 0.0; u_deconrx = 0.0; u_decongx = 0.0;
u_deconbx = 0.0; u_deconry = 0.0; u_decongy = 0.0; u_deconby = 0.0;
u_decons = 1.0; u_addnoised = 0.0; u_noiseresd = 2.0; u_noisetype = 0.0;
u_post_br = 1.0;

// -----------------------------------------------------------------------------
// HELPER METHOD: Push Uniforms
// -----------------------------------------------------------------------------
// Pushes ALL uniforms to the currently active shader.
push_all_uniforms = function(_shader) {
    var _u;
    
    // Resolution / Time
    shader_set_uniform_i(shader_get_uniform(_shader, "framecount"), framecount);
    
    // NTSC
    shader_set_uniform_f(shader_get_uniform(_shader, "internal_res"), u_internal_res);
    shader_set_uniform_f(shader_get_uniform(_shader, "cust_artifacting"), u_cust_artifacting);
    shader_set_uniform_f(shader_get_uniform(_shader, "cust_fringing"), u_cust_fringing);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_fields"), u_ntsc_fields);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_phase"), u_ntsc_phase);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_scale"), u_ntsc_scale);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_taps"), u_ntsc_taps);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_cscale1"), u_ntsc_cscale1);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_cscale2"), u_ntsc_cscale2);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_sat"), u_ntsc_sat);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_brt"), u_ntsc_brt);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_gamma"), u_ntsc_gamma);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_rainbow"), u_ntsc_rainbow);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_ring"), u_ntsc_ring);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_shrp"), u_ntsc_shrp);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_shpe"), u_ntsc_shpe);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_charp1"), u_ntsc_charp1);
    shader_set_uniform_f(shader_get_uniform(_shader, "ntsc_charp2"), u_ntsc_charp2);
    
    // Sharpen
    shader_set_uniform_f(shader_get_uniform(_shader, "CSHARPEN"), u_CSHARPEN);
    shader_set_uniform_f(shader_get_uniform(_shader, "CCONTR"), u_CCONTR);
    shader_set_uniform_f(shader_get_uniform(_shader, "CDETAILS"), u_CDETAILS);
    shader_set_uniform_f(shader_get_uniform(_shader, "DEBLUR"), u_DEBLUR);
    shader_set_uniform_f(shader_get_uniform(_shader, "DREDGE"), u_DREDGE);
    shader_set_uniform_f(shader_get_uniform(_shader, "DSHARP"), u_DSHARP);
    
    // Persistence
    shader_set_uniform_f(shader_get_uniform(_shader, "PR"), u_PR);
    shader_set_uniform_f(shader_get_uniform(_shader, "PG"), u_PG);
    shader_set_uniform_f(shader_get_uniform(_shader, "PB"), u_PB);
    shader_set_uniform_f(shader_get_uniform(_shader, "AS"), u_AS);
    shader_set_uniform_f(shader_get_uniform(_shader, "ST"), u_ST);
    
    // Color / LUT
    shader_set_uniform_f(shader_get_uniform(_shader, "CS"), u_CS);
    shader_set_uniform_f(shader_get_uniform(_shader, "CP"), u_CP);
    shader_set_uniform_f(shader_get_uniform(_shader, "TNTC"), u_TNTC);
    shader_set_uniform_f(shader_get_uniform(_shader, "LUTLOW"), u_LUTLOW);
    shader_set_uniform_f(shader_get_uniform(_shader, "LUTBR"), u_LUTBR);
    shader_set_uniform_f(shader_get_uniform(_shader, "WP"), u_WP);
    shader_set_uniform_f(shader_get_uniform(_shader, "wp_saturation"), u_wp_saturation);
    shader_set_uniform_f(shader_get_uniform(_shader, "pre_bb"), u_pre_bb);
    shader_set_uniform_f(shader_get_uniform(_shader, "contra"), u_contra);
    shader_set_uniform_f(shader_get_uniform(_shader, "sega_fix"), u_sega_fix);
    shader_set_uniform_f(shader_get_uniform(_shader, "BP"), u_BP);
    
    // Vignette/Gamma
    shader_set_uniform_f(shader_get_uniform(_shader, "vigstr"), u_vigstr);
    shader_set_uniform_f(shader_get_uniform(_shader, "vigdef"), u_vigdef);
    shader_set_uniform_f(shader_get_uniform(_shader, "lsmooth"), u_lsmooth);
    shader_set_uniform_f(shader_get_uniform(_shader, "gamma_i"), u_gamma_i);
    shader_set_uniform_f(shader_get_uniform(_shader, "gamma_o"), u_gamma_o);
    shader_set_uniform_f(shader_get_uniform(_shader, "interr"), u_interr);
    shader_set_uniform_f(shader_get_uniform(_shader, "interm"), u_interm);
    shader_set_uniform_f(shader_get_uniform(_shader, "iscanb"), u_iscanb);
    shader_set_uniform_f(shader_get_uniform(_shader, "iscans"), u_iscans);
    shader_set_uniform_f(shader_get_uniform(_shader, "hiscan"), u_hiscan);
    shader_set_uniform_f(shader_get_uniform(_shader, "intres"), u_intres);
    shader_set_uniform_f(shader_get_uniform(_shader, "downsample_levelx"), u_downsample_levelx);
    shader_set_uniform_f(shader_get_uniform(_shader, "downsample_levely"), u_downsample_levely);
    
    // Blur
    shader_set_uniform_f(shader_get_uniform(_shader, "HSHARPNESS"), u_HSHARPNESS);
    shader_set_uniform_f(shader_get_uniform(_shader, "LIGMA_H"), u_LIGMA_H);
    shader_set_uniform_f(shader_get_uniform(_shader, "S_SHARP"), u_S_SHARP);
    shader_set_uniform_f(shader_get_uniform(_shader, "SHARP"), u_SHARP);
    shader_set_uniform_f(shader_get_uniform(_shader, "MAXS"), u_MAXS);
    shader_set_uniform_f(shader_get_uniform(_shader, "SSRNG"), u_SSRNG);
    
    // Glow
    shader_set_uniform_f(shader_get_uniform(_shader, "m_glow"), u_m_glow);
    shader_set_uniform_f(shader_get_uniform(_shader, "m_glow_cutoff"), u_m_glow_cutoff);
    shader_set_uniform_f(shader_get_uniform(_shader, "m_glow_low"), u_m_glow_low);
    shader_set_uniform_f(shader_get_uniform(_shader, "m_glow_high"), u_m_glow_high);
    shader_set_uniform_f(shader_get_uniform(_shader, "m_glow_dist"), u_m_glow_dist);
    shader_set_uniform_f(shader_get_uniform(_shader, "m_glow_mask"), u_m_glow_mask);
    shader_set_uniform_f(shader_get_uniform(_shader, "FINE_GAUSS"), u_FINE_GAUSS);
    shader_set_uniform_f(shader_get_uniform(_shader, "SIZEH"), u_SIZEH);
    shader_set_uniform_f(shader_get_uniform(_shader, "SIGMA_H"), u_SIGMA_H);
    shader_set_uniform_f(shader_get_uniform(_shader, "SIZEV"), u_SIZEV);
    shader_set_uniform_f(shader_get_uniform(_shader, "SIGMA_V"), u_SIGMA_V);
    shader_set_uniform_f(shader_get_uniform(_shader, "glow"), u_glow);
    
    // Bloom
    shader_set_uniform_f(shader_get_uniform(_shader, "FINE_BLOOM"), u_FINE_BLOOM);
    shader_set_uniform_f(shader_get_uniform(_shader, "SIZEX"), u_SIZEX);
    shader_set_uniform_f(shader_get_uniform(_shader, "SIGMA_X"), u_SIGMA_X);
    shader_set_uniform_f(shader_get_uniform(_shader, "SIZEY"), u_SIZEY);
    shader_set_uniform_f(shader_get_uniform(_shader, "SIGMA_Y"), u_SIGMA_Y);
    shader_set_uniform_f(shader_get_uniform(_shader, "blm_1"), u_blm_1);
    shader_set_uniform_f(shader_get_uniform(_shader, "b_mask"), u_b_mask);
    shader_set_uniform_f(shader_get_uniform(_shader, "mask_bloom"), u_mask_bloom);
    shader_set_uniform_f(shader_get_uniform(_shader, "bloom_dist"), u_bloom_dist);
    shader_set_uniform_f(shader_get_uniform(_shader, "halation"), u_halation);
    shader_set_uniform_f(shader_get_uniform(_shader, "h_mask"), u_h_mask);
    shader_set_uniform_f(shader_get_uniform(_shader, "blm_2"), u_blm_2);
    shader_set_uniform_f(shader_get_uniform(_shader, "OS"), u_OS);
    
    // Mask/Scanline
    shader_set_uniform_f(shader_get_uniform(_shader, "shadow_msk"), u_shadow_msk);
    shader_set_uniform_f(shader_get_uniform(_shader, "maskstr"), u_maskstr);
    shader_set_uniform_f(shader_get_uniform(_shader, "mcut"), u_mcut);
    shader_set_uniform_f(shader_get_uniform(_shader, "maskboost"), u_maskboost);
    shader_set_uniform_f(shader_get_uniform(_shader, "masksize"), u_masksize);
    shader_set_uniform_f(shader_get_uniform(_shader, "mask_zoom"), u_mask_zoom);
    shader_set_uniform_f(shader_get_uniform(_shader, "zoom_mask"), u_zoom_mask);
    shader_set_uniform_f(shader_get_uniform(_shader, "mshift"), u_mshift);
    shader_set_uniform_f(shader_get_uniform(_shader, "mask_layout"), u_mask_layout);
    shader_set_uniform_f(shader_get_uniform(_shader, "mask_drk"), u_mask_drk);
    shader_set_uniform_f(shader_get_uniform(_shader, "mask_lgt"), u_mask_lgt);
    shader_set_uniform_f(shader_get_uniform(_shader, "mask_gamma"), u_mask_gamma);
    shader_set_uniform_f(shader_get_uniform(_shader, "slotmask1"), u_slotmask1);
    shader_set_uniform_f(shader_get_uniform(_shader, "slotmask2"), u_slotmask2);
    shader_set_uniform_f(shader_get_uniform(_shader, "slotwidth"), u_slotwidth);
    shader_set_uniform_f(shader_get_uniform(_shader, "double_slot"), u_double_slot);
    shader_set_uniform_f(shader_get_uniform(_shader, "slotms"), u_slotms);
    shader_set_uniform_f(shader_get_uniform(_shader, "smoothmask"), u_smoothmask);
    shader_set_uniform_f(shader_get_uniform(_shader, "smask_mit"), u_smask_mit);
    shader_set_uniform_f(shader_get_uniform(_shader, "bmask"), u_bmask);
    shader_set_uniform_f(shader_get_uniform(_shader, "mclip"), u_mclip);
    shader_set_uniform_f(shader_get_uniform(_shader, "pr_scan"), u_pr_scan);
    shader_set_uniform_f(shader_get_uniform(_shader, "maskmid"), u_maskmid);
    shader_set_uniform_f(shader_get_uniform(_shader, "edgemask"), u_edgemask);
    shader_set_uniform_f(shader_get_uniform(_shader, "clp"), u_clp);
    shader_set_uniform_f(shader_get_uniform(_shader, "gsl"), u_gsl);
    shader_set_uniform_f(shader_get_uniform(_shader, "scanline1"), u_scanline1);
    shader_set_uniform_f(shader_get_uniform(_shader, "scanline2"), u_scanline2);
    shader_set_uniform_f(shader_get_uniform(_shader, "beam_min"), u_beam_min);
    shader_set_uniform_f(shader_get_uniform(_shader, "beam_max"), u_beam_max);
    shader_set_uniform_f(shader_get_uniform(_shader, "tds"), u_tds);
    shader_set_uniform_f(shader_get_uniform(_shader, "beam_size"), u_beam_size);
    shader_set_uniform_f(shader_get_uniform(_shader, "scans"), u_scans);
    shader_set_uniform_f(shader_get_uniform(_shader, "scan_falloff"), u_scan_falloff);
    shader_set_uniform_f(shader_get_uniform(_shader, "spike"), u_spike);
    shader_set_uniform_f(shader_get_uniform(_shader, "scangamma"), u_scangamma);
    shader_set_uniform_f(shader_get_uniform(_shader, "rolling_scan"), u_rolling_scan);
    shader_set_uniform_f(shader_get_uniform(_shader, "no_scanlines"), u_no_scanlines);
    shader_set_uniform_f(shader_get_uniform(_shader, "gamma_c"), u_gamma_c);
    shader_set_uniform_f(shader_get_uniform(_shader, "gamma_d"), u_gamma_d);
    shader_set_uniform_f(shader_get_uniform(_shader, "brightboost1"), u_brightboost1);
    shader_set_uniform_f(shader_get_uniform(_shader, "brightboost2"), u_brightboost2);
    
    // Geom
    shader_set_uniform_f(shader_get_uniform(_shader, "IOS"), u_IOS);
    shader_set_uniform_f(shader_get_uniform(_shader, "csize"), u_csize);
    shader_set_uniform_f(shader_get_uniform(_shader, "bsize"), u_bsize);
    shader_set_uniform_f(shader_get_uniform(_shader, "sborder"), u_sborder);
    shader_set_uniform_f(shader_get_uniform(_shader, "barspeed"), u_barspeed);
    shader_set_uniform_f(shader_get_uniform(_shader, "barintensity"), u_barintensity);
    shader_set_uniform_f(shader_get_uniform(_shader, "bardir"), u_bardir);
    shader_set_uniform_f(shader_get_uniform(_shader, "warpx"), u_warpx);
    shader_set_uniform_f(shader_get_uniform(_shader, "warpy"), u_warpy);
    shader_set_uniform_f(shader_get_uniform(_shader, "c_shape"), u_c_shape);
    shader_set_uniform_f(shader_get_uniform(_shader, "overscanx"), u_overscanx);
    shader_set_uniform_f(shader_get_uniform(_shader, "overscany"), u_overscany);
    shader_set_uniform_f(shader_get_uniform(_shader, "dctypex"), u_dctypex);
    shader_set_uniform_f(shader_get_uniform(_shader, "dctypey"), u_dctypey);
    shader_set_uniform_f(shader_get_uniform(_shader, "deconrx"), u_deconrx);
    shader_set_uniform_f(shader_get_uniform(_shader, "decongx"), u_decongx);
    shader_set_uniform_f(shader_get_uniform(_shader, "deconbx"), u_deconbx);
    shader_set_uniform_f(shader_get_uniform(_shader, "deconry"), u_deconry);
    shader_set_uniform_f(shader_get_uniform(_shader, "decongy"), u_decongy);
    shader_set_uniform_f(shader_get_uniform(_shader, "deconby"), u_deconby);
    shader_set_uniform_f(shader_get_uniform(_shader, "decons"), u_decons);
    shader_set_uniform_f(shader_get_uniform(_shader, "addnoised"), u_addnoised);
    shader_set_uniform_f(shader_get_uniform(_shader, "noiseresd"), u_noiseresd);
    shader_set_uniform_f(shader_get_uniform(_shader, "noisetype"), u_noisetype);
    shader_set_uniform_f(shader_get_uniform(_shader, "post_br"), u_post_br);
}