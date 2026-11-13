if (hp <= 0) exit;

draw_self();

if (flash_alpha > 0) {
	shader_set(sh_hit_flash);
	draw_sprite_ext(sprite_index, image_index, x, y,
		image_xscale, image_yscale, image_angle, c_white, image_alpha * flash_alpha);
	shader_reset();
}
