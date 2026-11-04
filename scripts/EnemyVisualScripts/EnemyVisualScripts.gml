// Menu preview uses elapsed seconds because the combat clock stops in the spellbook.
function draw_enemy_mutation_preview(_entry, _sprite, _x, _y, _seconds) {
	var _keys = normalize_mutation_keys(_entry.mutation);
	var _width = max(1, sprite_get_bbox_right(_sprite) - sprite_get_bbox_left(_sprite) + 1);
	var _height = max(1, sprite_get_bbox_bottom(_sprite) - sprite_get_bbox_top(_sprite) + 1);
	var _scale = min(0.75, min(180 / _width, 180 / _height));
	var _cx = (sprite_get_bbox_left(_sprite) + sprite_get_bbox_right(_sprite)) / 2;
	var _cy = (sprite_get_bbox_top(_sprite) + sprite_get_bbox_bottom(_sprite)) / 2;
	var _tint = array_contains(_keys, "skeletal") ? c_gray : c_white;
	var _rate = sprite_get_speed(_sprite);
	if (sprite_get_speed_type(_sprite) == spritespeed_framespergameframe) _rate *= TARGET_ROOM_SPEED;
	var _frame = floor(_seconds * _rate) mod max(1, sprite_get_number(_sprite));
	draw_sprite_ext(_sprite, _frame,
		_x - (_cx - sprite_get_xoffset(_sprite)) * _scale,
		_y - (_cy - sprite_get_yoffset(_sprite)) * _scale,
		_scale, _scale, 0, _tint, 1);
	var _wide = _entry.enemy == obj_siege_beast || _entry.enemy == obj_carrion;
	var _ward = -1;
	if (array_contains(_keys, "fire-warded")) _ward = _wide ? spr_ward_fire_wide : spr_ward_fire_narrow;
	if (array_contains(_keys, "frost-warded")) _ward = _wide ? spr_ward_frost_wide : spr_ward_frost_narrow;
	if (array_contains(_keys, "lightning-warded")) _ward = _wide ? spr_ward_lightning_wide : spr_ward_lightning_narrow;
	if (_ward >= 0) {
		var _ward_rate = sprite_get_speed(_ward);
		if (sprite_get_speed_type(_ward) == spritespeed_framespergameframe) _ward_rate *= TARGET_ROOM_SPEED;
		var _elapsed = _seconds * _ward_rate;
		var _count = sprite_get_number(_ward);
		var _ward_frame = (_elapsed < 1 || _count <= 1) ? 0 : 1 + (floor(_elapsed - 1) mod (_count - 1));
		var _ward_scale = _width * _scale * 1.15 / max(1, sprite_get_bbox_right(_ward) - sprite_get_bbox_left(_ward) + 1);
		var _ward_cx = (sprite_get_bbox_left(_ward) + sprite_get_bbox_right(_ward)) / 2;
		var _ward_cy = (sprite_get_bbox_top(_ward) + sprite_get_bbox_bottom(_ward)) / 2;
		draw_sprite_ext(_ward, _ward_frame,
			_x - (_ward_cx - sprite_get_xoffset(_ward)) * _ward_scale,
			_y - (_ward_cy - sprite_get_yoffset(_ward)) * _ward_scale,
			_ward_scale, _ward_scale, 0, c_white, 1);
	}
	if (array_contains(_keys, "banneret")) {
		var _banner = spr_banneret_speed;
		var _banner_scale = _height * _scale / max(1, sprite_get_bbox_bottom(_banner) - sprite_get_bbox_top(_banner) + 1);
		var _banner_cx = (sprite_get_bbox_left(_banner) + sprite_get_bbox_right(_banner)) / 2;
		var _banner_cy = (sprite_get_bbox_top(_banner) + sprite_get_bbox_bottom(_banner)) / 2;
		draw_sprite_ext(_banner, 0,
			_x + _width * _scale * 0.3 - (_banner_cx - sprite_get_xoffset(_banner)) * _banner_scale,
			_y - _height * _scale * 0.15 - (_banner_cy - sprite_get_yoffset(_banner)) * _banner_scale + sin(_seconds * 3) * 3,
			_banner_scale, _banner_scale, 0, c_white, 1);
	}
}

// Visual progress follows combat time, independent of the enemy's animation.
function enemy_frost_visual(_enemy, _clock) {
	var _stacks = combat_status_frost_stacks(_enemy);
	if (_stacks <= 0 || _enemy.hp <= 0) {
		_enemy.frost_visual = undefined;
		return undefined;
	}
	if (!variable_instance_exists(_enemy, "frost_visual") || !is_struct(_enemy.frost_visual)) {
		_enemy.frost_visual = {phase: 0, since: _clock, sprite: spr_frost_1_1, frame: 0};
	}
	var _visual = _enemy.frost_visual;
	var _sprites = [spr_frost_1_1, spr_frost_1_2, spr_frost_2, spr_frost_3];
	// Finish each buildup before progressing, even if stacks arrive together.
	while (true) {
		var _sprite = _sprites[_visual.phase];
		var _rate = max(0.0001, sprite_get_speed(_sprite));
		if (sprite_get_speed_type(_sprite) == spritespeed_framespergameframe) _rate *= TARGET_ROOM_SPEED;
		var _duration = sprite_get_number(_sprite) * TARGET_ROOM_SPEED / _rate;
		var _elapsed = max(0, _clock - _visual.since);
		if (_visual.phase == 1 && _stacks > 1) {
			_visual.phase = 2;
			_visual.since = _clock;
			continue;
		}
		if (_elapsed >= _duration && (_visual.phase == 0 || (_visual.phase == 2 && _stacks >= 3))) {
			var _next_since = (_visual.phase == 2) ? _clock : _visual.since + _duration;
			_visual.phase += 1;
			_visual.since = _next_since;
			continue;
		}
		_visual.sprite = _sprite;
		var _frame = floor(_elapsed * _rate / TARGET_ROOM_SPEED);
		_visual.frame = (_visual.phase == 1) ? _frame mod sprite_get_number(_sprite)
			: min(_frame, sprite_get_number(_sprite) - 1);
		return _visual;
	}
}

function enemy_draw_frost(_enemy) {
	var _execution = combat_execution_state();
	var _clock = is_struct(_execution) ? _execution.clock : 0;
	var _visual = enemy_frost_visual(_enemy, _clock);
	if (!is_struct(_visual)) return;
	var _bounds = enemy_visual_bounds(_enemy);
	// Use a common canvas anchor and scale so the ice grows without jumping.
	var _reference = spr_frost_3;
	var _width = sprite_get_bbox_right(_reference)
       - sprite_get_bbox_left(_reference) + 1;
	var _height = sprite_get_bbox_bottom(_reference)
		- sprite_get_bbox_top(_reference) + 1;
	// Fit both dimensions so long bodies/tails cannot inflate the overlay.
	var _scale = max(min(
		_bounds.width / max(1, _width),
		_bounds.height / max(1, _height)
	) * 1.15, 0.9);
	_scale *= _enemy.frost_visual_scale;
	var _anchor_x = (sprite_get_bbox_left(_reference) + sprite_get_bbox_right(_reference)) / 2;
	var _anchor_y =  (
		sprite_get_bbox_top(_reference) + sprite_get_bbox_bottom(_reference)
	) / 2;
	var _sprite = _visual.sprite;
	draw_sprite_ext(_sprite, _visual.frame,
		_bounds.x - (_anchor_x - sprite_get_xoffset(_sprite)) * _scale,
		_bounds.y - (_anchor_y - sprite_get_yoffset(_sprite)) * _scale,
		_scale, _scale, 0, c_white, _enemy.image_alpha);
}

function enemy_draw_fire(_enemy) {
	if (_enemy.hp <= 0 || _enemy.burn_timer <= 0) {
		_enemy.fire_visual = undefined;
		return undefined;
	}
	var _execution = combat_execution_state();
	if (!is_struct(_execution)) return;
	var _clock = _execution.clock;
	
	if (!variable_instance_exists(_enemy, "fire_visual") || !is_struct(_enemy.fire_visual)) _enemy.fire_visual = {since: _clock};
	var _elapsed = _clock - _enemy.fire_visual.since;
	var _start_frames = sprite_get_number(spr_fire_1);
	var _start_rate = sprite_get_speed(spr_fire_1);
	var _start_duration = _start_frames * TARGET_ROOM_SPEED / _start_rate;
	
	var _sprite;
	var _frame;
	
	if (_elapsed < _start_duration) {
		_sprite = spr_fire_1;
		_frame = floor(_elapsed * _start_rate / TARGET_ROOM_SPEED);
	} else {
		_sprite = spr_fire_2;
		_frame = floor(
			(_elapsed - _start_duration)
			* sprite_get_speed(_sprite) / TARGET_ROOM_SPEED
		) % sprite_get_number(_sprite);
	}
	
	var _bounds = enemy_visual_bounds(_enemy);
    var _width = sprite_get_bbox_right(spr_fire_2)
        - sprite_get_bbox_left(spr_fire_2) + 1;
    var _scale = max(_bounds.width * 1.15 / max(1, _width), 0.9);

    var _center_x = (
        sprite_get_bbox_left(_sprite) + sprite_get_bbox_right(_sprite)
    ) / 2;
    var _bottom = sprite_get_bbox_bottom(_sprite);

    draw_sprite_ext(
        _sprite, _frame,
        _bounds.x - (_center_x - sprite_get_xoffset(_sprite)) * _scale,
        _bounds.y + _bounds.height / 2
            - (_bottom - sprite_get_yoffset(_sprite)) * _scale,
        _scale, _scale, 0, c_white, _enemy.image_alpha
    );
}

function enemy_draw_stun(_enemy) {
	if (_enemy.hp <= 0 || _enemy.stun_timer <= 0) {
		_enemy.stun_visual = undefined;
		return undefined;
	}
	var _execution = combat_execution_state();
	if (!is_struct(_execution)) return;
	var _clock = _execution.clock;
	
	if (!variable_instance_exists(_enemy, "stun_visual") || !is_struct(_enemy.stun_visual)) _enemy.stun_visual = {since: _clock};
	var _elapsed = _clock - _enemy.stun_visual.since;
	var _start_frames = sprite_get_number(spr_stun_1);
	var _start_rate = sprite_get_speed(spr_stun_1);
	var _start_duration = _start_frames * TARGET_ROOM_SPEED / _start_rate;
	
	var _sprite;
	var _frame;
	
	if (_elapsed < _start_duration) {
		_sprite = spr_stun_1;
		_frame = floor(_elapsed * _start_rate / TARGET_ROOM_SPEED);
	} else {
		_sprite = spr_stun_2;
		_frame = floor(
			(_elapsed - _start_duration)
			* sprite_get_speed(_sprite) / TARGET_ROOM_SPEED
		) % sprite_get_number(_sprite);
	}
	
	var _bounds = enemy_visual_bounds(_enemy);
    var _width = sprite_get_bbox_right(spr_stun_2)
        - sprite_get_bbox_left(spr_stun_2) + 1;
    var _scale = max(_bounds.width * 1.15 / max(1, _width), 0.9);

    var _center_x = (
        sprite_get_bbox_left(_sprite) + sprite_get_bbox_right(_sprite)
    ) / 2;
	var _top = sprite_get_bbox_top(_sprite);
    var _draw_y =  _bounds.y - _bounds.height / 2
		- (_top - sprite_get_yoffset(_sprite)) * _scale;

    draw_sprite_ext(
        _sprite, _frame,
        _bounds.x - (_center_x - sprite_get_xoffset(_sprite)) * _scale,
        _draw_y - 25,
        _scale, _scale, 0, c_white, _enemy.image_alpha
    );
}
	
function enemy_draw_charged(_enemy) {
	if (_enemy.hp <= 0 || !combat_status_charged(_enemy)) {
		_enemy.charged_visual = undefined;
		return undefined;
	}
	var _execution = combat_execution_state();
	if (!is_struct(_execution)) return;
	var _clock = _execution.clock;
	
	if (!variable_instance_exists(_enemy, "charged_visual") || !is_struct(_enemy.charged_visual)) _enemy.charged_visual = {since: _clock};
	var _elapsed = _clock - _enemy.charged_visual.since;
	var _sprite = spr_charged;
	var _frame = floor(
		_elapsed
		* sprite_get_speed(_sprite) / TARGET_ROOM_SPEED
	) % sprite_get_number(_sprite);
	
	var _bounds = enemy_visual_bounds(_enemy);
    var _width = sprite_get_bbox_right(_sprite)
        - sprite_get_bbox_left(_sprite) + 1;
    var _scale = max(_bounds.width * 1.15 / max(1, _width), 0.9);

    var _center_x = (
        sprite_get_bbox_left(_sprite) + sprite_get_bbox_right(_sprite)
    ) / 2;
	var _center_y = (
		sprite_get_bbox_top(_sprite) + sprite_get_bbox_bottom(_sprite)
	) / 2;

    draw_sprite_ext(
        _sprite, _frame,
        _bounds.x - (_center_x - sprite_get_xoffset(_sprite)) * _scale,
        _bounds.y - (_center_y - sprite_get_yoffset(_sprite)) * _scale,
        _scale, _scale, 0, c_white, _enemy.image_alpha
    );
}

function enemy_draw_hex(_enemy) {
	if (_enemy.hp <= 0 || _enemy.hex_timer <= 0) {
		_enemy.hex_visual = undefined;
		return undefined;
	}
	var _execution = combat_execution_state();
	if (!is_struct(_execution)) return;
	var _clock = _execution.clock;
	
	if (!variable_instance_exists(_enemy, "charged_visual") || !is_struct(_enemy.hex_visual)) _enemy.hex_visual = {since: _clock};
	var _elapsed = _clock - _enemy.hex_visual.since;
	var _sprite = spr_hex;
	var _frame = floor(
		_elapsed
		* sprite_get_speed(_sprite) / TARGET_ROOM_SPEED
	) % sprite_get_number(_sprite);
	
	var _bounds = enemy_visual_bounds(_enemy);
    var _width = sprite_get_bbox_right(_sprite)
        - sprite_get_bbox_left(_sprite) + 1;
    var _scale = max(_bounds.width * 1.15 / max(1, _width), 0.9);
    var _center_x = (
        sprite_get_bbox_left(_sprite) + sprite_get_bbox_right(_sprite)
    ) / 2;
	var _center_y = (
		sprite_get_bbox_top(_sprite) + sprite_get_bbox_bottom(_sprite)
	) / 2;
	shader_set(shd_purple_swap);
    draw_sprite_ext(
        _sprite, _frame,
        _bounds.x - (_center_x - sprite_get_xoffset(_sprite)) * _scale,
        _bounds.y - (_center_y - sprite_get_yoffset(_sprite)) * _scale,
        _scale, _scale, 0, c_white, _enemy.image_alpha
    );
	shader_reset();
}

function enemy_get_leftpoint(_enemy, _sprite, _pos, _scale) {
	var _bounds = enemy_visual_bounds(_enemy);
    var _width = sprite_get_bbox_right(_sprite)
        - sprite_get_bbox_left(_sprite) + 1;
	if (_scale == 0) {
		_scale = max(_bounds.width * 1.15 / max(1, _width), 0.9) * _enemy.frost_visual_scale;
	}

    var _left_x = sprite_get_bbox_left(_sprite);
	var _left = _bounds.x - (_left_x - sprite_get_xoffset(_sprite)) * _scale;
	
	switch (_pos) {
	    case "top":
			var _top = _bounds.y - _bounds.height / 2
				- (sprite_get_bbox_top(_sprite) - sprite_get_yoffset(_sprite)) * _scale;
			return {x: _left, y: _top, scale: _scale};
		case "center":
			var _center_y = (
				sprite_get_bbox_top(_sprite) + sprite_get_bbox_bottom(_sprite)
			) / 2;
			var _center = _bounds.y - (_center_y - sprite_get_yoffset(_sprite)) * _scale;
	        return {x: _left, y: _center, scale: _scale};
		case "bottom":
			var _bottom_y = sprite_get_bbox_bottom(_sprite);
			var _bottom = _bounds.y + _bounds.height / 2
				- (_bottom_y - sprite_get_yoffset(_sprite)) * _scale;
	        return {x: _left, y: _bottom, scale: _scale};
	    default:
	        return {x: 0, y: 0, scale: 0};
	}
}


