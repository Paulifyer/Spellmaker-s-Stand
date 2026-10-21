

held_enemy = obj_enemy_parent;
wave_owner = noone;

e_path_index = 0;
e_path_position = 0;
ex = 0;
ey = 0;

spawn_delay = 1;
revive_delay = 3;

_bones = noone;
bones_spawned = false;

alarm[0] = spawn_delay * TARGET_ROOM_SPEED;
