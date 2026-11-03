/// @description Mole movement and animation
event_inherited();

// The parent ties animation to movement speed; surfaced moles animate at rest.
if (emerged) {
	my_speed = 0;
	path_speed = 0;
	sprite_index = emerging ? emerge_sprite : normal_sprite;
	image_speed = 1;
}
