
function combat_spawn_vfx(_sprite, _x, _y, _xs, _ys) {
	var _state = combat_execution_state();
	
	array_push(_state.visuals, {
		sprite: _sprite,
		x: _x,
		y: _y,
		xs: _xs,
		ys: _ys,
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
		
		draw_sprite_ext(
			_vfx.sprite, _frame,
			_vfx.x, _vfx.y,
			_vfx.xs, _vfx.ys, 0, c_white, 1
		);
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
