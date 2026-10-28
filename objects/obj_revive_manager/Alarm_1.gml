///@description Revives the enemy without the skeletal modifier

// A destroyed or lethally damaged pile must never revive, including on this frame.
if (!instance_exists(_bones)) {
	instance_destroy(id);
	exit;
}
if (_bones.hp <= 0)
{
	instance_destroy(_bones);
	instance_destroy(id);
	exit;
}

var _status = enemy_capture_status(_bones);
// Hand the same active-enemy slot to the replacement instead of counting a death.
_bones.wave_owner = noone;
_bones.combat_lineage = undefined;
instance_destroy(_bones);
var _enemy = instance_create_layer(ex, ey, "Instances", held_enemy);
enemy_bind_lineage(_enemy, lineage);
enemy_restore_status(_enemy, _status);

// The revived enemy is no longer skeletal and must not create another revive.
var _retained = variable_instance_exists(id, "revived_mutations") ? revived_mutations : [];
enemy_apply_mutations(_enemy, _retained);

if (instance_exists(wave_owner))
{
	_enemy.wave_owner = wave_owner;
}

with (_enemy) {
	path_start(other.e_path_index, (stun_timer > 0) ? 0 : my_speed, path_action_stop, true);
	path_position = other.e_path_position;
}
enemy_initialize_mole_marker(_enemy, e_path_index);

instance_destroy(id);
