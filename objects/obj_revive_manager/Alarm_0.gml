///@description spawns the bonepile

_bones = instance_create_layer(ex, ey, "Instances", obj_bonepile);
bones_spawned = true;
alarm[1] = revive_delay * TARGET_ROOM_SPEED;