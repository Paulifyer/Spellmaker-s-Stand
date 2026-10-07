
// Mana Regen
if (mana != MAX_MANA) {
	if (mana_ticks == 0) {
		mana = min(MAX_MANA, mana + mana_regen_rate);
		mana_ticks = 6;
	}
	mana_ticks--
}

// Glyph inputs

if (input_slot < 3) {
	for (var k = 0; k < 3; k++) {
		if (keyboard_check_pressed(ord("1") + k) || keyboard_check(vk_numpad1 + k)) {
			var _type = global.slot_order[input_slot];
			input_glyphs[input_slot] = global.glyph_order[$ _type][k];
			input_slot++;
		}
	}
}

// Undo glyphs if backspace is pressed
if (keyboard_check_pressed(vk_backspace) && array_length(input_glyphs) > 0) {
	input_slot--;
	input_glyphs[input_slot] = undefined;
}
// right mouse button clears the glyphs
if (mouse_check_button_pressed(mb_right)) { 
	input_glyphs = [undefined, undefined, undefined];
	input_slot = 0;
}
// Cast

if (mouse_check_button(mb_left) && input_glyphs[0] != undefined && channel == noone) {
	var _t = world_to_grid(mouse_x, mouse_y);
	if (_t != undefined) {
		var _loadout = { form: input_glyphs[0], element: input_glyphs[1], modifier: input_glyphs[2] };
		var _s = cast_spell(id, _loadout, _t.col, _t.row);
		if (_s != noone) {
			if (_s.form.is_channel) channel = _s; // Stores the channeled spell
			else {
				input_glyphs = [undefined, undefined, undefined];
				input_slot = 0;
			}
		}
	}
}

// Handling Channeling
if (channel != noone) {
	var _release = !mouse_check_button(mb_left);
	
	if (!_release) {
		// Draining mana while held
		var _drain = channel.form.drain_per_sec / TARGET_ROOM_SPEED;
		if (mana >= _drain) mana -= _drain;
		else _release = true;
	}
	if  (_release || !instance_exists(channel)) {
		if (instance_exists(channel)) instance_destroy(channel);
		channel = noone;
		input_glyphs = [undefined, undefined, undefined]
		input_slot = 0;
	}
}