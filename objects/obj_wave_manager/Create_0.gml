/// @description Wave Manager

// WAVE TIMING SETTINGS (seconds)
// Child level managers may override these after calling event_inherited().
// Time between enemies belonging to the same group.
group_spawn_stagger_min_seconds = 0.2;
group_spawn_stagger_max_seconds = 0.5;

// Random delay after one group finishes before the next group begins.
group_delay_min_seconds = 1;
group_delay_max_seconds = 3;

// Fixed pause after clearing one numbered wave before the next begins.
inter_wave_delay_seconds = 3;

// Each enemy spawns slightly faster or slower than its normal movement speed.
enemy_speed_variation = 0.10;

// The state machine is the authoritative source for wave lifecycle checks.
state = WaveState.WAITING;

// This variable stores the wave number
wave = 1;

// This variable stores all the wave struct data
wave_array = [];

// This variable stores the groups in the current wave.
current_wave_groups = [];

// Number of living enemies created by this manager, including overlapping waves.
active_enemy_count = 0;

// Index of the current spawn group and the next enemy within that group.
position = 0;
group_enemy_position = 0;

// A group's shuffled lanes are retained while its enemies stagger into play.
group_lane_indices = [];

// Tracks the remaining intermission in frames. Timing settings remain in seconds
// and are converted only when their respective timers are scheduled.
intermission_timer = 0;

// This variable is used to animate the wave number displayed in the HUD
wave_flash_alpha = 0;

// This variable holds the path to use for the enemies that spawn
// It should be overwritten in the child object
level_paths = [Path1, Path2, Path3, Path4, Path5, Path6];
