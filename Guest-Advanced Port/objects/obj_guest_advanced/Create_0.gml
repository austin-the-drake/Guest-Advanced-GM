/// @description Initialize Pipeline & Parameters

// --- Resolution Settings ---
game_width = 320;
game_height = 224;
bloom_width = 800;
bloom_height = 600;

output_width = window_get_width();
output_height = window_get_height();

// --- Pipeline State ---
history_size = 3;
frame_count = 0;
surf_format = surface_rgba32float; 

// --- Surface Definitions ---
surf_game = -1;
surf_history = array_create(history_size, -1);
history_idx = 0;

surf_afterglow = [ -1, -1 ]; 
surf_avglum    = [ -1, -1 ];
pingpong_read  = 0;
pingpong_write = 1;

surf_stock_pass     = -1; 
surf_prepass0       = -1; 
surf_interlace      = -1; 
surf_ntsc_1         = -1; 
surf_ntsc_2         = -1; 
surf_ntsc_3         = -1; 
surf_ntsc_sharpen   = -1; 
surf_prepass        = -1; 
surf_linearize      = -1; 
surf_pass1          = -1; 
surf_gauss_h        = -1; 
surf_glow           = -1; 
surf_bloom_h        = -1; 
surf_bloom          = -1; 
surf_pass2          = -1; 

// --- View Setup ---
view_enabled = true;
view_visible[0] = true;

// --- Texture Samplers ---
// Pre-fetching sampler IDs
s_afterglow_history   = shader_get_sampler_index(shd_afterglow, "OriginalHistory0");
s_afterglow_feedback  = shader_get_sampler_index(shd_afterglow, "AfterglowPassFeedback");

s_preshader_stock     = shader_get_sampler_index(shd_pre_shaders, "StockPass");
s_preshader_lut1      = shader_get_sampler_index(shd_pre_shaders, "SamplerLUT1");
s_preshader_lut2      = shader_get_sampler_index(shd_pre_shaders, "SamplerLUT2");
s_preshader_lut3      = shader_get_sampler_index(shd_pre_shaders, "SamplerLUT3");
s_preshader_lut4      = shader_get_sampler_index(shd_pre_shaders, "SamplerLUT4");

s_ntsc2_prepass0      = shader_get_sampler_index(shd_ntsc_pass2, "PrePass0");

s_ntsc3_npass1        = shader_get_sampler_index(shd_ntsc_pass3, "NPass1");
s_ntsc3_prepass0      = shader_get_sampler_index(shd_ntsc_pass3, "PrePass0");

s_sharpen_prepass0    = shader_get_sampler_index(shd_fast_sharpen, "PrePass0");

s_avglum_feedback     = shader_get_sampler_index(shd_avg_lum, "AvgLumPassFeedback");

s_linearize_interlace = shader_get_sampler_index(shd_linearize, "InterlacePass");

s_crt2_linearize      = shader_get_sampler_index(shd_crt_pass2, "LinearizePass");
s_crt2_avglum         = shader_get_sampler_index(shd_crt_pass2, "AvgLumPass");
s_crt2_bloom          = shader_get_sampler_index(shd_crt_pass2, "BloomPass");
s_crt2_prepass        = shader_get_sampler_index(shd_crt_pass2, "PrePass");

s_decon_linearize     = shader_get_sampler_index(shd_deconvergence, "LinearizePass");
s_decon_avglum        = shader_get_sampler_index(shd_deconvergence, "AvgLumPass");
s_decon_glow          = shader_get_sampler_index(shd_deconvergence, "GlowPass");
s_decon_bloom         = shader_get_sampler_index(shd_deconvergence, "BloomPass");
s_decon_prepass0      = shader_get_sampler_index(shd_deconvergence, "PrePass0");
s_decon_stock         = shader_get_sampler_index(shd_deconvergence, "StockPass");
s_decon_source        = shader_get_sampler_index(shd_deconvergence, "Source");

// LUT Textures
tex_lut1 = sprite_get_texture(spr_trinitron_lut, 0);
tex_lut2 = sprite_get_texture(spr_inv_trinitron_lut, 0);
tex_lut3 = sprite_get_texture(spr_nec_lut, 0);
tex_lut4 = sprite_get_texture(spr_ntsc_lut, 0);

// --- Pipeline Parameters ---
// Corrected defaults based on slang source analysis
params = {
    // --- System / Global ---
    OriginalSize: [game_width, game_height, 1.0/game_width, 1.0/game_height],
    
    // --- Pass 2: Afterglow ---
    pr: 0.32, pg: 0.32, pb: 0.32, 
    esrc: 1.0, bth: 4.0,
    
    // --- Pass 3: Pre-Shaders ---
    tntc: 4.0, ls: 32.0, lutlow: 5.0, lutbr: 1.0,
    wp: 0.0, wp_sat: 1.0, bp: 0.0, 
    vigstr: 0.0, vigdef: 1.0, sega_fix: 0.0, 
    pre_bb: 1.0, contr: 0.0, pre_gc: 1.0,
    as_strength: 0.20, as_sat: 0.50, 
    cp: 0.0, cs: 0.0,
    
    // --- Pass 4: Interlace ---
    inter: 375.0, interm: 2.0, iscan: 0.20, 
    intres: 0.0, iscans: 0.25, gamma_out_inter: 1.95,
    hiscan: 0.0, gamma_in_inter: 2.0,
    
    // --- Pass 5, 6, 7: NTSC ---
    cust_artifacting: 1.0, cust_fringing: 1.0,
    ntsc_sat: 1.0, ntsc_bright: 1.0,
    ntsc_scale: 1.0, ntsc_fields: -1.0, ntsc_phase: 3.0,
    ntsc_gamma: 1.0, ntsc_rainbow1: 0.0, ntsc_taps: 32.0,
    ntsc_charp: 0.0, ntsc_charp3: 0.0, speedup: 1.0,
    ntsc_ring: 0.5, ntsc_cscale: 1.0, ntsc_cscale1: 1.0,
    ntsc_sharp: 0.0, ntsc_fonts: 0.25, ntsc_shape: 0.80,
    rfnoise: 0.30, rfnoise1: 0.0, rfnoise2: 0.0,
    nscale: 1.0,
    
    // --- Pass 8: Fast Sharpen ---
    csharpen: 0.0, ccontr: 0.05, cdetails: 1.0, 
    ndeblur: 1.0, dsmart: 0.0, dedge: 0.90, desharp: 0.0,
    
    // --- Pass 10: Avg Lum ---
    lsmooth: 0.70, lsdev: 0.0,
    
    // --- Pass 11: Linearize ---
    gamma_input: 2.0, gamma_out_lin: 1.95,
    ds_levelx: 0.0, ds_levely: 0.0,
    
    // --- Pass 12: CRT Pass 1 ---
    sigma_hor: 0.80, hsharpness: 1.60, s_sharp: 1.10, 
    harng: 0.30, hsharp: 1.20, spike: 1.0,
    maxs: 0.18, filter_res: 1.0, auto_res: 0.0,
    
    // --- Pass 13-16: Glow & Bloom ---
    sizeh: 6.0, sigma_h: 1.20, fine_glow: 1.0,
    mglow: 0.0, mglow_cut: 0.12, mglow_low: 0.35, mglow_high: 5.0,
    mglow_dist: 1.0, mglow_mask: 1.0,
    sizev: 6.0, sigma_v: 1.20,
    sizehb: 3.0, sigma_hb: 0.75, fine_bloom: 1.0,
    sizevb: 3.0, sigma_vb: 0.60,
    
    // --- Pass 17 & 18: CRT Pass 2 & Deconvergence ---
    // Explicit parameters requested:
    tds: 0.0,           // Thinner Dark Scanlines
    no_scanlines: 0.0,  // No-scanline mode
    glow: 0.08,         // (Magic) Glow Strength
    
    // Other CRT params
    ios: 0.0, os: 1.0, bloom_str: 0.0, 
    brightboost: 1.40, brightboost1: 1.10,
    gsl: 0.0, scanline1: 6.0, scanline2: 8.0,
    beam_min: 1.30, beam_max: 1.00, beam_size: 0.60,
    shadow_mask: 0.0, mask_size: 1.0, 
    slot_mask: 0.0, slot_mask1: 0.0, slot_width: 0.0, double_slot: 2.0,
    mcut: 1.10, mask_dark: 0.5, mask_light: 1.5, mask_str: 0.3,
    mshift: 0.0, mask_layout: 0.0, mask_bloom: 0.0,
    mask_zoom: 0.0, mzoom_sh: 0.0, smask_mit: 0.0,
    scan_falloff: 1.0, scans: 0.50,
    bloom_dist: 0.0, halation: 0.0,
    bmask: 0.0, bmask1: 0.0, hmask1: 0.35, mclip: 0.0,
    warpx: 0.0, warpy: 0.0, cshape: 0.25,
    csize: 0.0, bsize1: 0.0, sborder: 0.75,
    barspeed: 50.0, barint: 0.0, bardir: 0.0,
    deconr: 0.0, decons: 1.0,
    deconrr: 0.0, deconrg: 0.0, deconrb: 0.0,
    deconrry: 0.0, deconrgy: 0.0, deconrby: 0.0,
    dctypex: 0.0, dctypey: 0.0, post_br: 1.0,
    gamma_c: 1.0, gamma_c2: 1.0, gamma_out_final: 1.95,
    addnoised: 0.0, noiseresd: 2.0, noisetype: 0.0,
    edgemask: 0.0, pr_scan: 0.10, oimage: 0.0,
    
    // Params for previously hardcoded pusher values
    scangamma: 2.40, rolling_scan: 0.0, 
    overscan_x: 0.0, overscan_y: 0.0, vshift: 0.0,
    slotms: 1.0, mask_gamma: 2.40, maskboost: 1.0, smoothmask: 0.0
};

// --- Uniform Pusher Helper ---
push_shader_params = function(_shader, _current_surf) {
    // 1. System Uniforms
    var _w = surface_get_width(_current_surf);
    var _h = surface_get_height(_current_surf);
    
    var u = shader_get_uniform(_shader, "SourceSize");
    shader_set_uniform_f(u, _w, _h, 1.0/_w, 1.0/_h);
    
    u = shader_get_uniform(_shader, "OriginalSize");
    shader_set_uniform_f_array(u, params.OriginalSize);
    
    u = shader_get_uniform(_shader, "OutputSize");
    shader_set_uniform_f(u, output_width, output_height, 1.0/output_width, 1.0/output_height);
    
    u = shader_get_uniform(_shader, "FrameCount");
    shader_set_uniform_i(u, frame_count);
    
    // 2. Shader Specifics
    switch(_shader) {
        case shd_afterglow:
            u = shader_get_uniform(_shader, "PR");   shader_set_uniform_f(u, params.pr);
            u = shader_get_uniform(_shader, "PG");   shader_set_uniform_f(u, params.pg);
            u = shader_get_uniform(_shader, "PB");   shader_set_uniform_f(u, params.pb);
            u = shader_get_uniform(_shader, "esrc"); shader_set_uniform_f(u, params.esrc);
            u = shader_get_uniform(_shader, "bth");  shader_set_uniform_f(u, params.bth);
            break;
            
        case shd_pre_shaders:
            u = shader_get_uniform(_shader, "TNTC"); shader_set_uniform_f(u, params.tntc);
            u = shader_get_uniform(_shader, "LS"); shader_set_uniform_f(u, params.ls);
            u = shader_get_uniform(_shader, "LUTLOW"); shader_set_uniform_f(u, params.lutlow);
            u = shader_get_uniform(_shader, "LUTBR"); shader_set_uniform_f(u, params.lutbr);
            u = shader_get_uniform(_shader, "WP"); shader_set_uniform_f(u, params.wp);
            u = shader_get_uniform(_shader, "wp_saturation"); shader_set_uniform_f(u, params.wp_sat);
            u = shader_get_uniform(_shader, "BP"); shader_set_uniform_f(u, params.bp);
            u = shader_get_uniform(_shader, "vigstr"); shader_set_uniform_f(u, params.vigstr);
            u = shader_get_uniform(_shader, "vigdef"); shader_set_uniform_f(u, params.vigdef);
            u = shader_get_uniform(_shader, "sega_fix"); shader_set_uniform_f(u, params.sega_fix);
            u = shader_get_uniform(_shader, "pre_bb"); shader_set_uniform_f(u, params.pre_bb);
            u = shader_get_uniform(_shader, "contr"); shader_set_uniform_f(u, params.contr);
            u = shader_get_uniform(_shader, "pre_gc"); shader_set_uniform_f(u, params.pre_gc);
            u = shader_get_uniform(_shader, "AS"); shader_set_uniform_f(u, params.as_strength);
            u = shader_get_uniform(_shader, "agsat"); shader_set_uniform_f(u, params.as_sat);
            u = shader_get_uniform(_shader, "CP"); shader_set_uniform_f(u, params.cp);
            u = shader_get_uniform(_shader, "CS"); shader_set_uniform_f(u, params.cs);
            break;
            
        case shd_interlace:
            u = shader_get_uniform(_shader, "inter"); shader_set_uniform_f(u, params.inter);
            u = shader_get_uniform(_shader, "interm"); shader_set_uniform_f(u, params.interm);
            u = shader_get_uniform(_shader, "iscan"); shader_set_uniform_f(u, params.iscan);
            u = shader_get_uniform(_shader, "intres"); shader_set_uniform_f(u, params.intres);
            u = shader_get_uniform(_shader, "iscans"); shader_set_uniform_f(u, params.iscans);
            u = shader_get_uniform(_shader, "gamma_out"); shader_set_uniform_f(u, params.gamma_out_inter);
            u = shader_get_uniform(_shader, "hiscan"); shader_set_uniform_f(u, params.hiscan);
            u = shader_get_uniform(_shader, "GAMMA_INPUT"); shader_set_uniform_f(u, params.gamma_in_inter);
            break;
            
        case shd_ntsc_pass1:
            u = shader_get_uniform(_shader, "cust_artifacting"); shader_set_uniform_f(u, params.cust_artifacting);
            u = shader_get_uniform(_shader, "cust_fringing"); shader_set_uniform_f(u, params.cust_fringing);
            u = shader_get_uniform(_shader, "ntsc_sat"); shader_set_uniform_f(u, params.ntsc_sat);
            u = shader_get_uniform(_shader, "ntsc_bright"); shader_set_uniform_f(u, params.ntsc_bright);
            u = shader_get_uniform(_shader, "ntsc_scale"); shader_set_uniform_f(u, params.ntsc_scale);
            u = shader_get_uniform(_shader, "ntsc_fields"); shader_set_uniform_f(u, params.ntsc_fields);
            u = shader_get_uniform(_shader, "ntsc_phase"); shader_set_uniform_f(u, params.ntsc_phase);
            u = shader_get_uniform(_shader, "ntsc_gamma"); shader_set_uniform_f(u, params.ntsc_gamma);
            u = shader_get_uniform(_shader, "ntsc_rainbow1"); shader_set_uniform_f(u, params.ntsc_rainbow1);
            u = shader_get_uniform(_shader, "ntsc_taps"); shader_set_uniform_f(u, params.ntsc_taps);
            u = shader_get_uniform(_shader, "ntsc_charp"); shader_set_uniform_f(u, params.ntsc_charp);
            u = shader_get_uniform(_shader, "ntsc_charp3"); shader_set_uniform_f(u, params.ntsc_charp3);
            u = shader_get_uniform(_shader, "speedup"); shader_set_uniform_f(u, params.speedup);
            u = shader_get_uniform(_shader, "auto_res"); shader_set_uniform_f(u, params.auto_res);
            break;
            
        case shd_ntsc_pass2:
            u = shader_get_uniform(_shader, "ntsc_scale"); shader_set_uniform_f(u, params.ntsc_scale);
            u = shader_get_uniform(_shader, "ntsc_phase"); shader_set_uniform_f(u, params.ntsc_phase);
            u = shader_get_uniform(_shader, "ntsc_ring"); shader_set_uniform_f(u, params.ntsc_ring);
            u = shader_get_uniform(_shader, "ntsc_cscale"); shader_set_uniform_f(u, params.ntsc_cscale);
            u = shader_get_uniform(_shader, "ntsc_cscale1"); shader_set_uniform_f(u, params.ntsc_cscale1);
            u = shader_get_uniform(_shader, "ntsc_taps"); shader_set_uniform_f(u, params.ntsc_taps);
            u = shader_get_uniform(_shader, "ntsc_charp"); shader_set_uniform_f(u, params.ntsc_charp);
            u = shader_get_uniform(_shader, "ntsc_charp3"); shader_set_uniform_f(u, params.ntsc_charp3);
            u = shader_get_uniform(_shader, "speedup"); shader_set_uniform_f(u, params.speedup);
            u = shader_get_uniform(_shader, "auto_res"); shader_set_uniform_f(u, params.auto_res);
            u = shader_get_uniform(_shader, "nscale"); shader_set_uniform_f(u, params.nscale);
            break;
            
        case shd_ntsc_pass3:
            u = shader_get_uniform(_shader, "ntsc_phase"); shader_set_uniform_f(u, params.ntsc_phase);
            u = shader_get_uniform(_shader, "ntsc_sharp"); shader_set_uniform_f(u, params.ntsc_sharp);
            u = shader_get_uniform(_shader, "ntsc_fonts"); shader_set_uniform_f(u, params.ntsc_fonts);
            u = shader_get_uniform(_shader, "ntsc_shape"); shader_set_uniform_f(u, params.ntsc_shape);
            u = shader_get_uniform(_shader, "ntsc_gamma"); shader_set_uniform_f(u, params.ntsc_gamma);
            u = shader_get_uniform(_shader, "ntsc_rainbow1"); shader_set_uniform_f(u, params.ntsc_rainbow1);
            u = shader_get_uniform(_shader, "ntsc_charp"); shader_set_uniform_f(u, params.ntsc_charp);
            u = shader_get_uniform(_shader, "ntsc_charp3"); shader_set_uniform_f(u, params.ntsc_charp3);
            u = shader_get_uniform(_shader, "speedup"); shader_set_uniform_f(u, params.speedup);
            u = shader_get_uniform(_shader, "auto_res"); shader_set_uniform_f(u, params.auto_res);
            u = shader_get_uniform(_shader, "RFNOISE"); shader_set_uniform_f(u, params.rfnoise);
            u = shader_get_uniform(_shader, "RFNOISE1"); shader_set_uniform_f(u, params.rfnoise1);
            u = shader_get_uniform(_shader, "RFNOISE2"); shader_set_uniform_f(u, params.rfnoise2);
            break;
            
        case shd_fast_sharpen:
            u = shader_get_uniform(_shader, "CSHARPEN"); shader_set_uniform_f(u, params.csharpen);
            u = shader_get_uniform(_shader, "CCONTR"); shader_set_uniform_f(u, params.ccontr);
            u = shader_get_uniform(_shader, "CDETAILS"); shader_set_uniform_f(u, params.cdetails);
            u = shader_get_uniform(_shader, "NDEBLUR"); shader_set_uniform_f(u, params.ndeblur);
            u = shader_get_uniform(_shader, "DSMART"); shader_set_uniform_f(u, params.dsmart);
            u = shader_get_uniform(_shader, "DEDGE"); shader_set_uniform_f(u, params.dedge);
            u = shader_get_uniform(_shader, "DESHARP"); shader_set_uniform_f(u, params.desharp);
            break;
            
        case shd_avg_lum:
            u = shader_get_uniform(_shader, "lsmooth"); shader_set_uniform_f(u, params.lsmooth);
            u = shader_get_uniform(_shader, "lsdev"); shader_set_uniform_f(u, params.lsdev);
            break;
            
        case shd_linearize:
            u = shader_get_uniform(_shader, "GAMMA_INPUT"); shader_set_uniform_f(u, params.gamma_input);
            u = shader_get_uniform(_shader, "gamma_out"); shader_set_uniform_f(u, params.gamma_out_lin);
            u = shader_get_uniform(_shader, "downsample_levelx"); shader_set_uniform_f(u, params.ds_levelx);
            u = shader_get_uniform(_shader, "downsample_levely"); shader_set_uniform_f(u, params.ds_levely);
            break;
            
        case shd_crt_pass1:
            u = shader_get_uniform(_shader, "SIGMA_HOR"); shader_set_uniform_f(u, params.sigma_hor);
            u = shader_get_uniform(_shader, "HSHARPNESS"); shader_set_uniform_f(u, params.hsharpness);
            u = shader_get_uniform(_shader, "S_SHARP"); shader_set_uniform_f(u, params.s_sharp);
            u = shader_get_uniform(_shader, "HARNG"); shader_set_uniform_f(u, params.harng);
            u = shader_get_uniform(_shader, "HSHARP"); shader_set_uniform_f(u, params.hsharp);
            u = shader_get_uniform(_shader, "spike"); shader_set_uniform_f(u, params.spike);
            u = shader_get_uniform(_shader, "filter_res"); shader_set_uniform_f(u, params.filter_res);
            u = shader_get_uniform(_shader, "MAXS"); shader_set_uniform_f(u, params.maxs);
            u = shader_get_uniform(_shader, "auto_res"); shader_set_uniform_f(u, params.auto_res);
            break;
            
        case shd_gauss_h:
            u = shader_get_uniform(_shader, "SIZEH"); shader_set_uniform_f(u, params.sizeh);
            u = shader_get_uniform(_shader, "SIGMA_H"); shader_set_uniform_f(u, params.sigma_h);
            u = shader_get_uniform(_shader, "FINE_GLOW"); shader_set_uniform_f(u, params.fine_glow);
            u = shader_get_uniform(_shader, "m_glow"); shader_set_uniform_f(u, params.mglow);
            u = shader_get_uniform(_shader, "m_glow_cutoff"); shader_set_uniform_f(u, params.mglow_cut);
            u = shader_get_uniform(_shader, "m_glow_low"); shader_set_uniform_f(u, params.mglow_low);
            u = shader_get_uniform(_shader, "m_glow_high"); shader_set_uniform_f(u, params.mglow_high);
            u = shader_get_uniform(_shader, "m_glow_dist"); shader_set_uniform_f(u, params.mglow_dist);
            u = shader_get_uniform(_shader, "m_glow_mask"); shader_set_uniform_f(u, params.mglow_mask);
            u = shader_get_uniform(_shader, "auto_res"); shader_set_uniform_f(u, params.auto_res);
            break;
            
        case shd_gauss_v:
            u = shader_get_uniform(_shader, "SIZEV"); shader_set_uniform_f(u, params.sizev);
            u = shader_get_uniform(_shader, "SIGMA_V"); shader_set_uniform_f(u, params.sigma_v);
            u = shader_get_uniform(_shader, "FINE_GLOW"); shader_set_uniform_f(u, params.fine_glow);
            break;
            
        case shd_bloom_h:
            u = shader_get_uniform(_shader, "SIZEHB"); shader_set_uniform_f(u, params.sizehb);
            u = shader_get_uniform(_shader, "SIGMA_HB"); shader_set_uniform_f(u, params.sigma_hb);
            u = shader_get_uniform(_shader, "FINE_BLOOM"); shader_set_uniform_f(u, params.fine_bloom);
            break;
            
        case shd_bloom_v:
            u = shader_get_uniform(_shader, "SIZEVB"); shader_set_uniform_f(u, params.sizevb);
            u = shader_get_uniform(_shader, "SIGMA_VB"); shader_set_uniform_f(u, params.sigma_vb);
            u = shader_get_uniform(_shader, "FINE_BLOOM"); shader_set_uniform_f(u, params.fine_bloom);
            break;
            
        case shd_crt_pass2:
            u = shader_get_uniform(_shader, "IOS"); shader_set_uniform_f(u, params.ios);
            u = shader_get_uniform(_shader, "OS"); shader_set_uniform_f(u, params.os);
            u = shader_get_uniform(_shader, "BLOOM"); shader_set_uniform_f(u, params.bloom_str);
            u = shader_get_uniform(_shader, "brightboost"); shader_set_uniform_f(u, params.brightboost);
            u = shader_get_uniform(_shader, "brightboost1"); shader_set_uniform_f(u, params.brightboost1);
            u = shader_get_uniform(_shader, "gsl"); shader_set_uniform_f(u, params.gsl);
            u = shader_get_uniform(_shader, "scanline1"); shader_set_uniform_f(u, params.scanline1);
            u = shader_get_uniform(_shader, "scanline2"); shader_set_uniform_f(u, params.scanline2);
            u = shader_get_uniform(_shader, "beam_min"); shader_set_uniform_f(u, params.beam_min);
            u = shader_get_uniform(_shader, "beam_max"); shader_set_uniform_f(u, params.beam_max);
            u = shader_get_uniform(_shader, "beam_size"); shader_set_uniform_f(u, params.beam_size);
            u = shader_get_uniform(_shader, "h_sharp"); shader_set_uniform_f(u, params.hsharp);
            u = shader_get_uniform(_shader, "s_sharp"); shader_set_uniform_f(u, params.s_sharp);
            u = shader_get_uniform(_shader, "warpX"); shader_set_uniform_f(u, params.warpx);
            u = shader_get_uniform(_shader, "warpY"); shader_set_uniform_f(u, params.warpy);
            u = shader_get_uniform(_shader, "glow"); shader_set_uniform_f(u, params.glow);
            u = shader_get_uniform(_shader, "shadowMask"); shader_set_uniform_f(u, params.shadow_mask);
            u = shader_get_uniform(_shader, "masksize"); shader_set_uniform_f(u, params.mask_size);
            u = shader_get_uniform(_shader, "ring"); shader_set_uniform_f(u, params.harng);
            u = shader_get_uniform(_shader, "no_scanlines"); shader_set_uniform_f(u, params.no_scanlines);
            u = shader_get_uniform(_shader, "tds"); shader_set_uniform_f(u, params.tds);
            u = shader_get_uniform(_shader, "clips"); shader_set_uniform_f(u, params.mclip);
            u = shader_get_uniform(_shader, "rolling_scan"); shader_set_uniform_f(u, params.rolling_scan);
            u = shader_get_uniform(_shader, "bloom"); shader_set_uniform_f(u, params.bloom_str);
            u = shader_get_uniform(_shader, "halation"); shader_set_uniform_f(u, params.halation);
            u = shader_get_uniform(_shader, "scans"); shader_set_uniform_f(u, params.scans);
            u = shader_get_uniform(_shader, "gamma_c"); shader_set_uniform_f(u, params.gamma_c);
            u = shader_get_uniform(_shader, "gamma_c2"); shader_set_uniform_f(u, params.gamma_c2);
            u = shader_get_uniform(_shader, "gamma_out"); shader_set_uniform_f(u, params.gamma_out_final);
            u = shader_get_uniform(_shader, "overscanX"); shader_set_uniform_f(u, params.overscan_x);
            u = shader_get_uniform(_shader, "overscanY"); shader_set_uniform_f(u, params.overscan_y);
            u = shader_get_uniform(_shader, "VShift"); shader_set_uniform_f(u, params.vshift);
            u = shader_get_uniform(_shader, "intres"); shader_set_uniform_f(u, params.intres);
            u = shader_get_uniform(_shader, "c_shape"); shader_set_uniform_f(u, params.cshape);
            u = shader_get_uniform(_shader, "scangamma"); shader_set_uniform_f(u, params.scangamma);
            u = shader_get_uniform(_shader, "sborder"); shader_set_uniform_f(u, params.sborder);
            u = shader_get_uniform(_shader, "scan_falloff"); shader_set_uniform_f(u, params.scan_falloff);
            u = shader_get_uniform(_shader, "bloom_dist"); shader_set_uniform_f(u, params.bloom_dist);
            u = shader_get_uniform(_shader, "bmask1"); shader_set_uniform_f(u, params.bmask1);
            u = shader_get_uniform(_shader, "hmask1"); shader_set_uniform_f(u, params.hmask1);
            u = shader_get_uniform(_shader, "interm"); shader_set_uniform_f(u, params.interm);
            break;
            
        case shd_deconvergence:
            u = shader_get_uniform(_shader, "IOS"); shader_set_uniform_f(u, params.ios);
            u = shader_get_uniform(_shader, "OS"); shader_set_uniform_f(u, params.os);
            u = shader_get_uniform(_shader, "BLOOM"); shader_set_uniform_f(u, params.bloom_str);
            u = shader_get_uniform(_shader, "brightboost"); shader_set_uniform_f(u, params.brightboost);
            u = shader_get_uniform(_shader, "brightboost1"); shader_set_uniform_f(u, params.brightboost1);
            u = shader_get_uniform(_shader, "csize"); shader_set_uniform_f(u, params.csize);
            u = shader_get_uniform(_shader, "bsize1"); shader_set_uniform_f(u, params.bsize1);
            u = shader_get_uniform(_shader, "warpX"); shader_set_uniform_f(u, params.warpx);
            u = shader_get_uniform(_shader, "warpY"); shader_set_uniform_f(u, params.warpy);
            u = shader_get_uniform(_shader, "glow"); shader_set_uniform_f(u, params.glow);
            u = shader_get_uniform(_shader, "shadowMask"); shader_set_uniform_f(u, params.shadow_mask);
            u = shader_get_uniform(_shader, "masksize"); shader_set_uniform_f(u, params.mask_size);
            u = shader_get_uniform(_shader, "slotmask"); shader_set_uniform_f(u, params.slot_mask);
            u = shader_get_uniform(_shader, "slotmask1"); shader_set_uniform_f(u, params.slot_mask1);
            u = shader_get_uniform(_shader, "slotwidth"); shader_set_uniform_f(u, params.slot_width);
            u = shader_get_uniform(_shader, "double_slot"); shader_set_uniform_f(u, params.double_slot);
            u = shader_get_uniform(_shader, "mcut"); shader_set_uniform_f(u, params.mcut);
            u = shader_get_uniform(_shader, "maskDark"); shader_set_uniform_f(u, params.mask_dark);
            u = shader_get_uniform(_shader, "maskLight"); shader_set_uniform_f(u, params.mask_light);
            u = shader_get_uniform(_shader, "maskstr"); shader_set_uniform_f(u, params.mask_str);
            u = shader_get_uniform(_shader, "mshift"); shader_set_uniform_f(u, params.mshift);
            u = shader_get_uniform(_shader, "mask_layout"); shader_set_uniform_f(u, params.mask_layout);
            u = shader_get_uniform(_shader, "mask_bloom"); shader_set_uniform_f(u, params.mask_bloom);
            u = shader_get_uniform(_shader, "pr_scan"); shader_set_uniform_f(u, params.pr_scan);
            u = shader_get_uniform(_shader, "bloom"); shader_set_uniform_f(u, params.bloom_str);
            u = shader_get_uniform(_shader, "halation"); shader_set_uniform_f(u, params.halation);
            u = shader_get_uniform(_shader, "slotms"); shader_set_uniform_f(u, params.slotms);
            u = shader_get_uniform(_shader, "mask_gamma"); shader_set_uniform_f(u, params.mask_gamma);
            u = shader_get_uniform(_shader, "gamma_out"); shader_set_uniform_f(u, params.gamma_out_final);
            u = shader_get_uniform(_shader, "overscanX"); shader_set_uniform_f(u, params.overscan_x);
            u = shader_get_uniform(_shader, "overscanY"); shader_set_uniform_f(u, params.overscan_y);
            u = shader_get_uniform(_shader, "VShift"); shader_set_uniform_f(u, params.vshift);
            u = shader_get_uniform(_shader, "intres"); shader_set_uniform_f(u, params.intres);
            u = shader_get_uniform(_shader, "c_shape"); shader_set_uniform_f(u, params.cshape);
            u = shader_get_uniform(_shader, "barspeed"); shader_set_uniform_f(u, params.barspeed);
            u = shader_get_uniform(_shader, "barintensity"); shader_set_uniform_f(u, params.barint);
            u = shader_get_uniform(_shader, "bardir"); shader_set_uniform_f(u, params.bardir);
            u = shader_get_uniform(_shader, "sborder"); shader_set_uniform_f(u, params.sborder);
            u = shader_get_uniform(_shader, "bloom_dist"); shader_set_uniform_f(u, params.bloom_dist);
            u = shader_get_uniform(_shader, "deconr"); shader_set_uniform_f(u, params.deconr);
            u = shader_get_uniform(_shader, "decons"); shader_set_uniform_f(u, params.decons);
            u = shader_get_uniform(_shader, "addnoised"); shader_set_uniform_f(u, params.addnoised);
            u = shader_get_uniform(_shader, "noisetype"); shader_set_uniform_f(u, params.noisetype);
            u = shader_get_uniform(_shader, "noiseresd"); shader_set_uniform_f(u, params.noiseresd);
            u = shader_get_uniform(_shader, "deconrr"); shader_set_uniform_f(u, params.deconrr);
            u = shader_get_uniform(_shader, "deconrg"); shader_set_uniform_f(u, params.deconrg);
            u = shader_get_uniform(_shader, "deconrb"); shader_set_uniform_f(u, params.deconrb);
            u = shader_get_uniform(_shader, "deconrry"); shader_set_uniform_f(u, params.deconrry);
            u = shader_get_uniform(_shader, "deconrgy"); shader_set_uniform_f(u, params.deconrgy);
            u = shader_get_uniform(_shader, "deconrby"); shader_set_uniform_f(u, params.deconrby);
            u = shader_get_uniform(_shader, "dctypex"); shader_set_uniform_f(u, params.dctypex);
            u = shader_get_uniform(_shader, "dctypey"); shader_set_uniform_f(u, params.dctypey);
            u = shader_get_uniform(_shader, "post_br"); shader_set_uniform_f(u, params.post_br);
            u = shader_get_uniform(_shader, "maskboost"); shader_set_uniform_f(u, params.maskboost);
            u = shader_get_uniform(_shader, "smoothmask"); shader_set_uniform_f(u, params.smoothmask);
            u = shader_get_uniform(_shader, "gamma_c"); shader_set_uniform_f(u, params.gamma_c);
            u = shader_get_uniform(_shader, "gamma_c2"); shader_set_uniform_f(u, params.gamma_c2);
            u = shader_get_uniform(_shader, "m_glow"); shader_set_uniform_f(u, params.mglow);
            u = shader_get_uniform(_shader, "m_glow_low"); shader_set_uniform_f(u, params.mglow_low);
            u = shader_get_uniform(_shader, "m_glow_high"); shader_set_uniform_f(u, params.mglow_high);
            u = shader_get_uniform(_shader, "m_glow_dist"); shader_set_uniform_f(u, params.mglow_dist);
            u = shader_get_uniform(_shader, "m_glow_mask"); shader_set_uniform_f(u, params.mglow_mask);
            u = shader_get_uniform(_shader, "smask_mit"); shader_set_uniform_f(u, params.smask_mit);
            u = shader_get_uniform(_shader, "mask_zoom"); shader_set_uniform_f(u, params.mask_zoom);
            u = shader_get_uniform(_shader, "no_scanlines"); shader_set_uniform_f(u, params.no_scanlines);
            u = shader_get_uniform(_shader, "bmask"); shader_set_uniform_f(u, params.bmask);
            u = shader_get_uniform(_shader, "bmask1"); shader_set_uniform_f(u, params.bmask1);
            u = shader_get_uniform(_shader, "hmask1"); shader_set_uniform_f(u, params.hmask1);
            u = shader_get_uniform(_shader, "mzoom_sh"); shader_set_uniform_f(u, params.mzoom_sh);
            u = shader_get_uniform(_shader, "mclip"); shader_set_uniform_f(u, params.mclip);
            u = shader_get_uniform(_shader, "edgemask"); shader_set_uniform_f(u, params.edgemask);
            u = shader_get_uniform(_shader, "oimage"); shader_set_uniform_f(u, params.oimage);
            u = shader_get_uniform(_shader, "interm"); shader_set_uniform_f(u, params.interm);
            break;
    }
}