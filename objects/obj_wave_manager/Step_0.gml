/// @description Wave Manager


// This is how we animate the wave number text in the HUD
// If wave_flash_alpha is greater than zero
if (wave_flash_alpha > 0)
{
	// Reduce the wave_flash alpha
	wave_flash_alpha -= 0.03;
}

// Once every scheduled enemy has spawned, wait for the room to be cleared.
if (state == WaveState.CLEANUP)
{
	if (active_enemy_count <= 0)
	{
		wave_flash_alpha = 1;
		instance_destroy(obj_button_wave_skip);

		if (wave < array_length(wave_array))
		{
			state = WaveState.INTERMISSION;
			intermission_timer = max(0, round(
				TARGET_ROOM_SPEED * inter_wave_delay_seconds
			));
		}
		else
		{
			advance_wave();
		}
	}
	// Offer an early start for the next wave while enemies from this wave remain.
	else if (wave < array_length(wave_array) && !instance_exists(obj_button_wave_skip))
	{
		layer_sequence_create("Sequences", 0, 0, seq_wave_skip_button);
	}
}
else if (state == WaveState.INTERMISSION)
{
	intermission_timer = max(0, intermission_timer - 1);
	if (intermission_timer <= 0)
	{
		advance_wave();
	}
}

