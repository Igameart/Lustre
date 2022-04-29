/// @description Capture GI Data

surface_set_target(GI_EmissiveData);
camera_apply(view_camera[view_current]);
draw_clear_alpha(c_black,0);

//gpu_set_tex_filter(true);
shader_set(GI_EmissivePacker_shd);
var uni = shader_get_uniform(GI_EmissivePacker_shd,"u_emission")

with GIData_obj{
	shader_set_uniform_f(uni,emissive_strength);
	draw_emission_data();
}
//gpu_set_tex_filter(false);
shader_reset();

surface_reset_target();

surface_set_target(GI_VoronoiDataSurf);
camera_apply(view_camera[view_current]);
draw_clear_alpha(c_black,0);

if tileEmission!=-1
    draw_tilemap(tileEmission,0,0);

//Use random identifier instead of just "solid" in blue channel to check when leaving an object
with GIData_obj draw_occlusion_data();


surface_reset_target();

surface_set_target(GI_ColourData);
camera_apply(view_camera[view_current]);
draw_clear_alpha(bg_color,1);
if tileColors!=-1
    draw_tilemap(tileColors,0,0);

gpu_set_tex_filter(true);
with GIData_obj draw_color_data();
gpu_set_tex_filter(false);

surface_reset_target();

surface_set_target(GI_VoronoiSeedSurf);
draw_clear_alpha(0,0);
shader_set(GI_VoronoiSeed_shd)
shader_set_uniform_f_array(shader_get_uniform(GI_VoronoiSeed_shd,"SCREEN_PIXEL_SIZE"),[WW,HH]);
draw_surface(GI_VoronoiDataSurf,0,0);
shader_reset();
surface_reset_target();

window_set_caption("FPS_REAL:"+string(fps));
