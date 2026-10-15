/// @description Wave Manager Level 1

// Inherit the parent event.
event_inherited();

// Define every enemy type that can appear in this level. Staggered introduction
// waves guarantee every type while adding stronger enemies as difficulty rises.
var _enemy_roster = [
	new EnemyWaveDefinition(obj_mook, 1, 10, 1, 999),
	new EnemyWaveDefinition(obj_ranger, 2, 4, 2, 5),
	new EnemyWaveDefinition(obj_brute, 5, 1, 3, 10)
];

// Wave budgets replace manually repeated enemy arrays. Enemy selection and
// order vary each run, while these settings keep the overall curve stable.
level_wave_config = new LevelWaveConfig(
	3, // Threat count
	7, // Starting budget
	30, // Ending budget
	1.00, // Difficulty curve
	_enemy_roster
);

wave_array = generate_standard_waves(level_wave_config);

