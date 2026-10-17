/// @description Wave Manager Level 1

// Inherit the parent event.
event_inherited();

// Init enemy catalog
if (!variable_global_exists("EnemyCatalog")) {
    init_enemy_catalog();
}

// Define every enemy type that can appear in this level. Staggered introduction
// waves guarantee every type while adding stronger enemies as difficulty rises.
var _enemy_roster = [
	new EnemyWaveDefinition(global.EnemyCatalog.MOOK, 10, 1, 999),
	//new EnemyWaveDefinition(global.EnemyCatalog.RANGER, 4, 2, 5),
	//new EnemyWaveDefinition(global.EnemyCatalog.BRUTE, 1, 3, 10)
];

// Wave budgets replace manually repeated enemy arrays. Enemy selection and
// order vary each run, while these settings keep the overall curve stable.
level_wave_config = new LevelWaveConfig(
	1, // Wave count
	5, // Starting budget
	15, // Ending budget
	1.00, // Difficulty curve
	_enemy_roster
);

wave_array = generate_standard_waves(level_wave_config);

