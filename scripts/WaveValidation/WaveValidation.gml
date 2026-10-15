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
