/// @description Enemy Parent

// Check if the enemies position on the path is greater than or equal to 1
// which means that it is at the end of the path


if (path_position >= 1)
{
	if (attack_sprite != undefined) sprite_index = attack_sprite;
	if (ready_to_attack && stun_timer <= 0) {
		reduce_village_hp(damage_dealt);
		ready_to_attack = false;
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