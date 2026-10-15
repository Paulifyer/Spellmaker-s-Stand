/// WaveScript Functions

/*
	These are functions used with the obj_wave_manager object to 
	create, start, and manage waves. With the exception of the constructor
	they all access instance variables in obj_wave_manager using with() 
	to ensure that an instance of obj_wave_manager exists.
*/

// This is the what we are using for our room speed (60 fps) as room_speed is discouraged
#macro TARGET_ROOM_SPEED 60

enum WaveState
{
	WAITING,
	SPAWNING,
	CLEANUP,
	FINISHED
}

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

/// @description Create a seed for one generated level run
/// @returns {real}
function create_wave_run_seed()
{
	randomize();
	return irandom(2147483645) + 1;
}

/// @description Create the isolated random-number state used by wave generation
/// @param {real} _seed
/// @returns {struct}
function create_wave_random(_seed)
{
	var _safe_seed = abs(floor(_seed)) mod 2147483647;
	if (_safe_seed == 0)
	{
		_safe_seed = 1;
	}

	return { seed: _safe_seed };
}

/// @description Return a deterministic value in the range [0, 1)
/// @param {struct} _random
/// @returns {real}
function wave_random_next(_random)
{
	_random.seed = (_random.seed * 48271) mod 2147483647;
	return _random.seed / 2147483647;
}

/// @description Select an affordable enemy definition using its configured weight
/// @param {struct.LevelWaveConfig} _config
/// @param {real} _wave_number
/// @param {real} _remaining_budget
/// @param {array} _counts
/// @param {struct} _random
/// @returns {real}
function wave_select_enemy_index(_config, _wave_number, _remaining_budget, _counts, _random)
{
	var _total_weight = 0;
	var _roster_length = array_length(_config.enemy_roster);

	for (var i = 0; i < _roster_length; i++)
	{
		var _definition = _config.enemy_roster[i];
		if (_definition.intro_wave <= _wave_number
		&& _definition.cost <= _remaining_budget
		&& _counts[i] < _definition.max_per_wave)
		{
			_total_weight += _definition.weight;
		}
	}

	if (_total_weight <= 0)
	{
		return -1;
	}

	var _selection = wave_random_next(_random) * _total_weight;
	var _running_weight = 0;

	for (var j = 0; j < _roster_length; j++)
	{
		var _enemy = _config.enemy_roster[j];
		if (_enemy.intro_wave <= _wave_number
		&& _enemy.cost <= _remaining_budget
		&& _counts[j] < _enemy.max_per_wave)
		{
			_running_weight += _enemy.weight;
			if (_selection < _running_weight)
			{
				return j;
			}
		}
	}

	return -1;
}

/// @description Shuffle an enemy queue without using GameMaker's global random stream
/// @param {array} _enemy_array
/// @param {struct} _random
/// @returns {array}
function wave_shuffle_enemy_array(_enemy_array, _random)
{
	for (var i = array_length(_enemy_array) - 1; i > 0; i--)
	{
		var j = floor(wave_random_next(_random) * (i + 1));
		var _temporary = _enemy_array[i];
		_enemy_array[i] = _enemy_array[j];
		_enemy_array[j] = _temporary;
	}

	return _enemy_array;
}

/// @description Generate every standard wave for a level
/// @param {struct.LevelWaveConfig} _config
/// @param {real} _run_seed
/// @returns {array<WaveData>}
function generate_standard_waves(_config, _run_seed)
{
	validate_wave_config(_config);

	var _random = create_wave_random(_run_seed);
	var _generated_waves = [];
	var _roster_length = array_length(_config.enemy_roster);

	show_debug_message("Wave generation seed: " + string(_run_seed));

	for (var _wave_number = 1; _wave_number <= _config.wave_count; _wave_number++)
	{
		var _budget = wave_config_budget(_config, _wave_number);
		var _remaining_budget = _budget;
		var _enemy_array = [];
		var _counts = array_create(_roster_length, 0);

		// Guaranteed introductions are placed before any random selections.
		for (var i = 0; i < _roster_length; i++)
		{
			var _guaranteed_enemy = _config.enemy_roster[i];
			if (_guaranteed_enemy.intro_wave == _wave_number)
			{
				array_push(_enemy_array, _guaranteed_enemy.enemy_object);
				_counts[i] += 1;
				_remaining_budget -= _guaranteed_enemy.cost;
			}
		}

		while (_remaining_budget > 0)
		{
			var _selected_index = wave_select_enemy_index(
				_config,
				_wave_number,
				_remaining_budget,
				_counts,
				_random
			);

			if (_selected_index < 0)
			{
				break;
			}

			var _selected_enemy = _config.enemy_roster[_selected_index];
			array_push(_enemy_array, _selected_enemy.enemy_object);
			_counts[_selected_index] += 1;
			_remaining_budget -= _selected_enemy.cost;
		}

		_enemy_array = wave_shuffle_enemy_array(_enemy_array, _random);

		var _wave_data = new WaveData(
			_enemy_array,
			wave_config_delay(_config, _wave_number)
		);
		_wave_data.threat_budget = _budget;
		_wave_data.spent_budget = _budget - _remaining_budget;
		array_push(_generated_waves, _wave_data);
	}

	return _generated_waves;
}

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

/// @description Start the first wave or advance from cleanup to the next wave
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

	if (_manager.state == WaveState.CLEANUP)
	{
		return start_wave(_manager.wave + 1);
	}

	return false;
}

/// @description Complete cleanup and either start another wave or finish the level
/// @returns {bool}
function advance_wave()
{
	var _manager = instance_find(obj_wave_manager, 0);
	if (!instance_exists(_manager) || _manager.state != WaveState.CLEANUP)
	{
		return false;
	}

	if (_manager.wave < array_length(_manager.wave_array))
	{
		return start_wave(_manager.wave + 1);
	}

	_manager.alarm[0] = -1;
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


