/// @description Wave Manager 


/*
	This alarm spawns one member of the current group. Group members arrive with
	a short stagger, followed by the group's longer generated delay.
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

	if (group_enemy_position == 0)
	{
		if (_group_size > _lane_count)
		{
			show_error("Spawn group contains more enemies than the wave manager has lanes", true);
			exit;
		}

		// Shuffle once per group, then retain the result across staggered spawns.
		group_lane_indices = array_create(_lane_count, 0);
		for (var i = 0; i < _lane_count; i++)
		{
			group_lane_indices[i] = i;
		}

		for (var j = _lane_count - 1; j > 0; j--)
		{
			var _swap_index = irandom(j);
			var _temporary_lane = group_lane_indices[j];
			group_lane_indices[j] = group_lane_indices[_swap_index];
			group_lane_indices[_swap_index] = _temporary_lane;
		}
	}

	var _lane_index = group_lane_indices[group_enemy_position];
	var _enemy = instance_create_layer(
		x,
		y,
		layer,
		_enemy_group.enemy_array[group_enemy_position]
	);
	_enemy.wave_owner = id;
	_enemy.spawn_wave = wave;
	active_enemy_count += 1;

	with (_enemy)
	{
		path_start(other.level_paths[_lane_index], my_speed, path_action_stop, true);
	}

	group_enemy_position += 1;
	if (group_enemy_position < _group_size)
	{
		alarm[0] = max(1, round(TARGET_ROOM_SPEED * group_spawn_stagger_seconds));
	}
	else
	{
		// The group is complete. Reset its transient state before moving on.
		group_enemy_position = 0;
		group_lane_indices = [];
		position += 1;

		if (position < array_length(current_wave_struct.enemy_groups))
		{
			alarm[0] = max(1, round(TARGET_ROOM_SPEED * random_range(
				group_delay_min_seconds,
				group_delay_max_seconds
			)));
		}
		else
		{
			state = WaveState.CLEANUP;
		}
	}
}
