/// @description Enemy Parent

// Check if the enemies position on the path is greater than or equal to 1
// which means that it is at the end of the path

rock = enemy_detect_obstacle(id, detection_dist);
is_blocked = rock != noone && is_targetable;

if (path_position >= pos_to_stop || is_blocked)
{
	if (attack_sprite != undefined) sprite_index = attack_sprite;
	if (ready_to_attack && stun_timer <= 0 && hitstun_timer <= 0) {
		ready_to_attack = false
		is_stop_reached = path_position >= pos_to_stop;
		if (is_ranged) {
			enemy_shoot_prj(x, y, depth, damage_dealt, obj_arrow);
		} else {
			if (is_blocked) {
				rock.hp -= damage_dealt;
			} else {
				reduce_village_hp(damage_dealt);
			}
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
	if (!ready_to_attack && stun_timer <= 0 && hitstun_timer <= 0 && alarm[0] <= 0) {
		alarm[0] = TARGET_ROOM_SPEED * attack_delay * (1 + slow_amt);
	}
}
