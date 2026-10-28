
// Advance the same stun/charged clock for live enemies and skeletal spawn gaps.
function enemy_get_lineage(_enemy) {
	if (!variable_instance_exists(_enemy, "combat_lineage") || _enemy.combat_lineage == undefined) {
		_enemy.combat_lineage = {id: combat_next_id(), target: _enemy, alive: true, gap: false};
	}
	return _enemy.combat_lineage;
}

function enemy_bind_lineage(_enemy, _lineage) {
	_enemy.combat_lineage = _lineage;
	_lineage.target = _enemy;
	_lineage.gap = false;
}

function enemy_advance_lightning(_state, _frames) {
	_frames = max(0, _frames);
	var _stun = max(0, _state.stun_timer);
	_state.stun_timer = max(0, _stun - _frames);
	if (_stun > 0 && _stun <= _frames) {
		var _charged = round(tune_params("effects", "lightning", "stun_immune_duration", 3) * TARGET_ROOM_SPEED);
		_state.stun_immune_timer = max(0, _charged - (_frames - _stun));
	} else {
		_state.stun_immune_timer = max(0, _state.stun_immune_timer - _frames);
	}
}

// Resolve speed once after status updates; Stun/Pull control actual path movement.
function enemy_update_movement(_enemy, _multiplier = 1) {
	var _slow = (_enemy.slow_timer > 0) ? clamp(_enemy.slow_amt, 0, 0.6) : 0;
	_enemy.my_speed = max(0, _enemy.base_speed * _multiplier * (1 - _slow));
	_enemy.path_speed = (_enemy.stun_timer > 0 || _enemy.pull != undefined) ? 0 : _enemy.my_speed;
}

function enemy_begin_pull(_e, _x, _y, _lane, _frames, _hold) {
	if (_e.pull != undefined || _e.is_pull_immune) return;
	_e.pull = {
		sx: _e.x, sy: _e.y, tx: _x, ty: _y,
		t: 0, dur: max(1, _frames), hold: _hold, lane: _lane,
		xs: _e.image_xscale, ys: _e.image_yscale
	};
	with (_e) path_end(); // Stops path movement to freely move the enemy
}

function enemy_update_pull(_e) {
	var _p = _e.pull;
	_p.t++;
	
	if (_p.t <= _p.dur) {
		var _k = _p.t / _p.dur; // accelerates inward like suction
		var _ease = _k * _k;
		var _dx = _p.sx - _p.tx, _dy = _p.sy - _p.ty;
		var _r = point_distance(0, 0, _dx, _dy) * (1 - _ease); // spiral as it closes in
		var _a = point_direction(0, 0, _dx, _dy) + _ease * 120;
		_e.x = _p.tx + lengthdir_x(_r, _a);
		_e.y = _p.ty + lengthdir_y(_r, _a);
		var _s = lerp(1, 0.7, _ease);
		_e.image_xscale = _p.xs * _s;
		_e.image_yscale = _p.ys * _s;
	} else if (_p.t > _p.dur + _p.hold) {
		enemy_end_pull(_e);
	}
}

function enemy_end_pull(_e) {
	var _p = _e.pull;
	show_debug_message(_p.lane);
	var _path = _e.wave_owner.level_paths[_p.lane];
	
	var _best = 0, _bestd = 99999999;
	for (var i = 0; i <= 100; i++) {
		var _d = point_distance(path_get_x(_path, i / 100), path_get_y(_path, i/100), _e.x, _e.y);
		if (_d < _bestd) { _bestd = _d; _best = i / 100; }
	}
	_e.image_xscale = _p.xs;
    _e.image_yscale = _p.ys;
    _e.lane = _p.lane;
    _e.pull = undefined;

    with (_e) {
        path_start(_path, my_speed, path_action_stop, true);
        path_position = _best;
    }
}
