/// @description Start Button

// Re-enter the current level so the room matches the retained spells and mana progression.
// current_level starts at zero for a fresh session and advances with NEXT LEVEL.
room_goto(global.level_array[global.current_level]);

// Play the button press sound effect
audio_play_sound(snd_button_click, 0, false);
