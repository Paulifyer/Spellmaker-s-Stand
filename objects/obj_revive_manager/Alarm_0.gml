///@description spawns the bonepile

enemy_age_status(status_state, round(spawn_delay * TARGET_ROOM_SPEED));
_bones = instance_create_layer(ex, ey, "Instances", obj_bonepile);
_bones.wave_owner = wave_owner;
enemy_bind_lineage(_bones, lineage);
bones_spawned = true;
// Delayed spell deliveries remain independent of inherited statuses.
if (tune_setting("mutations", "skeletal", "transfer_status", true) != false) {
	enemy_restore_status(_bones, status_state);
}
combat_flush_lineage(lineage);
// A delayed killing blow can destroy the pile immediately on appearance.
if (_bones.hp <= 0) {
	instance_destroy(_bones);
	instance_destroy(id);
	exit;
}
alarm[1] = revive_delay * TARGET_ROOM_SPEED;
