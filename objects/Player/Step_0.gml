
// Brief feedback only follows successful casts.
if (cast_flash_ticks > 0) cast_flash_ticks--;
for (var _slot = 0; _slot < SPELL_SLOTS; _slot++) {
	spell_cooldowns[_slot] = max(0, spell_cooldowns[_slot] - 1);
}

// Mana Regen
if (mana <= 0) {
	mana = 0;
	mana_exhausted = true;
}

if (mana < max_mana && channel == noone) {
	if (mana_ticks == 0) {
		var _regen_multiplier = mana_exhausted ? mana_exhausted_regen_multiplier : 1;
		mana = min(max_mana, mana + max_mana * (mana_regen_rate / 100) * _regen_multiplier);
		mana_ticks = 6;
	}
	mana_ticks--
}

if (mana >= max_mana) {
	mana = max_mana;
	mana_exhausted = false;
}

// Menus and loss of focus must not accept casts or sustain a channel.
var _input_enabled = !global.menu_lock && !instance_exists(obj_spellbook) && window_has_focus();


// Spacebar sets mana_exhausted to trigger mana recovery mode
if (_input_enabled && keyboard_check_pressed(vk_space)) {
	mana_exhausted = true;
}

// A fresh slot-key press casts once at the hovered tile; presses are not queued.
if (_input_enabled && channel == noone) {
	var _t = world_to_grid(mouse_x, mouse_y);
	if (_t != undefined) {
		for (var k = 0; k < SPELL_SLOTS; k++) {
			var _key = -1;
			if (keyboard_check_pressed(ord("1") + k)) _key = ord("1") + k;
			else if (keyboard_check_pressed(vk_numpad1 + k)) _key = vk_numpad1 + k;
			if (_key == -1) continue;
			if (spell_cooldowns[k] > 0) continue;

			var _loadout = spell_ensure(k);
			if (_loadout == undefined || !is_spell_usable(_loadout)) continue;
			var _s = cast_spell(id, _loadout, _t.col, _t.row);
			if (_s.spell != noone) {
				cast_flash_slot = k;
				cast_flash_ticks = max(1, round(0.15 * TARGET_ROOM_SPEED));
				if (_s.spell.form.is_channel) {
					channel = _s.spell;
					channel_key = _key;
					channel_slot = k;
					cost = _s.cost;
				} else {
					var _cooldown_seconds = tune_value("player", "spell_cd", SPELL_CD);
					var _slot_cooldowns = global.tuning.player[$ "spell_cd_by_slot"];
					if (is_array(_slot_cooldowns) && k < array_length(_slot_cooldowns) && is_real(_slot_cooldowns[k])) {
						_cooldown_seconds = _slot_cooldowns[k];
					}
					spell_cooldowns[k] = max(0, _cooldown_seconds) * TARGET_ROOM_SPEED;
					spell_cooldown_max[k] = spell_cooldowns[k];
				}
				// At most one successful cast per frame, even for simultaneous presses.
				break;
			}
		}
	}
}

// Handling Channeling
if (channel != noone) {
	var _release = !_input_enabled || !keyboard_check(channel_key) || !instance_exists(channel);
	
	if (!_release) {
		// Draining mana while held
		var _drain = cost / TARGET_ROOM_SPEED;
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
		var _finished_channel_slot = channel_slot;
		if (instance_exists(channel)) instance_destroy(channel);
		channel = noone;
		channel_key = -1;
		channel_slot = -1;
		cost = 0;
		if (_finished_channel_slot >= 0) {
			var _cooldown_seconds = tune_value("player", "spell_cd", SPELL_CD);
			var _slot_cooldowns = global.tuning.player[$ "spell_cd_by_slot"];
			if (is_array(_slot_cooldowns) && _finished_channel_slot < array_length(_slot_cooldowns) && is_real(_slot_cooldowns[_finished_channel_slot])) {
				_cooldown_seconds = _slot_cooldowns[_finished_channel_slot];
			}
			spell_cooldowns[_finished_channel_slot] = max(0, _cooldown_seconds) * TARGET_ROOM_SPEED;
			spell_cooldown_max[_finished_channel_slot] = spell_cooldowns[_finished_channel_slot];
		}
	}
}
