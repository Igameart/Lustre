/// @description Render GI Surface

//draw_surface(GI_VoronoiSeedSurf,0,0);

gpu_set_tex_filter(true);
var jFlood = GI_render_passes(GI_voronoi_passes, GI_VoronoiSeedSurf,noone);
gpu_set_tex_filter(false);
var dField = GI_render_passes(GI_DistanceField, jFlood,noone);


// TIME needs to update with each frame so we change the values here
GI_GlobalIllum.material.set_shader_param(GI_GlobalIllum.material.param,"TIME", (TIME++)/256);

var stages = [];
array_push(stages,[ "u_scene_colour_data", surface_get_texture(GI_ColourData) ]);
array_push(stages,[ "u_scene_emissive_data", surface_get_texture(GI_EmissiveData) ]);
array_push(stages,[ "u_last_frame_data", surface_get_texture(GI_LastFrameData) ]);
array_push(stages,[ "u_flood_data", surface_get_texture(jFlood) ]);

var GIRender = GI_render_passes(GI_GlobalIllum, dField,stages);

//draw_surface_ext(GI_ColourData,0,0,1,1,0,c_black,1);

surface_set_target(application_surface);
if denoise = true{
	shader_set(glslSmartDenoise_shd);
	shader_set_uniform_f_array(shader_get_uniform(glslSmartDenoise_shd,"u_texture_size"),[WW,HH]);
}

var xx,yy;
xx = camera_get_view_x(view_get_camera(view_current));
yy = camera_get_view_y(view_get_camera(view_current));

draw_surface_ext(GIRender,xx,yy,1,1,0,c_white,1);
//GI_draw_bloom(GIRender);

if denoise = true
	shader_reset();
surface_reset_target();

surface_copy(GI_LastFrameData,0,0,GIRender);

//surface_set_target(GI_LastFrameData);
//draw_surface_ext(GIRender,0,0,1,1,0,c_white,1.5);
//surface_reset_target();
