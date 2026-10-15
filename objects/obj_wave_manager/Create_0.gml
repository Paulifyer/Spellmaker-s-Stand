/// @description Wave Manager

// WAVE TIMING SETTINGS (seconds)
// Child level managers may override these after calling event_inherited().
// Time between enemies belonging to the same group.
group_spawn_stagger_seconds = 0.1;

// Time after clearing one numbered wave before the next begins.
inter_wave_delay_seconds = 5;

// This variable tells whether the wave is currently running
wave_running = false;

// This variable tells whether all the waves have been completed 
waves_over = false;

// The state machine is the authoritative source for wave lifecycle checks.
state = WaveState.WAITING;

// This variable stores the wave number
wave = 1;

// This variable stores all the wave struct data
wave_array = [];

// This variable stores the current wave struct
current_wave_struct = noone;

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
