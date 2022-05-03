/// @description function container

function LU_bloom_blur_pass(surf){
	shader_set_uniform_f_array(shader_get_uniform(shader_current(),"size"),[WW,HH]);
	draw_surface(surf,0,0);
}

function LU_occupy_jumpflood(){
	LU_voronoi_passes = [];

	// number of passes required is the log2 of the largest viewport dimension rounded up to the nearest power of 2.
	// i.e. 768x512 is log2(1024) == 10
	var passes = ceil(log2(max(WW,HH)) / log2(2.0));

	// iterate through each pass and set up the required render pass objects.
	for (var i = 0; i<passes; i++){

	    // offset for each pass is half the previous one, starting at half the square resolution rounded up to nearest power 2.
	    // i.e. for 768x512 we round up to 1024x1024 and the offset for the first pass is 512x512, then 256x256, etc. 
	    var offset = power(2, passes - i - 1)

	    // on the first pass, use our existing render pass, on subsequent passes we duplicate the existing render pass.
	    var render_pass
	    if i == 0{
	        render_pass = LU_JumpFloodPass;
		}else{
	        render_pass = LU_duplicate_render_pass(LU_JumpFloodPass);
		    //LU_pass_add_child(LU_PassArray,render_pass);
		
		    render_pass.material = render_pass.material.duplicate();
			render_pass.material.shader = LU_JumpFloodPass.material.shader;
		}
	
		array_push(LU_voronoi_passes,render_pass)

	    // here we set the input texture for each pass, which is the previous pass, unless it's the first pass in which case it's
	    // the seed texture.
	    var input_texture = LU_VoronoiSeedSurf;
	    if i > 0{
	        input_texture = LU_voronoi_passes[i - 1].get_texture();
		}

	    // set size and shader uniforms for this pass.
	    render_pass.set_size(get_viewport(0).size);
		var Mat = render_pass.material;
	
		DEtrace("Checking Material Components",Mat);
	
	    Mat.set_shader_param(Mat.param,"u_level", i);
	    Mat.set_shader_param(Mat.param,"u_max_steps", passes);
	    Mat.set_shader_param(Mat.param,"u_offset", offset);
	    Mat.set_shader_param(Mat.param,"SCREEN_PIXEL_SIZE", [1/WW,1/HH]);
	}

	DEtrace("Total number of voronoi passes",array_length(LU_voronoi_passes));
}

function LU_draw_bloom(surf){
	
	surface_set_target(bloomSurf)
	shader_set(LU_BloomX_shd);
	LU_bloom_blur_pass( surf );
	shader_reset();
	surface_reset_target()
	
	surface_set_target(bloomSurf)
	shader_set(LU_BloomY_shd);
	LU_bloom_blur_pass( bloomSurf );
	shader_reset();
	surface_reset_target()
	
	gpu_set_blendmode(bm_add);
	draw_surface(bloomSurf,0,0);
	gpu_set_blendmode(bm_normal);
	
}

function LU_handler_init(){
	LU_tiles = ds_map_create();
	
	LU_tiles[? "COLOUR"] = array_create(1,noone);
	LU_tiles[? "EMISSION"] = [noone];
	LU_tiles[? "OCCLUSION"] = [noone];
}

function LU_add_tileset_to_pass( pass, tileset ){
	var p_dat = ds_map_find_value(LU_tiles,pass);
	var tSet = layer_get_id(tileset);
	
	DEtrace("Adding layer To Pass",room_get_name(room),tileset,tSet,pass);
	
	if !is_array(p_dat){
		DEtrace(string(p_dat));
	}
	
	array_push(p_dat,layer_tilemap_get_id(tSet));
	
}

function LU_capture_emission_data(){
	
	surface_set_target(LU_EmissiveData);
	camera_apply(view_camera[view_current]);
	draw_clear_alpha(c_black,0);

	//gpu_set_tex_filter(true);
	shader_set(LU_EmissivePacker_shd);
	var uni = shader_get_uniform(LU_EmissivePacker_shd,"u_is_passable");
	var uni2 = shader_get_uniform(LU_EmissivePacker_shd,"u_emission");
	
	shader_set_uniform_f(uni2,12.0);

	var tile_count = ds_list_size(LU_TileMaps);
	
	for (var t = 0; t<tile_count; t++){
		var tileMap = LU_TileMaps[| t];
		var tiledat = tileMap.emission;
		if tiledat!=noone{
			tilemap_tileset(tileMap.layerid,tiledat);
		    draw_tilemap(tileMap.layerid,0,0);
		}
	}

	with GIData_obj{
		shader_set_uniform_i(uni,light_passable);
		shader_set_uniform_f(uni2,emissive_strength * e_mul);
		
		draw_emission_data();
		
	}
	
	//gpu_set_tex_filter(false);
	
	shader_reset();

	surface_reset_target();
}

function LU_capture_voronoi_data(){
	
	surface_set_target(LU_VoronoiDataSurf);
	camera_apply(view_camera[view_current]);
	draw_clear_alpha(c_black,0);

	var tile_count = ds_list_size(LU_TileMaps);
	
	for (var t = 0; t<tile_count; t++){
		var tileMap = LU_TileMaps[| t];
		//DEtrace("Capturing Occlusion",tileMap);
		var tiledat = tileMap.occlusion;
		if tiledat!=noone{
			tilemap_tileset(tileMap.layerid,tiledat);
		    draw_tilemap(tileMap.layerid,0,0);
		}
	}

	//Use random identifier instead of just "solid" in blue channel to check when leaving an object
	with GIData_obj draw_occlusion_data();


	surface_reset_target();
}


function LU_capture_normal_data(){
	
	surface_set_target(LU_NormalDataSurf);
	camera_apply(view_camera[view_current]);
	draw_clear_alpha(c_black,0);

	var tile_count = ds_list_size(LU_TileMaps);
	
	shader_set(LU_NormalsTransform)
	
	for (var t = 0; t<tile_count; t++){
		var tileMap = LU_TileMaps[| t];
		var tiledat = tileMap.normal;
		if tiledat!=noone{
			tilemap_tileset(tileMap.layerid,tiledat);
		    draw_tilemap(tileMap.layerid,0,0);
		}
	}

	//Use random identifier instead of just "solid" in blue channel to check when leaving an object
	with GIData_obj{
		draw_normal_data();
	}

	shader_reset();
	surface_reset_target();
}

function LU_capture_colour_data(){
	
	surface_set_target(LU_ColourData);
	camera_apply(view_camera[view_current]);
	draw_clear_alpha(make_color_hsv(0,0,5),0);

	var tile_count = ds_list_size(LU_TileMaps);
	
	for (var t = 0; t<tile_count; t++){
		var tileMap = LU_TileMaps[| t];
		var tiledat = tileMap.colour;
		if tiledat!=noone{
			tilemap_tileset(tileMap.layerid,tiledat);
		    draw_tilemap(tileMap.layerid,0,0);
		}
	}


	//gpu_set_tex_filter(true);
	with GIData_obj draw_color_data();
	//gpu_set_tex_filter(false);

	surface_reset_target();
}

function LU_calculate_voronoi_seed(){
	
	surface_set_target(LU_VoronoiSeedSurf);
	draw_clear_alpha(0,0);
	shader_set(LU_VoronoiSeed_shd)
	shader_set_uniform_f_array(shader_get_uniform(LU_VoronoiSeed_shd,"SCREEN_PIXEL_SIZE"),[WW,HH]);
	draw_surface(LU_VoronoiDataSurf,0,0);
	shader_reset();
	surface_reset_target();
	
}

function LU_fill_render_passes(){
	
	surface_set_target(LU_NoiseDataSurf);
		draw_sprite_tiled(BNoise_spr,0,random(WW),random(HH));
	surface_reset_target();
	
	var jFlood = LU_render_pass_array(LU_voronoi_passes, LU_VoronoiSeedSurf,noone);

	var dField = LU_render_pass_array(LU_DistanceField, jFlood,noone);

	// TIME needs to update with each frame so we change the values here
	LU_GlobalIllum.material.set_shader_param(LU_GlobalIllum.material.param,"TIME", (TIME++)/256);

	var stages = [];
	array_push(stages,[ "u_scene_colour_data", surface_get_texture(LU_ColourData) ]);
	array_push(stages,[ "u_scene_emissive_data", surface_get_texture(LU_EmissiveData) ]);
	array_push(stages,[ "u_last_frame_data", surface_get_texture(LU_LastFrameData) ]);
	array_push(stages,[ "u_noise_data", surface_get_texture(LU_NoiseDataSurf) ]);
	array_push(stages,[ "u_normal_data", surface_get_texture(LU_NormalDataSurf) ]);
	array_push(stages,[ "u_flood_data", surface_get_texture(jFlood) ]);
	

	var GIRender = LU_render_pass_array(LU_GlobalIllum, dField,stages);
	
	return GIRender;
	
}

function LU_render_final(){

var GIRender = LU_fill_render_passes();

	var xx,yy;
	xx = camera_get_view_x(view_get_camera(view_current));
	yy = camera_get_view_y(view_get_camera(view_current));
	
	surface_set_target(LU_VoronoiDataSurf);
	
	draw_clear_alpha(c_black,0);
	
	if denoise = true{
		shader_set(glslSmartDenoise_shd);
		shader_set_uniform_f_array(shader_get_uniform(glslSmartDenoise_shd,"u_texture_size"),[WW,HH]);
	}

	draw_surface_ext(GIRender,xx,yy,1,1,0,c_white,1);
	//LU_draw_bloom(GIRender);

	if denoise = true
		shader_reset();
	surface_reset_target();

	//surface_copy(LU_LastFrameData,0,0,GIRender);
	surface_set_target(LU_LastFrameData);
	draw_surface_ext(GIRender,0,0,1,1,0,c_white,0.1);
	surface_reset_target();
	
	surface_set_target(application_surface);
	
	draw_sprite_ext(alienPlatformerBG_spr,0,-128,0,1,1,0,c_dkgray,1);
	
	shader_set(LU_Final_shd);
	var stage = shader_get_sampler_index(LU_Final_shd,"u_alpha");
	texture_set_stage(stage,surface_get_texture(LU_ColourData));
	
	shader_set_uniform_i( shader_get_uniform(LU_Final_shd,"render_type"),true);
	
	draw_surface(LU_VoronoiDataSurf,xx,yy);
	gpu_set_blendmode(bm_add);
	
	shader_set_uniform_i(shader_get_uniform(LU_Final_shd,"render_type"),false);
	
	draw_surface(LU_VoronoiDataSurf,xx,yy);
	shader_reset();
	
	gpu_set_blendmode(bm_normal);
	
	//draw_surface(LU_EmissiveData,xx,yy);
	
	surface_reset_target();

}


sine_array = [127, 130, 133, 136, 139, 142, 145, 148, 151, 154, 157, 161, 164, 166, 169, 172, 
175, 178, 181, 184, 187, 189, 192, 195, 197, 200, 202, 205, 207, 210, 212, 214, 
217, 219, 221, 223, 225, 227, 229, 231, 233, 234, 236, 237, 239, 240, 242, 243, 
244, 245, 247, 248, 249, 249, 250, 251, 252, 252, 253, 253, 253, 254, 254, 254, 
254, 254, 254, 254, 253, 253, 253, 252, 252, 251, 250, 249, 249, 248, 247, 245, 
244, 243, 242, 240, 239, 237, 236, 234, 233, 231, 229, 227, 225, 223, 221, 219, 
217, 214, 212, 210, 207, 205, 202, 200, 197, 195, 192, 189, 187, 184, 181, 178, 
175, 172, 169, 166, 164, 161, 157, 154, 151, 148, 145, 142, 139, 136, 133, 130, 
127, 124, 121, 118, 115, 112, 109, 106, 103, 100,  97,  93,  90,  88,  85,  82, 
 79,  76,  73,  70,  67,  65,  62,  59,  57,  54,  52,  49,  47,  44,  42,  40, 
 37,  35,  33,  31,  29,  27,  25,  23,  21,  20,  18,  17,  15,  14,  12,  11, 
 10,   9,   7,   6,   5,   5,   4,   3,   2,   2,   1,   1,   1,   0,   0,   0, 
  0,   0,   0,   0,   1,   1,   1,   2,   2,   3,   4,   5,   5,   6,   7,   9, 
 10,  11,  12,  14,  15,  17,  18,  20,  21,  23,  25,  27,  29,  31,  33,  35, 
 37,  40,  42,  44,  47,  49,  52,  54,  57,  59,  62,  65,  67,  70,  73,  76, 
 79,  82,  85,  88,  90,  93,  97, 100, 103, 106, 109, 112, 115, 118, 121, 124, 
0]
