/// @description Finish emerging once, then use the normal animation
if (emerging && sprite_index == emerge_sprite) {
	emerging = false;
	walk_side_sprite = normal_sprite;
	sprite_index = normal_sprite;
	image_index = 0;
	image_speed = 1;
}
