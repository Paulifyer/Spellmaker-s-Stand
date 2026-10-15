/// @description Wave Manager 


/*
	This alarm will spawn the next enemy in the wave and reset itself
	only if the current position in the wave is less than the length of the enemy_array.
*/


// Ignore stale alarms after the wave has stopped or the game has ended.
if (state != WaveState.SPAWNING)
{
	exit;
}

// Check if the current position is less than the length of the enemy array in the current wave
if (position < array_length(current_wave_struct.enemy_array))
{	
	var lane_index = irandom(array_length(level_paths) - 1);

	// Create the enemy and record which manager owns its lifecycle.
	var _enemy = instance_create_layer(x, y, layer, current_wave_struct.enemy_array[position]);
	_enemy.wave_owner = id;
	_enemy.spawn_wave = wave;
	active_enemy_count += 1;

	with (_enemy)
	{
		// So that we can start it on the path
		path_start(other.level_paths[lane_index], my_speed, path_action_stop, true);
	}	
	
	// Increase the position variable so that next time we spawn the next enemy
	position += 1;
	
	// Schedule another spawn only while entries remain in this queue.
	if (position < array_length(current_wave_struct.enemy_array))
	{
		alarm[0] = current_wave_struct.wave_delay;
	}
	else
	{
		state = WaveState.CLEANUP;
	}
}
