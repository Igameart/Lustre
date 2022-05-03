/// @description 

step += stepSpd;

if step > 255 step = 0;

//emissive_strength = (0.55 + sin(step)*0.5);

h = color_get_hue(image_blend);
s = color_get_saturation(image_blend);
v = color_get_value(image_blend);

h = step;

image_blend = make_color_hsv(h,s,v);
