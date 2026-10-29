/// @description Enemy Mole

rock = enemy_detect_obstacle(id, detection_dist);
is_blocked = rock != noone && is_targetable; // Can only e blocked if targettable/emerged


// This is to prevent the mole from emerging on a rock
if (pull == undefined && place_meeting(path_get_x(path_index, pos_to_stop), y, obj_rock)) {
	pos_to_stop -= 1/13;
} else {
	pos_to_stop = base_pos_to_stop;
}

// Check if the enemies position on the path is greater than or equal to 1
// which means that it is at the end of the path
if (path_position >= pos_to_stop || is_blocked)
{
	if (!emerged) {
		emerged = true;
		path_position = pos_to_stop;
		path_speed = 0;
		if (is_struct(emergence_marker)) {
			x = emergence_marker.x; y = emergence_marker.y;
			emergence_marker.active = false;
		}
	}
	my_speed = 0;
	is_stop_reached = path_position >= pos_to_stop;
	is_targetable = true;
	walk_side_sprite = normal_sprite;
	if (ready_to_attack && stun_timer <= 0) {
		ready_to_attack = false;
		var _arrow = instance_create_depth(x, y - 100, depth, obj_arrow)
		with (_arrow) {
			// Set image_angle using point_direction to get the direction to the target 
			// We are offsetting the target's y value because we don't want to shoot at the target's feet
			image_angle = point_direction(x, y, -x, y);
			
			// Set the direction to be the same as the image_angle
			direction = image_angle;
			
			// Create a layer for our arrow fire sequence so it will be at the right depth
			var _layer = layer_create(-(y + 105));
			
			// Create a sequence on that layer
			var _seq = layer_sequence_create(_layer, x, y, seq_arrow_fire);
			
			//Set the sequence's angle to be the same as the arrows
			layer_sequence_angle(_seq, image_angle);
			
			damage = other.damage_dealt;
		}

		switch (object_index) {
			case obj_mook:
				audio_play_sound(choose(snd_zombie_groan_01, snd_zombie_groan_02, snd_zombie_groan_03), 10, false);
				break;
			case obj_brute:
				audio_play_sound(choose(snd_frankenstein_groan_01, snd_frankenstein_groan_02, snd_frankenstein_groan_03), 10, false);				
				break;
			default:
				break;
		}
	}
	if (!ready_to_attack && stun_timer <= 0 && alarm[0] <= 0) {
		alarm[0] = TARGET_ROOM_SPEED * attack_delay * (1 + slow_amt);
	}
}
