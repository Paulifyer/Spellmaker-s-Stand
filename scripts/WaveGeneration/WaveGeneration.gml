/// Standard wave generation

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

/// @description Select an affordable enemy definition using its configured weight
/// @param {struct.LevelWaveConfig} _config
/// @param {real} _wave_number
/// @param {real} _remaining_budget
/// @param {array} _counts
/// @returns {real}
function wave_select_enemy_index(_config, _wave_number, _remaining_budget, _counts)
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

	var _selection = random(_total_weight);
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

/// @description Split a generated enemy queue into varied spawn groups
/// @param {array} _enemy_array
/// @returns {array}
function generate_standard_wave_groups(_enemy_array)
{
	var _groups = [];
	var _position = 0;
	var _enemy_count = array_length(_enemy_array);

	while (_position < _enemy_count)
	{
		var _remaining = _enemy_count - _position;
		var _maximum_size = min(MAX_WAVE_GROUP_SIZE, _remaining);
		var _group_size = _remaining == 1 ? 1 : irandom_range(2, _maximum_size);

		// Avoid leaving a one-enemy final group when the enemies can fit together.
		if (_remaining - _group_size == 1)
		{
			_group_size = _remaining <= MAX_WAVE_GROUP_SIZE
				? _remaining
				: _group_size - 1;
		}

		var _group = [];
		for (var i = 0; i < _group_size; i++)
		{
			array_push(_group, _enemy_array[_position + i]);
		}

		array_push(_groups, _group);
		_position += _group_size;
	}

	return _groups;
}

/// @description Generate every standard wave for a level
/// @param {struct.LevelWaveConfig} _config
/// @returns {array}
function generate_standard_waves(_config)
{
	validate_wave_config(_config);
	randomize();

	var _generated_waves = [];
	var _roster_length = array_length(_config.enemy_roster);

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
				_counts
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

		_enemy_array = array_shuffle(_enemy_array);
		var _enemy_groups = generate_standard_wave_groups(_enemy_array);
		array_push(_generated_waves, _enemy_groups);
	}

	return _generated_waves;
}
