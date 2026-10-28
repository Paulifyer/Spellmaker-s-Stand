/// Shared wave constants, state, and data types

// This is the what we are using for our room speed (60 fps) as room_speed is discouraged
#macro TARGET_ROOM_SPEED 60
#macro MAX_WAVE_GROUP_SIZE 6

enum WaveState
{
	WAITING,
	SPAWNING,
	CLEANUP,
	INTERMISSION,
	FINISHED
}

/// @description Defines one enemy type that may be selected by a level's wave generator 
/// @param {struct} _enemy EnemyCatalog entry containing the object and threat cost
/// @param {real|array} _weight_setting Relative selection weight after minimums are added
/// @param {real|array} _min_setting Minimum amount required in each wave
/// @param {real|array} _max_setting Maximum amount allowed in each wave
/// @param {string|undefined} _mutation The mutation key from global.mutations
function EnemyWaveDefinition(_enemy, _weight_setting, _min_setting, _max_setting, _mutation = undefined) constructor
{
	enemy_object = _enemy.object;
	cost = _enemy.cost;
	weight_setting = _weight_setting;
	min_setting = _min_setting;
	max_setting = _max_setting;
	mutation = _mutation;
	cost += mutation_total_cost(_mutation);
}

/// @description Resolve a scalar setting or one entry from a per-wave array
/// @param {real|array} _setting
/// @param {real} _wave_number One-based wave number
/// @returns {real}
function wave_setting_value(_setting, _wave_number)
{
	if (is_array(_setting))
	{
		return _setting[_wave_number - 1];
	}

	return _setting;
}

/// @description Return an enemy's selection weight for one wave
function wave_enemy_weight(_definition, _wave_number)
{
	return wave_setting_value(_definition.weight_setting, _wave_number);
}

/// @description Return an enemy's required minimum for one wave
function wave_enemy_min(_definition, _wave_number)
{
	return wave_setting_value(_definition.min_setting, _wave_number);
}

/// @description Return an enemy's maximum for one wave
function wave_enemy_max(_definition, _wave_number)
{
	return wave_setting_value(_definition.max_setting, _wave_number);
}

/// @description Defines the standard-wave generation settings for one level
/// @param {real} _wave_count
/// @param {real} _starting_budget
/// @param {real} _ending_budget
/// @param {real} _difficulty_curve
/// @param {array} _enemy_roster
function LevelWaveConfig(
	_wave_count,
	_starting_budget,
	_ending_budget,
	_difficulty_curve,
	_enemy_roster
) constructor
{
	wave_count = _wave_count;
	starting_budget = _starting_budget;
	ending_budget = _ending_budget;
	difficulty_curve = _difficulty_curve;
	enemy_roster = _enemy_roster;
}
