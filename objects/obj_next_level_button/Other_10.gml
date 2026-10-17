///@description Next Level Button

// Increment Level selector to pick next level
global.current_level++;

//Go to the next level in the level_array (Ensure sequential)
room_goto(global.level_array[global.current_level]);

// Play the button press sound effect
audio_play_sound(snd_button_click, 0, false);