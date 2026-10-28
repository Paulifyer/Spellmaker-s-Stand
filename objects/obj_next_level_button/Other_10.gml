///@description Next Level Button

var _save = json_stringify({ owned: global.owned, spellbook: global.spellbook });

if (global.current_level + 1 < array_length(global.level_array)) {
	global.current_level++;
	room_goto(global.level_array[global.current_level]);
} else {
	room_goto(rm_menu);
}

// Play the button press sound effect
audio_play_sound(snd_button_click, 0, false);
