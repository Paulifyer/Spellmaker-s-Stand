/// WaveScript Functions

/*
	These are functions used with the obj_wave_manager object to 
	create, start, and manage waves. With the exception of the constructor
	they all access instance variables in obj_wave_manager using with() 
	to ensure that an instance of obj_wave_manager exists.
*/

// This is the what we are using for our room speed (60 fps) as room_speed is discouraged
#macro TARGET_ROOM_SPEED 60

/// @description This function is a constructor that creates a struct that contains data for a wave
/// @param {array} _enemy_array 
/// @param {real} _wave_delay 
/// @returns {struct} 
function WaveData(_enemy_array, _wave_delay) constructor 
{
	// enemy_array should be an array of GameMaker Objects
	enemy_array = _enemy_array;
	
	// wave_delay should be the amount of time in frames you want to wait before spawning a new enemy
	wave_delay = _wave_delay;
}

/// @description Defines one enemy type that may be selected by a level's wave generator
/// @param {object_asset} _enemy_object
/// @param {real} _cost
/// @param {real} _weight
/// @param {real} _intro_wave
/// @param {real} _max_per_wave
function EnemyWaveDefinition(_enemy_object, _cost, _weight, _intro_wave, _max_per_wave) constructor
{
	enemy_object = _enemy_object;
	cost = _cost;
	weight = _weight;
	intro_wave = _intro_wave;
	max_per_wave = _max_per_wave;
}

/// @description Defines the standard-wave generation settings for one level
/// @param {real} _wave_count
/// @param {real} _starting_budget
/// @param {real} _ending_budget
/// @param {real} _difficulty_curve
/// @param {real} _starting_delay
/// @param {real} _minimum_delay
/// @param {array} _enemy_roster
function LevelWaveConfig(
	_wave_count,
	_starting_budget,
	_ending_budget,
	_difficulty_curve,
	_starting_delay,
	_minimum_delay,
	_enemy_roster
) constructor
{
	wave_count = _wave_count;
	starting_budget = _starting_budget;
	ending_budget = _ending_budget;
	difficulty_curve = _difficulty_curve;
	starting_delay = _starting_delay;
	minimum_delay = _minimum_delay;
	enemy_roster = _enemy_roster;
}

/// @description Report an invalid wave configuration and stop the game
/// @param {string} _message
/// @returns {bool}
function wave_config_error(_message)
{
	show_error("Invalid wave configuration: " + _message, true);
	return false;
}

/// @description Calculate the threat budget for a wave number
/// @param {struct.LevelWaveConfig} _config
/// @param {real} _wave_number
/// @returns {real}
function wave_config_budget(_config, _wave_number)
{
	var _progress = 0;
	if (_config.wave_count > 1)
	{
		_progress = (_wave_number - 1) / (_config.wave_count - 1);
	}

	return round(lerp(
		_config.starting_budget,
		_config.ending_budget,
		power(_progress, _config.difficulty_curve)
	));
}

/// @description Calculate the spawn delay for a wave number
/// @param {struct.LevelWaveConfig} _config
/// @param {real} _wave_number
/// @returns {real}
function wave_config_delay(_config, _wave_number)
{
	var _progress = 0;
	if (_config.wave_count > 1)
	{
		_progress = (_wave_number - 1) / (_config.wave_count - 1);
	}

	return max(1, round(lerp(
		_config.starting_delay,
		_config.minimum_delay,
		_progress
	)));
}

/// @description Validate a level's standard-wave generation settings
/// @param {struct.LevelWaveConfig} _config
/// @returns {bool}
function validate_wave_config(_config)
{
	if (!is_struct(_config))
	{
		return wave_config_error("the level configuration must be a struct");
	}

	if (_config.wave_count < 1 || floor(_config.wave_count) != _config.wave_count)
	{
		return wave_config_error("wave_count must be a positive integer");
	}

	if (_config.starting_budget < 1 || _config.ending_budget < _config.starting_budget)
	{
		return wave_config_error("budgets must be positive and ending_budget cannot be lower than starting_budget");
	}

	if (_config.difficulty_curve <= 0)
	{
		return wave_config_error("difficulty_curve must be greater than zero");
	}

	if (_config.starting_delay < 1 || _config.minimum_delay < 1 || _config.minimum_delay > _config.starting_delay)
	{
		return wave_config_error("spawn delays must be positive and minimum_delay cannot exceed starting_delay");
	}

	var _roster_length = array_length(_config.enemy_roster);
	if (_roster_length < 1)
	{
		return wave_config_error("enemy_roster must contain at least one enemy");
	}

	for (var i = 0; i < _roster_length; i++)
	{
		var _definition = _config.enemy_roster[i];

		if (!is_struct(_definition))
		{
			return wave_config_error("enemy roster entry " + string(i) + " must be a struct");
		}

		if (!object_exists(_definition.enemy_object))
		{
			return wave_config_error("enemy roster entry " + string(i) + " does not reference an object");
		}

		if (_definition.cost <= 0 || _definition.weight <= 0)
		{
			return wave_config_error(object_get_name(_definition.enemy_object) + " must have positive cost and weight");
		}

		if (_definition.intro_wave < 1
		|| _definition.intro_wave > _config.wave_count
		|| floor(_definition.intro_wave) != _definition.intro_wave)
		{
			return wave_config_error(object_get_name(_definition.enemy_object) + " has an invalid intro_wave");
		}

		if (_definition.max_per_wave < 1 || floor(_definition.max_per_wave) != _definition.max_per_wave)
		{
			return wave_config_error(object_get_name(_definition.enemy_object) + " must have a positive integer max_per_wave");
		}

		for (var j = i + 1; j < _roster_length; j++)
		{
			if (_config.enemy_roster[j].enemy_object == _definition.enemy_object)
			{
				return wave_config_error(object_get_name(_definition.enemy_object) + " appears more than once in enemy_roster");
			}
		}
	}

	for (var _wave_number = 1; _wave_number <= _config.wave_count; _wave_number++)
	{
		var _budget = wave_config_budget(_config, _wave_number);
		var _guaranteed_cost = 0;
		var _has_affordable_enemy = false;

		for (var k = 0; k < _roster_length; k++)
		{
			var _enemy = _config.enemy_roster[k];

			if (_enemy.intro_wave == _wave_number)
			{
				_guaranteed_cost += _enemy.cost;
			}

			if (_enemy.intro_wave <= _wave_number && _enemy.cost <= _budget)
			{
				_has_affordable_enemy = true;
			}
		}

		if (_guaranteed_cost > _budget)
		{
			return wave_config_error("guaranteed enemies exceed the budget for wave " + string(_wave_number));
		}

		if (!_has_affordable_enemy)
		{
			return wave_config_error("wave " + string(_wave_number) + " has no affordable eligible enemy");
		}
	}

	return true;
}

/// @description Start the next wave
function start_next_wave()
{

	// Uses with() to access the instance of obj_wave_manager.
	// with() only works if an instance of the object exists.
	with (obj_wave_manager)
	{
		// Assing the next wave struct to the current_wave_struct.
		// The position is wave - 1 because the waves start counting at 1, but arrays are zero indexed.
		current_wave_struct = wave_array[wave - 1];
		
		// This variable marks the current position in the enemy array
		// and will be increased each time an enemy is spawned
		position = 0;
		
		// This variable tells whether a wave is currently running
		wave_running = true;	
		
		// Spawn the first enemy in the wave
		event_perform(ev_alarm, 0);
	}
	
	// Create the wave start banner sequence
	layer_sequence_create("Sequences", 0, 0, seq_wave_start_banner);
}

/// @description Returns true if the wave is currently running, otherwise returns false
/// @returns bool
function wave_is_running()
{

	// Uses with() to access the instance of obj_wave_manager.
	// with() only works if an instance of the object exists.
	with (obj_wave_manager)
	{
		// Return the boolean value stored in the wave_running variable of obj_wave_manager.
		// return will end the function
		return wave_running;
	}
	
	// If we make it here, then there is no instance of obj_wave_manager to check,
	// so we will return false instead.
	return false;
}

/// @description Returns true if the waves are over, otherwise returns false
/// @returns bool
function waves_are_over()
{
	
	// Uses with() to access the instance of obj_wave_manager.
	// with() only works if an instance of the object exists.
	with (obj_wave_manager)
	{
		// Return the boolean value stored in the waves_over variable of obj_wave_manager.
		// return will end the function
		return waves_over;
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


