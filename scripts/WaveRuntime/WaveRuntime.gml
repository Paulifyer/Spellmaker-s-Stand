/// Wave runtime lifecycle

/// @description Start a specific one-based wave number
/// @param {real} _wave_number
/// @returns {bool}
function start_wave(_wave_number)
{
	var _manager = instance_find(obj_wave_manager, 0);
	if (!instance_exists(_manager))
	{
		return false;
	}

	if (_wave_number < 1 || _wave_number > array_length(_manager.wave_array))
	{
		show_debug_message("Cannot start wave " + string(_wave_number) + ": wave number is out of range");
		return false;
	}

	if (_manager.state == WaveState.SPAWNING || _manager.state == WaveState.FINISHED)
	{
		return false;
	}

	_manager.alarm[0] = -1;
	_manager.wave = _wave_number;
	_manager.current_wave_struct = _manager.wave_array[_wave_number - 1];
	_manager.position = 0;
	_manager.group_enemy_position = 0;
	_manager.group_lane_indices = [];
	_manager.intermission_timer = 0;
	_manager.state = WaveState.SPAWNING;
	_manager.wave_running = true;
	_manager.waves_over = false;

	with (_manager)
	{
		event_perform(ev_alarm, 0);
	}

	layer_sequence_create("Sequences", 0, 0, seq_wave_start_banner);
	return true;
}

/// @description Start the first wave or manually advance to the next wave
/// @returns {bool}
function start_next_wave()
{
	var _manager = instance_find(obj_wave_manager, 0);
	if (!instance_exists(_manager))
	{
		return false;
	}

	if (_manager.state == WaveState.WAITING)
	{
		return start_wave(_manager.wave);
	}

	if (_manager.state == WaveState.CLEANUP
	|| _manager.state == WaveState.INTERMISSION)
	{
		return start_wave(_manager.wave + 1);
	}

	return false;
}

/// @description Complete cleanup or intermission and advance the level lifecycle
/// @returns {bool}
function advance_wave()
{
	var _manager = instance_find(obj_wave_manager, 0);
	if (!instance_exists(_manager)
	|| (_manager.state != WaveState.CLEANUP
	&& _manager.state != WaveState.INTERMISSION))
	{
		return false;
	}

	if (_manager.wave < array_length(_manager.wave_array))
	{
		return start_wave(_manager.wave + 1);
	}

	_manager.alarm[0] = -1;
	_manager.intermission_timer = 0;
	_manager.state = WaveState.FINISHED;
	_manager.wave_running = false;
	_manager.waves_over = true;
	instance_destroy(obj_button_wave_skip);
	return true;
}

/// @description Returns true if the wave is currently running, otherwise returns false
/// @returns bool
function wave_is_running()
{
	var _manager = instance_find(obj_wave_manager, 0);
	if (instance_exists(_manager))
	{
		return _manager.state == WaveState.SPAWNING
			|| _manager.state == WaveState.CLEANUP;
	}

	// If we make it here, then there is no instance of obj_wave_manager to check,
	// so we will return false instead.
	return false;
}

/// @description Returns true if the waves are over, otherwise returns false
/// @returns bool
function waves_are_over()
{
	var _manager = instance_find(obj_wave_manager, 0);
	if (instance_exists(_manager))
	{
		return _manager.state == WaveState.FINISHED;
	}

	// If we make it here, then there is no instance of obj_wave_manager to check,
	// so we will return false instead.
	return false;
}

/// @description Returns the current wave number
/// @returns {real}
function return_wave_number()
{

	// Uses with() to access the instance of obj_wave_manager.
	// with() only works if an instance of the object exists.
	with (obj_wave_manager)
	{
		// Return the number stored in the wave variable of obj_wave_manager.
		// return will end the function
		return wave;
	}

	// If we make it here, then there is no instance of obj_wave_manager to check,
	// so we will return -1 instead.
	return -1;
}
