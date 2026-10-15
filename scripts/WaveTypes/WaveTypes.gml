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

/// @description This function is a constructor that creates a struct that contains data for a wave
/// @param {array} _enemy_array
/// @param {array} _enemy_groups
/// @param {real} _wave_delay
/// @returns {struct}
function WaveData(_enemy_array, _enemy_groups, _wave_delay) constructor
{
	// The flat array is retained for validation and systems that inspect the level roster.
	enemy_array = _enemy_array;

	// Each record describes a tightly staggered enemy group and its delay afterward.
	enemy_groups = _enemy_groups;

	// wave_delay is the amount of time in frames between enemy groups.
	wave_delay = _wave_delay;
}

/// @description Defines one coordinated enemy spawn group and the pause that follows it
/// @param {array} _enemy_array
/// @param {real} _threat
/// @param {real} _delay_after
function WaveSpawnGroup(_enemy_array, _threat, _delay_after) constructor
{
	enemy_array = _enemy_array;
	threat = _threat;
	delay_after = _delay_after;
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
