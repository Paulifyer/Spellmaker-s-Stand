/// @description Enemy Parent

// Set the sprite to the sideways sprite
sprite_index = (hitstun_timer > 0 || stun_timer > 0) ? stun_sprite : walk_side_sprite;
	
// Ensures pull is set correctly
if (pull != undefined) enemy_update_pull(id);

// Ensures Force is executed correctly
if (force_push != undefined) enemy_update_force(id);

if (hitstun_timer > 0) {
	hitstun_timer--;	
}


combat_status_advance(id, 1);
if (mutation != undefined) mutation.on_step(id);

var _barrier_broken = get_village_hp() == 0;
if (_barrier_broken) is_stop_reached = false;
enemy_update_movement(id);

// Continue on foot after the path ends so enemies at the wall still have to cross it.
if (_barrier_broken && hp > 0 && !is_bonepile && x <= GRID_X0 && path_speed > 0
	&& !(object_index == obj_mole && emerged)) {
	var _advance = path_speed;
	if (path_index != -1) path_end();
	x -= _advance;
}

// Save it's current x and y
x_previous = x;
y_previous = y;

// Set image_speed as the ratio between my_speed and base_speed
image_speed = my_speed / base_speed;

var _frames = sprite_get_number(delay_spr);
delay_frame = (delay_frame + delay_speed) % _frames;
