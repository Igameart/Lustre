/// @description Set up GI system

bg_color = layer_background_get_blend( layer_background_get_id(layer_get_id("Background") ));

TIME = 0;

room_speed = 60;

denoise = false;

gpu_set_tex_filter(false);
//display_reset(4,false);

WW = 255;//view_get_wport(view_current);
HH = 144;//view_get_hport(view_current);

tileColors = layer_tilemap_get_id(layer_get_id("Tiles_1"));
tileEmission = layer_tilemap_get_id(layer_get_id("Tiles_2"));

surface_resize(application_surface,WW,HH);

GI_EmissiveData = surface_create(WW,HH);
GI_ColourData = surface_create(WW,HH);
GI_LastFrameData = surface_create(WW,HH);

GI_VoronoiSeedSurf = surface_create(WW,HH);
GI_VoronoiDataSurf = surface_create(WW,HH);

GI_JumpFloodPass = GI_new_render_pass(WW,HH);

GI_JumpFloodPass.material = GI_new_material(GIMaterial,GI_JumpFlood_shd);

DEtrace(string(GI_JumpFloodPass));

//GI_PassArray = [];
GI_voronoi_passes = [];

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
        render_pass = GI_JumpFloodPass;
	}else{
        render_pass = GI_duplicate_render_pass(GI_JumpFloodPass);
	    //GI_pass_add_child(GI_PassArray,render_pass);
		
	    render_pass.material = render_pass.material.duplicate();
		render_pass.material.shader = GI_JumpFloodPass.material.shader;
	}
	
	array_push(GI_voronoi_passes,render_pass)

    // here we set the input texture for each pass, which is the previous pass, unless it's the first pass in which case it's
    // the seed texture.
    var input_texture = GI_VoronoiSeedSurf;
    if i > 0{
        input_texture = GI_voronoi_passes[i - 1].get_texture();
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

DEtrace("Total number of voronoi passes",array_length(GI_voronoi_passes));

distmod = 1;

GI_DistanceField = GI_new_render_pass(WW,HH);
GI_DistanceField.material = GI_new_material(GIMaterial,GI_DistanceField_shd);
GI_DistanceField.material.set_shader_param(GI_DistanceField.material.param,"u_dist_mod", distmod);


GI_GlobalIllum = GI_new_render_pass(WW,HH);
GI_GlobalIllum.material = GI_new_material(GIMaterial,GI_GlobalIllum_shd);

var mat = GI_GlobalIllum.material;
mat.set_shader_param(mat.param,"SCREEN_PIXEL_SIZE", [1/WW,1/HH]);
mat.set_shader_param(mat.param,"TIME", TIME);
mat.set_shader_param(mat.param,"u_resolution", [WW,HH] );
mat.set_shader_param(mat.param,"Iu_rays_per_pixel", 256);
mat.set_shader_param(mat.param,"u_dist_mod", distmod);
mat.set_shader_param(mat.param,"Iu_bounce", true);
mat.set_shader_param(mat.param,"u_emission_multi", 1.0);
mat.set_shader_param(mat.param,"u_emission_range", 10.0);
mat.set_shader_param(mat.param,"u_emission_dropoff", 2.0);
mat.set_shader_param(mat.param,"Iu_max_raymarch_steps", 32);

surface_set_target(GI_LastFrameData);
draw_clear(c_black);
surface_reset_target();

bloomSurf = surface_create(WW,HH);

function GI_bloom_blur_pass(surf){
	shader_set_uniform_f_array(shader_get_uniform(shader_current(),"size"),[WW,HH]);
	draw_surface(surf,0,0);
}

function GI_draw_bloom(surf){
	
	surface_set_target(bloomSurf)
	shader_set(GI_BloomX_shd);
	GI_bloom_blur_pass( surf );
	shader_reset();
	surface_reset_target()
	
	surface_set_target(bloomSurf)
	shader_set(GI_BloomY_shd);
	GI_bloom_blur_pass( bloomSurf );
	shader_reset();
	surface_reset_target()
	
	gpu_set_blendmode(bm_add);
	draw_surface(bloomSurf,0,0);
	gpu_set_blendmode(bm_normal);
	
}
