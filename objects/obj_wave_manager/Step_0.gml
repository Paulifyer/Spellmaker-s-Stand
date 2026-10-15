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
		advance_wave();
		instance_destroy(obj_button_wave_skip);
	}
	// Offer an early start for the next wave while enemies from this wave remain.
	else if (wave < array_length(wave_array) && !instance_exists(obj_button_wave_skip))
	{
		layer_sequence_create("Sequences", 0, 0, seq_wave_skip_button);
	}
}

