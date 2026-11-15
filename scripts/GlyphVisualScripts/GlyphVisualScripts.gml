
function combat_spawn_vfx(_sprite, _x, _y, _xs, _ys, _spell_colour = undefined) {
	var _state = combat_execution_state();
	
	array_push(_state.visuals, {
		sprite: _sprite,
		x: _x,
		y: _y,
		xs: _xs,
		ys: _ys,
		spell_colour: _spell_colour,
		born: _state.clock
	});
}

function combat_draw_vfx() {
	var _state = combat_execution_state();
	
	for (var i = array_length(_state.visuals) - 1; i>= 0; i--) {
		var _vfx = _state.visuals[i];
		var _frame = floor(
			(_state.clock - _vfx.born)
			* sprite_get_speed(_vfx.sprite) / TARGET_ROOM_SPEED
		);
		
		if (_frame >= sprite_get_number(_vfx.sprite)) {
			array_delete(_state.visuals, i, 1);
			continue;
		}
		
		if (_vfx.spell_colour != undefined) {
			draw_spell_sprite_ext(_vfx.sprite, _frame, _vfx.x, _vfx.y,
				_vfx.xs, _vfx.ys, 0, _vfx.spell_colour, 1);
		} else {
			draw_sprite_ext(_vfx.sprite, _frame, _vfx.x, _vfx.y,
				_vfx.xs, _vfx.ys, 0, c_white, 1);
		}
	}
}

function combat_pending_delay(_enemy) {
	var _state = combat_execution_state();
	var _has_delay = false;
	
	if (is_struct(_state)) {
		var _lineage = enemy_get_lineage(_enemy);
		
		for (var i = 0; i < array_length(_state.events); i++) {
			var _event = _state.events[i];
			
			if (_event.policy == "entity"
			&& _event.lineage == _lineage
			&& _event.due > _state.clock) {
				_has_delay = true;
				break;
			}
		}
	}
	return _has_delay;
}

function combat_spawn_sfx(_snd, _gain = 0.7) {
	var _state = combat_execution_state();
	var _snd_frame = { snd: _snd, gain: _gain, frame: _state.clock };
	array_push(_state.audio, _snd_frame);
}

function combat_play_sfx(_cooldown_frames = 6) {
	var _state = combat_execution_state();
	if (!is_struct(_state)) return;
	
	var _history = _state.audio_history;
	
	for (var i = array_length(_state.audio) - 1; i >= 0; i--) {
		var _audio = _state.audio[i];
		var _key = string(_audio.snd);
		
		if (variable_struct_exists(_history, _key)) {
			if (_state.clock - _history[$ _key] < _cooldown_frames) {
				continue;
			}
		}

		_history[$ _key] = _state.clock;
		audio_play_sound(_audio.snd, 10, false, _audio.gain);
	}
	
	_state.audio = [];
}
