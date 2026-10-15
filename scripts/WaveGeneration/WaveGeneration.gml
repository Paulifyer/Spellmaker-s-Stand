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

/// @description Calculate the base threat target for one simultaneous spawn group
/// @param {struct.LevelWaveConfig} _config
/// @param {real} _wave_number
/// @returns {real}
function wave_group_base_threat(_config, _wave_number)
{
	var _progress = 0;
	if (_config.wave_count > 1)
	{
		_progress = (_wave_number - 1) / (_config.wave_count - 1);
	}

	return lerp(2.5, 6, _progress);
}

/// @description Calculate a varied threat target for the next simultaneous spawn group
/// @param {struct.LevelWaveConfig} _config
/// @param {real} _wave_number
/// @param {struct} _random
/// @returns {real}
function wave_group_target_threat(_config, _wave_number, _random)
{
	var _variation = lerp(0.75, 1.25, wave_random_next(_random));
	return max(1, wave_group_base_threat(_config, _wave_number) * _variation);
}

/// @description Calculate a bounded, threat-aware delay after one spawn group
/// @param {real} _base_delay
/// @param {real} _base_group_threat
/// @param {real} _group_threat
/// @param {struct} _random
/// @returns {real}
function wave_group_delay(_base_delay, _base_group_threat, _group_threat, _random)
{
	var _random_factor = lerp(0.85, 1.15, wave_random_next(_random));
	var _threat_ratio = _group_threat / max(1, _base_group_threat);
	var _threat_factor = clamp(0.8 + 0.2 * _threat_ratio, 0.9, 1.2);
	var _combined_factor = clamp(_random_factor * _threat_factor, 0.75, 1.25);

	return max(1, round(_base_delay * _combined_factor));
}

/// @description Return the configured threat cost of an enemy object
/// @param {struct.LevelWaveConfig} _config
/// @param {object_asset} _enemy_object
/// @returns {real}
function wave_enemy_cost(_config, _enemy_object)
{
	var _roster_index = wave_roster_index(_config, _enemy_object);
	if (_roster_index < 0)
	{
		return 0;
	}

	return _config.enemy_roster[_roster_index].cost;
}

/// @description Split a flat generated queue into varied simultaneous spawn groups
/// @param {struct.LevelWaveConfig} _config
/// @param {real} _wave_number
/// @param {array} _enemy_array
/// @param {struct} _random
/// @param {real} _base_delay
/// @returns {array}
function generate_standard_wave_groups(_config, _wave_number, _enemy_array, _random, _base_delay)
{
	var _groups = [];
	var _current_group = [];
	var _current_threat = 0;
	var _target_threat = wave_group_target_threat(_config, _wave_number, _random);

	for (var i = 0; i < array_length(_enemy_array); i++)
	{
		var _enemy_object = _enemy_array[i];
		var _enemy_cost = wave_enemy_cost(_config, _enemy_object);
		var _group_size = array_length(_current_group);
		var _would_exceed_soft_limit = _current_threat + _enemy_cost > _target_threat * 1.25;
		var _has_most_of_target = _current_threat >= _target_threat * 0.65;

		// Close a healthy group before adding an enemy that would make it much
		// stronger than its target. A costly enemy may still form a singleton.
		if (_group_size >= MAX_WAVE_GROUP_SIZE
		|| (_group_size >= 2 && _current_threat >= _target_threat)
		|| (_group_size > 0 && _would_exceed_soft_limit && _has_most_of_target))
		{
			array_push(_groups, _current_group);
			_current_group = [];
			_current_threat = 0;
			_target_threat = wave_group_target_threat(_config, _wave_number, _random);
		}

		array_push(_current_group, _enemy_object);
		_current_threat += _enemy_cost;
	}

	if (array_length(_current_group) > 0)
	{
		array_push(_groups, _current_group);
	}

	// Merge adjacent singleton groups so the schedule cannot fall back into a
	// one-enemy-at-a-time conveyor belt when several strong enemies are adjacent.
	var _repaired_groups = [];
	for (var j = 0; j < array_length(_groups); j++)
	{
		var _group = _groups[j];
		var _repaired_count = array_length(_repaired_groups);

		if (array_length(_group) == 1 && _repaired_count > 0)
		{
			var _previous_group = _repaired_groups[_repaired_count - 1];
			if (array_length(_previous_group) == 1)
			{
				array_push(_previous_group, _group[0]);
				_repaired_groups[_repaired_count - 1] = _previous_group;
				continue;
			}
		}

		array_push(_repaired_groups, _group);
	}

	// Turn the temporary enemy arrays into complete spawn-group records. The
	// final group has no delay because there is no subsequent group to schedule.
	var _spawn_groups = [];
	var _base_group_threat = wave_group_base_threat(_config, _wave_number);
	for (var k = 0; k < array_length(_repaired_groups); k++)
	{
		var _repaired_group = _repaired_groups[k];
		var _group_threat = 0;

		for (var m = 0; m < array_length(_repaired_group); m++)
		{
			_group_threat += wave_enemy_cost(_config, _repaired_group[m]);
		}

		var _delay_after = 0;
		if (k < array_length(_repaired_groups) - 1)
		{
			_delay_after = wave_group_delay(
				_base_delay,
				_base_group_threat,
				_group_threat,
				_random
			);
		}

		array_push(_spawn_groups, new WaveSpawnGroup(
			_repaired_group,
			_group_threat,
			_delay_after
		));
	}

	return _spawn_groups;
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
		var _wave_delay = wave_config_delay(_config, _wave_number);
		var _enemy_groups = generate_standard_wave_groups(
			_config,
			_wave_number,
			_enemy_array,
			_random,
			_wave_delay
		);

		var _wave_data = new WaveData(
			_enemy_array,
			_enemy_groups,
			_wave_delay
		);
		_wave_data.threat_budget = _budget;
		_wave_data.spent_budget = _budget - _remaining_budget;
		array_push(_generated_waves, _wave_data);
	}

	validate_generated_waves(_config, _generated_waves);
	return _generated_waves;
}
