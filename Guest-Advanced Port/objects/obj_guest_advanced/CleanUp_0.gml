/// @description Free All Allocated Surfaces

// 0. Free Input Surface
if (surface_exists(surf_game)) {
    surface_free(surf_game);
}

// 1. Free History Buffer
for (var i = 0; i < history_size; i++) {
    if (surface_exists(surf_history[i])) {
        surface_free(surf_history[i]);
    }
}

// 2. Free Feedback Buffers
for (var i = 0; i < 2; i++) {
    if (surface_exists(surf_afterglow[i])) {
        surface_free(surf_afterglow[i]);
    }
    if (surface_exists(surf_avglum[i])) {
        surface_free(surf_avglum[i]);
    }
}

// 3. Free Intermediate Surfaces
if (surface_exists(surf_stock_pass))   surface_free(surf_stock_pass);
if (surface_exists(surf_prepass0))     surface_free(surf_prepass0);
if (surface_exists(surf_interlace))    surface_free(surf_interlace);
if (surface_exists(surf_ntsc_1))       surface_free(surf_ntsc_1);
if (surface_exists(surf_ntsc_2))       surface_free(surf_ntsc_2);
if (surface_exists(surf_ntsc_3))       surface_free(surf_ntsc_3);
if (surface_exists(surf_ntsc_sharpen)) surface_free(surf_ntsc_sharpen);
if (surface_exists(surf_prepass))      surface_free(surf_prepass);
if (surface_exists(surf_linearize))    surface_free(surf_linearize);
if (surface_exists(surf_pass1))        surface_free(surf_pass1);
if (surface_exists(surf_gauss_h))      surface_free(surf_gauss_h);
if (surface_exists(surf_glow))         surface_free(surf_glow);
if (surface_exists(surf_bloom_h))      surface_free(surf_bloom_h);
if (surface_exists(surf_bloom))        surface_free(surf_bloom);
if (surface_exists(surf_pass2))        surface_free(surf_pass2);