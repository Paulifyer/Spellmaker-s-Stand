/// @description Enemy Parent

rock = enemy_detect_obstacle(id, detection_dist);
is_blocked = rock != noone && is_targetable;

var _barrier_broken = get_village_hp() == 0;
var _at_barrier = false;
if (!_barrier_broken && pull == undefined && force_push == undefined) {
	if (is_ranged) {
		_at_barrier = path_position >= pos_to_stop;
	} else {
		var _barrier = instance_find(obj_barrier, 0);
		_at_barrier = instance_exists(_barrier) ? x <= _barrier.front_x : path_position >= pos_to_stop;
	}
}
is_stop_reached = _at_barrier;

// Siege impacts resolve after spell effects in the gameplay manager.
if ((_at_barrier && object_index != obj_siege_beast) || is_blocked)
{
	if (attack_sprite != undefined) sprite_index = attack_sprite;
	if (ready_to_attack && stun_timer <= 0 && hitstun_timer <= 0) {
		ready_to_attack = false
		if (is_ranged && !_barrier_broken) {
			enemy_shoot_prj(x, y, depth, damage_dealt, range_obj);
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
