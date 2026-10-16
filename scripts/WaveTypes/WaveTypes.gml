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
/// @param {object_asset} _enemy_object
/// @param {real} _cost
/// @param {real} _weight
/// @param {real} _intro_wave
/// @param {real} _max_per_wave
function EnemyWaveDefinition(_enemy, _enemy_weight, _intro_wave, _max_per_wave) constructor
{
	enemy_object = _enemy.object;
	cost = _enemy.cost;
	weight = _enemy_weight;
	intro_wave = _intro_wave;
	max_per_wave = _max_per_wave;
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
