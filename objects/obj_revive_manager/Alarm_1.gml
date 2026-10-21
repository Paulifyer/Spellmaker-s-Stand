///@description Revives the enemy without the skeletal modifier

if (instance_exists(_bones))
{
	instance_destroy(_bones);
}

var _enemy = instance_create_layer(ex, ey, "Instances", held_enemy);

// The revived enemy is no longer skeletal and must not create another revive.
_enemy.mutation = undefined;

if (instance_exists(wave_owner))
{
	_enemy.wave_owner = wave_owner;
}

with (_enemy) {
	path_start(other.e_path_index, my_speed, path_action_stop, true);
	path_position = other.e_path_position;
}

instance_destroy(id);
