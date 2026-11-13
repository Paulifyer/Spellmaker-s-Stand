/// @description Gameplay Manager

// This is how we animate the village hp text in the HUD
// If village_flash_alpha is greater than zero
if (village_flash_alpha > 0)
{
	// Reduce the village_flash_alpha
	village_flash_alpha -= 0.03;
}

// This is how we animate the money text in the HUD
// If money_flash_alpha is greater than zero
if (money_flash_alpha > 0)
{
	// Reduce the money_flash_alpha
	money_flash_alpha -= 0.03;
}

// Check if the game is over, and if so, exit this event
if (paused || game_over) exit;

var _breached = false;
if (village_hp <= 0)
{
	with (obj_enemy_parent)
	{
		if (hp > 0 && !is_bonepile && x <= BARRIER_BREACH_X)
		{
			_breached = true;
			break;
		}
	}
}

if (_breached)
{
	// Use the custom game over function to turn off variables
	set_game_over();	
	
	// Create the game lost popup using a sequence
	layer_sequence_create("Sequences", 0, 0, seq_popup_game_lost);
	
	// Play the game over music
	audio_play_sound(snd_music_lose, 1, false);

} 
else if (waves_are_over())
{
    // Freeze and persist the result before deactivating gameplay instances.
    level_result = level_star_result(true, village_hp, village_max_hp, tower_damage_taken, star_thresholds);
    save_level_stars(room_get_name(room), level_result);
	
	// Use the custom game over function to turn off variables
	set_game_over();
	
	// Create the game won popup using a sequence
	layer_sequence_create("Sequences", 0, 0, seq_popup_game_won);
	
	// Play the game over music
	audio_play_sound(snd_music_win, 1, false);
}

