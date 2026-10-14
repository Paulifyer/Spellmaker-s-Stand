/// @description Enemy Ranger

// Set the enemy's speed
// Because the enemy is on path, we need to use path_speed instead of speed
path_speed = my_speed;

// Check if the enemies position on the path is greater than or equal to 1
// which means that it is at the end of the path
if (path_position >= 0.6 && path_position <= 0.7)
{
	my_speed = 0;
	base_speed = 0;
	if (ready_to_attack && stun_timer < 0) {
		reduce_village_hp(damage_dealt);
		ready_to_attack = false;
		alarm[0] = TARGET_ROOM_SPEED * attack_delay * (1 + slow_amt);
		with (instance_create_depth(x, y - 100, depth, obj_arrow)) {
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
}