/// @description Set up GI system


event_user(0);

LU_handler_init();


bg_color = layer_background_get_blend( layer_background_get_id(layer_get_id("Background") ));

TIME = 0;

room_speed = 600;

denoise = true;

gpu_set_tex_filter(false);
//display_reset(4,false);

WW = camera_get_view_width(view_get_camera(view_current));
HH = camera_get_view_height(view_get_camera(view_current));

surface_resize(application_surface,WW,HH);

LU_EmissiveData = surface_create(WW,HH);
LU_ColourData = surface_create(WW,HH);
LU_LastFrameData = surface_create(WW,HH);

LU_VoronoiSeedSurf = surface_create(WW,HH);
LU_VoronoiDataSurf = surface_create(WW,HH);
LU_NormalDataSurf = surface_create(WW,HH);
LU_NoiseDataSurf = surface_create(WW,HH);

LU_JumpFloodPass = LU_new_render_pass(WW,HH);

LU_JumpFloodPass.material = LU_new_material(LU_Material,LU_JumpFlood_shd);

LU_voronoi_passes = [];

LU_occupy_jumpflood()

distmod = 10;

LU_DistanceField = LU_new_render_pass(WW,HH);
LU_DistanceField.material = LU_new_material(LU_Material,LU_DistanceField_shd);
LU_DistanceField.material.set_shader_param(LU_DistanceField.material.param,"u_dist_mod", distmod);


LU_GlobalIllum = LU_new_render_pass(WW,HH);
LU_GlobalIllum.material = LU_new_material(LU_Material,LU_GlobalIllum_shd);

var mat = LU_GlobalIllum.material;
mat.set_shader_param(mat.param,"SCREEN_PIXEL_SIZE", [1/WW,1/HH]);
mat.set_shader_param(mat.param,"TIME", TIME);
mat.set_shader_param(mat.param,"SKYLIGHT", 0.25);
mat.set_shader_param(mat.param,"u_resolution", [WW,HH] );
mat.set_shader_param(mat.param,"Iu_rays_per_pixel", 128);
mat.set_shader_param(mat.param,"u_dist_mod", distmod);
mat.set_shader_param(mat.param,"Iu_bounce", true);
mat.set_shader_param(mat.param,"u_emission_multi", 1.0);
mat.set_shader_param(mat.param,"u_emission_range", 10.0);
mat.set_shader_param(mat.param,"u_emission_dropoff", 2.0);
mat.set_shader_param(mat.param,"Iu_max_raymarch_steps", 32);
mat.set_shader_param(mat.param,"Iu_sin1000", sine_array);

surface_set_target(LU_LastFrameData);
draw_clear(c_black);
surface_reset_target();

//bloomSurf = surface_create(WW,HH);
