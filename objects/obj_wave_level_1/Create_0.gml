/// @description Wave Manager Level 1

// Inherit the parent event.
event_inherited();

// Define every enemy type that can appear in this level. All three enemies
// are introduced in wave one, which guarantees at least one of each per run.
var _enemy_roster = [
	new EnemyWaveDefinition(obj_mook, 1, 10, 1, 999),
	new EnemyWaveDefinition(obj_ranger, 2, 4, 1, 5),
	new EnemyWaveDefinition(obj_brute, 5, 1, 1, 10)
];

// Wave budgets replace manually repeated enemy arrays. Enemy selection and
// order vary each run, while these settings keep the overall curve stable.
level_wave_config = new LevelWaveConfig(
	3,
	12,
	60,
	1.8,
	TARGET_ROOM_SPEED * 3,
	TARGET_ROOM_SPEED * 1.55,
	_enemy_roster
);

wave_run_seed = create_wave_run_seed();
wave_array = generate_standard_waves(level_wave_config, wave_run_seed);

