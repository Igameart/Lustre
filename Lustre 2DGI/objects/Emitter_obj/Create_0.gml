/// @description 
event_inherited();

image_blend = make_color_hsv(random(255),200,255);
image_alpha = 1;
emissive_strength = 1;

e_mul = random_range(0.5,8)*4;

emissive_index = circle_spr;
color_index = sprite_index;
contracted_index = circle_spr;
emission_color = c_white;

step = random(1);

stepSpd = random_range(0.05,0.2)/2;

x = round(x/3)*3;
y = round(y/3)*3;

image_xscale = next_p2(image_xscale);
image_yscale = next_p2(image_yscale);

/*
function draw_emission_data(){
	var blend = merge_color(c_black,c_white,clamp(emissive_strength,0,1));
	draw_circle_color(x,y,sprite_width/2,blend,blend,0);
}

function draw_color_data(){
	draw_circle_color(x,y,sprite_width/2,image_blend,image_blend,0);
}

function draw_occlusion_data(){
	draw_circle_color(x,y,sprite_width/2,image_blend,image_blend,0);
}*/
