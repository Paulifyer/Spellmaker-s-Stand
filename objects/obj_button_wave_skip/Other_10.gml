/// @description Wave Skip Button

// Wave advancement is owned by the manager's guarded state transition.
if (!start_next_wave())
{
	exit;
}

with (obj_wave_manager)
{
	wave_flash_alpha = 1;
}

// Destroy this button
instance_destroy(id);

// Play the button press sound effect
audio_play_sound(snd_button_click, 0, false);
