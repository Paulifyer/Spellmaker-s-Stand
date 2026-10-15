/// Wave configuration and generated-wave validation

/// @description Report an invalid wave configuration and stop the game
/// @param {string} _message
/// @returns {bool}
function wave_config_error(_message)
{
	show_error("Invalid wave configuration: " + _message, true);
	return false;
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
/// @description Find an enemy object in a level roster
/// @param {struct.LevelWaveConfig} _config
/// @param {object_asset} _enemy_object
/// @returns {real}
function wave_roster_index(_config, _enemy_object)
{
	for (var i = 0; i < array_length(_config.enemy_roster); i++)
	{
		if (_config.enemy_roster[i].enemy_object == _enemy_object)
		{
			return i;
		}
	}

	return -1;
}

/// @description Verify that generated waves obey their source configuration
/// @param {struct.LevelWaveConfig} _config
/// @param {array<WaveData>} _generated_waves
/// @returns {bool}
function validate_generated_waves(_config, _generated_waves)
{
	if (array_length(_generated_waves) != _config.wave_count)
	{
		return wave_config_error("the generator returned an incorrect number of waves");
	}

	var _roster_length = array_length(_config.enemy_roster);
	var _total_counts = array_create(_roster_length, 0);
	var _introduced_on_schedule = array_create(_roster_length, false);

	for (var _wave_index = 0; _wave_index < array_length(_generated_waves); _wave_index++)
	{
		var _wave_number = _wave_index + 1;
		var _wave_data = _generated_waves[_wave_index];
		var _wave_counts = array_create(_roster_length, 0);
		var _spent_budget = 0;

		if (array_length(_wave_data.enemy_array) < 1)
		{
			return wave_config_error("the generator created an empty wave " + string(_wave_number));
		}

		if (!variable_struct_exists(_wave_data, "enemy_groups")
		|| array_length(_wave_data.enemy_groups) < 1)
		{
			return wave_config_error("the generator created no spawn groups for wave " + string(_wave_number));
		}

		var _flattened_position = 0;
		var _previous_group_was_singleton = false;
		for (var _group_index = 0; _group_index < array_length(_wave_data.enemy_groups); _group_index++)
		{
			var _group = _wave_data.enemy_groups[_group_index];
			if (!is_struct(_group)
			|| !variable_struct_exists(_group, "enemy_array"))
			{
				return wave_config_error("wave " + string(_wave_number)
					+ " contains invalid spawn group data");
			}

			var _group_size = array_length(_group.enemy_array);

			if (_group_size < 1 || _group_size > MAX_WAVE_GROUP_SIZE)
			{
				return wave_config_error("wave " + string(_wave_number)
					+ " contains a spawn group with an invalid size");
			}

			if (_group_size == 1 && _previous_group_was_singleton)
			{
				return wave_config_error("wave " + string(_wave_number)
					+ " contains consecutive singleton spawn groups");
			}

			_previous_group_was_singleton = _group_size == 1;

			for (var _group_enemy_index = 0; _group_enemy_index < _group_size; _group_enemy_index++)
			{
				if (_flattened_position >= array_length(_wave_data.enemy_array)
				|| _group.enemy_array[_group_enemy_index] != _wave_data.enemy_array[_flattened_position])
				{
					return wave_config_error("wave " + string(_wave_number)
						+ " spawn groups do not match its generated enemy queue");
				}

				_flattened_position += 1;
			}

		}

		if (_flattened_position != array_length(_wave_data.enemy_array))
		{
			return wave_config_error("wave " + string(_wave_number)
				+ " spawn groups do not contain every generated enemy");
		}

		for (var i = 0; i < array_length(_wave_data.enemy_array); i++)
		{
			var _enemy_object = _wave_data.enemy_array[i];
			var _roster_index = wave_roster_index(_config, _enemy_object);
			if (_roster_index < 0)
			{
				return wave_config_error("wave " + string(_wave_number) + " contains an enemy outside its roster");
			}

			var _definition = _config.enemy_roster[_roster_index];
			if (_definition.intro_wave > _wave_number)
			{
				return wave_config_error(object_get_name(_enemy_object) + " appears before its intro_wave");
			}

			_wave_counts[_roster_index] += 1;
			_total_counts[_roster_index] += 1;
			_spent_budget += _definition.cost;

			if (_definition.intro_wave == _wave_number)
			{
				_introduced_on_schedule[_roster_index] = true;
			}
		}

		if (_spent_budget > wave_config_budget(_config, _wave_number))
		{
			return wave_config_error("wave " + string(_wave_number) + " exceeds its threat budget");
		}

		for (var j = 0; j < _roster_length; j++)
		{
			if (_wave_counts[j] > _config.enemy_roster[j].max_per_wave)
			{
				return wave_config_error(object_get_name(_config.enemy_roster[j].enemy_object)
					+ " exceeds max_per_wave in wave " + string(_wave_number));
			}
		}
	}

	for (var k = 0; k < _roster_length; k++)
	{
		if (_total_counts[k] < 1 || !_introduced_on_schedule[k])
		{
			return wave_config_error(object_get_name(_config.enemy_roster[k].enemy_object)
				+ " was not guaranteed on its intro_wave");
		}
	}

	return true;
}
