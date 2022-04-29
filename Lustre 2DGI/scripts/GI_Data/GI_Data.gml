globalvar GIPass;
GIPass = {
	buffer : noone,
	size : [0,0],
	child : [],
	material : noone,
	get_child : function (a){
		return (child[a]);
	},
	get_texture : function(){
		return buffer;
	},
	set_size : function(a){
		size = a;
	}
	
	
}

globalvar GIMaterial;
GIMaterial = {
	shader : noone,
	param : noone,
	set_shader_param : function(p,a,b){
		param = p;
		
		//DEtrace("Setting Shader Parameters", a, b );
		
		if param == noone DEtrace("ERROR: Param is noone");
		param[? a]=b;
		
	},
	duplicate : function(){
		var mat = GI_new_material(GIMaterial,shader);
		ds_map_copy(mat.param,param);
		DEtrace("Duplicating Material",string(param));
		return mat;
	}
}

globalvar GIViewport;
GIViewport = undefined;

function get_viewport(a){
	var WW,HH;
	WW = camera_get_view_width(view_camera[a]);
	HH = camera_get_view_height(view_camera[a]);
	if is_undefined(GIViewport){
		GIViewport = {
			size : [WW,HH]
		}
	}else GIViewport.size = [WW,HH]
	return GIViewport;
}

function GI_new_material(src,shd){
	var mat = struct_copy(src);
	mat.param = ds_map_create();
	mat.shader = shd;
	DEtrace("Creating new Material",mat);
	return mat;
}

function GI_new_render_pass(w,h){
	var pass = struct_copy(GIPass);
	pass.buffer = surface_create(w,h);
	return pass;
}

function GI_duplicate_render_pass(a){
	var w,h;
	w = surface_get_width(a.buffer);
	h = surface_get_height(a.buffer);
	var pass = struct_copy(a);
	pass.buffer = surface_create(w,h);
	DEtrace("Duplicating Render Pass",pass,w,h);
	return pass;
}

function GI_material_set_single_uniform(shader,param,val){
	
	//DEtrace("Setting Shader Parameters",param,val);
	
	if !is_undefined(param){
		var uni = shader_get_uniform(shader,param);
		if string_char_at(param,1)!="I"{
			if !is_array(val) shader_set_uniform_f(uni,val) else shader_set_uniform_f_array(uni,val);
		}else{
			if !is_array(val) shader_set_uniform_i(uni,val) else shader_set_uniform_i_array(uni,val);
		}
	}
}

function GI_material_set_uniforms(mat){
	var params = mat.param;
	
	if ds_map_size(params) == 0{ DEtrace("ERROR: No Parameters Found!", params); return undefined};
	
	var key = ds_map_find_first(params);
	var num = 0;
	do{
		var val = params[? key];
		GI_material_set_single_uniform(mat.shader,key,val);
		key = ds_map_find_next(params,key);
		num++;
	}until num>=ds_map_size(params);
	
}

function GI_render_set_stage(dat){
	var shd = shader_current();
	var sampler = shader_get_sampler_index(shd,dat[0]);
	texture_set_stage(sampler,dat[1]);
}

function GI_assign_texture_stages(stages){
	for (var j =0; j<array_length(stages);j++){
		var stage = stages[j];
		GI_render_set_stage(stage);
	}
}

function GI_render_passes(passes, input, stages){

	if is_array(passes)
	for (var i = 0; i<array_length(passes); i++){
		
		var pass = passes[i];
		
		var surf = pass.buffer;
		
		surface_set_target(surf);
		draw_clear_alpha(c_black,0);
		shader_set(pass.material.shader);
		GI_material_set_uniforms(pass.material);
		if is_array(stages){
			GI_assign_texture_stages(stages);
		}
		
		draw_surface(input,0,0);
		
		surface_reset_target();
		shader_reset();
		
		input = surf;
	}else{
		
		surf = passes.buffer;
		
		surface_set_target(surf);
		draw_clear_alpha(c_black,0);
		shader_set(passes.material.shader);
		GI_material_set_uniforms(passes.material);
		if is_array(stages){
			GI_assign_texture_stages(stages);
		}
		draw_surface(input,0,0);
		
		surface_reset_target();
		shader_reset();
		
		input = surf;
	}
	return input;
}
