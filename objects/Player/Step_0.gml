
// Mana Regen
if (mana <= 0) {
	mana = 0;
	mana_exhausted = true;
}

if (mana < MAX_MANA && channel == noone) {
	if (mana_ticks == 0) {
		var _regen_multiplier = mana_exhausted ? mana_exhausted_regen_multiplier : 1;
		mana = min(MAX_MANA, mana + mana_regen_rate * _regen_multiplier);
		mana_ticks = 6;
	}
	mana_ticks--
}

if (mana >= MAX_MANA) {
	mana = MAX_MANA;
	mana_exhausted = false;
}

for (var k = 0; k < 3; k++) {
	if (keyboard_check_pressed(ord("1") + k) || keyboard_check(vk_numpad1 + k)) {
		var _l = spell_ensure(k);
		if (_l != undefined && _l.form != undefined) spell_selected = (spell_selected == k) ? -1 : k;
	}
}


// Space button resets selected spell
if (mouse_check_button_pressed(vk_space) || keyboard_check_pressed(ord(" "))) spell_selected = -1;

// Cast
var _cost = 0;
if (!is_spell_on_cd && mouse_check_button(mb_left) && spell_selected != -1 && channel == noone) {
	var _t = world_to_grid(mouse_x, mouse_y);
	if (_t != undefined) {
		var _loadout = global.spellbook[spell_selected];
		var _s = cast_spell(id, _loadout, _t.col, _t.row);
		if (_s.spell != noone) {
			if (_s.spell.form.is_channel) {
				channel = _s.spell; // Stores the channeled spell
				_cost = _s.cost;
			} else {
				is_spell_on_cd = true;
				alarm[0] = 0.8 * TARGET_ROOM_SPEED;
			}
		}
	}
}

// Handling Channeling
if (channel != noone) {
	var _release = !mouse_check_button(mb_left);
	
	if (!_release) {
		// Draining mana while held
		var _drain = _cost / TARGET_ROOM_SPEED;
		if (mana >= _drain) {
			mana -= _drain;
			if (mana <= 0) {
				mana = 0;
				mana_exhausted = true;
				_release = true;
			}
		}
		else {
			mana = 0;
			mana_exhausted = true;
			_release = true;
		}
	}
	if  (_release || !instance_exists(channel)) {
		if (instance_exists(channel)) instance_destroy(channel);
		channel = noone;
		is_spell_on_cd = true;
		alarm[0] = 0.8 * TARGET_ROOM_SPEED;
	}
}
