/// @description 
// Inherit the parent event
event_inherited();
randomize();

color_index = sprite_index;
emissive_index = sprite_index;
contracted_index = sprite_index;

//image_blend = make_color_hsv(random(255),random(128)+128,random(64)+64);
image_alpha = 1;
//emission_color = c_black;

function draw_emission_data(){
	draw_sprite_ext(color_index,image_index,x,y,image_xscale,image_yscale,image_angle,c_black,1);
}

function draw_occlusion_data(){
	draw_sprite_ext(color_index,image_index,x,y,image_xscale,image_yscale,image_angle,c_black,1);
}
