/// Wave configuration and generated-wave validation

/// @description Report an invalid wave configuration and stop the game
/// @param {string} _message
/// @returns {bool}
function wave_config_error(_message)
{
	show_error("Invalid wave configuration: " + _message, true);
	return false;
}

/// @description Validate one scalar-or-per-wave enemy setting
/// @param {real|array} _setting
/// @param {real} _wave_count
/// @param {string} _setting_name
/// @param {string} _enemy_name
/// @returns {bool}
function validate_wave_setting(_setting, _wave_count, _setting_name, _enemy_name)
{
	if (is_array(_setting))
	{
		if (array_length(_setting) != _wave_count)
		{
			return wave_config_error(
				_enemy_name + " " + _setting_name
				+ " array must contain exactly " + string(_wave_count) + " entries"
			);
		}

		for (var i = 0; i < _wave_count; i++)
		{
			if (!is_real(_setting[i]))
			{
				return wave_config_error(
					_enemy_name + " " + _setting_name
					+ " contains a non-numeric value for wave " + string(i + 1)
				);
			}
		}

		return true;
	}

	if (!is_real(_setting))
	{
		return wave_config_error(
			_enemy_name + " " + _setting_name + " must be a number or array"
		);
	}

	return true;
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

		var _enemy_name = object_get_name(_definition.enemy_object);

		if (_definition.cost <= 0)
		{
			return wave_config_error(_enemy_name + " must have a positive cost");
		}
		
		try { normalize_mutation_keys(_definition.mutation); }
		catch (_error) { return wave_config_error("Roster entry " + string(i) + ": " + string(_error)); }

		if (!validate_wave_setting(
			_definition.weight_setting,
			_config.wave_count,
			"weight",
			_enemy_name
		))
		{
			return false;
		}

		if (!validate_wave_setting(
			_definition.min_setting,
			_config.wave_count,
			"minimum",
			_enemy_name
		))
		{
			return false;
		}

		if (!validate_wave_setting(
			_definition.max_setting,
			_config.wave_count,
			"maximum",
			_enemy_name
		))
		{
			return false;
		}

		//for (var j = i + 1; j < _roster_length; j++)
		//{
		//	if (_config.enemy_roster[j].enemy_object == _definition.enemy_object)
		//	{
		//		wave_config_error(object_get_name(_definition.enemy_object) + " appears more than once in enemy_roster");
		//		return true;
		//	}
		//}
	}

	for (var _wave_number = 1; _wave_number <= _config.wave_count; _wave_number++)
	{
		var _budget = wave_config_budget(_config, _wave_number);
		var _minimum_cost = 0;
		var _minimum_count = 0;

		for (var k = 0; k < _roster_length; k++)
		{
			var _enemy = _config.enemy_roster[k];
			var _enemy_name = object_get_name(_enemy.enemy_object);
			var _weight = wave_enemy_weight(_enemy, _wave_number);
			var _minimum = wave_enemy_min(_enemy, _wave_number);
			var _maximum = wave_enemy_max(_enemy, _wave_number);

			if (_weight < 0)
			{
				return wave_config_error(
					_enemy_name + " has a negative weight for wave " + string(_wave_number)
				);
			}

			if (_minimum < 0 || floor(_minimum) != _minimum)
			{
				return wave_config_error(
					_enemy_name + " minimum must be a non-negative integer for wave "
					+ string(_wave_number)
				);
			}

			if (_maximum < 0 || floor(_maximum) != _maximum)
			{
				return wave_config_error(
					_enemy_name + " maximum must be a non-negative integer for wave "
					+ string(_wave_number)
				);
			}

			if (_minimum > _maximum)
			{
				return wave_config_error(
					_enemy_name + " minimum exceeds its maximum for wave "
					+ string(_wave_number)
				);
			}

			if (_maximum == 0 && _weight > 0)
			{
				return wave_config_error(
					_enemy_name + " has positive weight but a zero maximum for wave "
					+ string(_wave_number)
				);
			}

			_minimum_cost += _minimum * _enemy.cost;
			_minimum_count += _minimum;
		}

		if (_minimum_cost > _budget)
		{
			return wave_config_error(
				"minimum enemies exceed the budget for wave " + string(_wave_number)
			);
		}

		var _remaining_budget = _budget - _minimum_cost;
		var _has_selectable_enemy = false;
		for (var m = 0; m < _roster_length; m++)
		{
			var _selectable = _config.enemy_roster[m];
			if (wave_enemy_weight(_selectable, _wave_number) > 0
			&& wave_enemy_min(_selectable, _wave_number) < wave_enemy_max(_selectable, _wave_number)
			&& _selectable.cost <= _remaining_budget)
			{
				_has_selectable_enemy = true;
				break;
			}
		}

		if (_minimum_count <= 0 && !_has_selectable_enemy)
		{
			return wave_config_error(
				"wave " + string(_wave_number) + " cannot generate any enemies"
			);
		}
	}

	return true;
}
