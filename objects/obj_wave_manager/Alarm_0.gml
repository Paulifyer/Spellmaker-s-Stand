/// @description Wave Manager 


/*
	This alarm spawns every enemy in the next group at the same time. It resets
	itself only while another group remains in the current wave.
*/


// Ignore stale alarms after the wave has stopped or the game has ended.
if (state != WaveState.SPAWNING)
{
	exit;
}

if (position < array_length(current_wave_struct.enemy_groups))
{
	var _enemy_group = current_wave_struct.enemy_groups[position];
	var _group_size = array_length(_enemy_group.enemy_array);
	var _lane_count = array_length(level_paths);

	if (_group_size > _lane_count)
	{
		show_error("Spawn group contains more enemies than the wave manager has lanes", true);
		exit;
	}

	// Shuffle all lane indices, then consume each index once so enemies in this
	// group always enter on distinct lanes.
	var _lane_indices = array_create(_lane_count, 0);
	for (var i = 0; i < _lane_count; i++)
	{
		_lane_indices[i] = i;
	}

	for (var j = _lane_count - 1; j > 0; j--)
	{
		var _swap_index = irandom(j);
		var _temporary_lane = _lane_indices[j];
		_lane_indices[j] = _lane_indices[_swap_index];
		_lane_indices[_swap_index] = _temporary_lane;
	}

	for (var k = 0; k < _group_size; k++)
	{
		var _lane_index = _lane_indices[k];
		var _enemy = instance_create_layer(x, y, layer, _enemy_group.enemy_array[k]);
		_enemy.wave_owner = id;
		_enemy.spawn_wave = wave;
		active_enemy_count += 1;

		with (_enemy)
		{
			path_start(other.level_paths[_lane_index], my_speed, path_action_stop, true);
		}
	}

	position += 1;

	// Each generated group owns its varied delay before the next group.
	if (position < array_length(current_wave_struct.enemy_groups))
	{
		alarm[0] = _enemy_group.delay_after;
	}
	else
	{
		state = WaveState.CLEANUP;
	}
}
