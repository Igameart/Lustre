/// @description 
rot_spd = 3;//random_range(0.25,3);

emissive_index = noone;
color_index = noone;
emission_color = c_white;
density = 24;

identifier = random_range(1,255)/255;

emissive_strength = 0;

e_mul = 1.0;

light_passable = false;

function draw_emission_data(){
	//draw_text_transformed(x,y-sprite_height/2-3,string(emissive_strength),3,3,90);
	draw_sprite_ext(emissive_index,image_index,x,y,image_xscale,image_yscale,image_angle,c_white,1);
}

function draw_occlusion_data(){
	var r,g,b;
	r = density;
	g = 0;
	b = 0;
	var col = make_color_rgb(r,g,b);
	draw_sprite_ext(contracted_index,image_index,x,y,image_xscale,image_yscale,image_angle,col,1);
}

function draw_normal_data(){
	var r,g,b;
	r = 0.5;
	g = 0.5;
	b = 0;
	var col = make_color_rgb(r,g,b);
	draw_sprite_ext(contracted_index,image_index,x,y,image_xscale,image_yscale,image_angle,col,1);
}

function draw_color_data(){
	draw_sprite_ext(color_index,image_index,x,y,image_xscale,image_yscale,image_angle,image_blend,image_alpha);
}
