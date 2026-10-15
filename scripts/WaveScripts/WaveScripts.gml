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


