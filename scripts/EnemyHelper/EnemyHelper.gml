
// Advance the same stun/charged clock for live enemies and skeletal spawn gaps.
// Registry owns expiry, counting, display and transfer metadata. Legacy fields remain
// adapters for enemy abilities; there is no second copy of the status state.
function combat_status_definitions() {
	if (!variable_global_exists("combat_status_definitions")) {
		global.combat_status_definitions = [
			{key: "burn", timer: "burn_timer", fields: ["burn_timer", "burn_dmg"], colour: c_red},
			{key: "frost", timer: "slow_timer", fields: ["slow_timer", "slow_amt"], colour: c_teal},
			{key: "lightning", timer: "stun_timer", fields: ["stun_timer", "stun_immune_timer"], colour: c_yellow},
			{key: "hex", timer: "hex_timer", fields: ["hex_timer"], colour: c_fuchsia}
		];
	}
	return global.combat_status_definitions;
}

function combat_status_get(_subject, _field) {
	return is_struct(_subject) ? _subject[$ _field] : variable_instance_get(_subject, _field);
}

function combat_status_initialize(_subject) {
	var _defs = combat_status_definitions();
	for (var i = 0; i < array_length(_defs); i++) {
		for (var j = 0; j < array_length(_defs[i].fields); j++) combat_status_set(_subject, _defs[i].fields[j], 0);
	}
}

function combat_status_set(_subject, _field, _value) {
	if (is_struct(_subject)) _subject[$ _field] = _value;
	else variable_instance_set(_subject, _field, _value);
}

function combat_status_active(_subject, _key) {
	var _defs = combat_status_definitions();
	for (var i = 0; i < array_length(_defs); i++) {
		var _def = _defs[i];
		if (_def.key != _key) continue;
		if (_key == "lightning" && combat_status_get(_subject, "stun_immune_timer") > 0) return true;
		return combat_status_get(_subject, _def.timer) > 0;
	}
	return false;
}

function combat_status_count(_subject) {
	var _count = 0;
	var _defs = combat_status_definitions();
	for (var i = 0; i < array_length(_defs); i++) if (combat_status_active(_subject, _defs[i].key)) _count++;
	return _count;
}

function combat_status_apply(_enemy, _key, _frames, _strength = 0) {
	_frames = max(0, round(_frames));
	switch (_key) {
		case "burn": _enemy.burn_timer = _frames; _enemy.burn_dmg = _strength; break;
		case "frost": _enemy.slow_timer = _frames; _enemy.slow_amt = clamp(_enemy.slow_amt + _strength, 0, 0.6); break;
		case "lightning":
			if (!combat_status_active(_enemy, "lightning")) {
				_enemy.stun_timer = _frames;
				if (_frames > 0) enemy_interrupt_charge(_enemy, "stun");
			}
			break;
		case "hex": _enemy.hex_timer = _frames; break;
	}
}

function combat_status_capture(_subject) {
	var _state = {};
	var _defs = combat_status_definitions();
	for (var i = 0; i < array_length(_defs); i++) {
		var _fields = _defs[i].fields;
		for (var j = 0; j < array_length(_fields); j++) {
			var _field = _fields[j];
			_state[$ _field] = max(0, combat_status_get(_subject, _field));
		}
	}
	return _state;
}

function combat_status_restore(_subject, _state) {
	var _defs = combat_status_definitions();
	for (var i = 0; i < array_length(_defs); i++) {
		var _fields = _defs[i].fields;
		for (var j = 0; j < array_length(_fields); j++) combat_status_set(_subject, _fields[j], _state[$ _fields[j]]);
	}
	if (!combat_status_active(_subject, "frost")) combat_status_set(_subject, "slow_amt", 0);
}

function combat_status_advance(_subject, _frames, _live = true) {
	_frames = max(0, round(_frames));
	var _defs = combat_status_definitions();
	for (var i = 0; i < array_length(_defs); i++) {
		var _def = _defs[i];
		if (_def.key == "lightning") { enemy_advance_lightning(_subject, _frames); continue; }
		var _before = max(0, combat_status_get(_subject, _def.timer));
		if (_def.key == "burn" && _live) {
			for (var t = 1; t <= min(_frames, _before); t++) {
				if ((_before - t) mod TARGET_ROOM_SPEED == 0) deal_damage(_subject, _subject.burn_dmg);
			}
		}
		combat_status_set(_subject, _def.timer, max(0, _before - _frames));
	}
	if (!combat_status_active(_subject, "frost")) combat_status_set(_subject, "slow_amt", 0);
}

function enemy_get_lineage(_enemy) {
	if (!variable_instance_exists(_enemy, "combat_lineage") || _enemy.combat_lineage == undefined) {
		_enemy.combat_lineage = {id: combat_next_id(), target: _enemy, alive: true, gap: false};
	}
	return _enemy.combat_lineage;
}

// Barricades can call this same hook when Earth/obstacle delivery is implemented.
function enemy_interrupt_charge(_enemy, _reason) {
	if (!variable_instance_exists(_enemy, "charge_active") || !_enemy.charge_active) return;
	_enemy.charge_active = false;
	_enemy.charge_interrupt_reason = _reason;
	_enemy.base_speed = _enemy.normal_speed;
	_enemy.ready_to_attack = false;
	_enemy.siege_attack_timer = -1;
	enemy_update_movement(_enemy);
}

function enemy_siege_attack(_enemy) {
	if (_enemy.hp <= 0) return;
	if (_enemy.stun_timer > 0) { enemy_interrupt_charge(_enemy, "stun"); return; }
	if (_enemy.pull != undefined) return;
	if (_enemy.path_position < 1) { _enemy.siege_attack_timer = -1; return; }
	var _windup = max(1, round(_enemy.attack_delay * TARGET_ROOM_SPEED));
	if (_enemy.charge_active) {
		reduce_village_hp(_enemy.damage_dealt * tune_enemy("siege_beast", "charge_attack_mult", 2));
		enemy_interrupt_charge(_enemy, "impact");
		_enemy.siege_attack_timer = _windup;
		return;
	}
	if (_enemy.siege_attack_timer < 0) { _enemy.siege_attack_timer = _windup; return; }
	_enemy.siege_attack_timer--;
	if (_enemy.siege_attack_timer <= 0) {
		reduce_village_hp(_enemy.damage_dealt);
		_enemy.siege_attack_timer = _windup;
	}
}

function enemy_resolve_siege_attacks() {
	for (var i = 0; i < instance_number(obj_siege_beast); i++) enemy_siege_attack(instance_find(obj_siege_beast, i));
}

function enemy_initialize_mole_marker(_enemy, _path) {
	if (_enemy.object_index != obj_mole || !path_exists(_path)) return;
	_enemy.emergence_marker = {x: path_get_x(_path, _enemy.pos_to_stop), y: path_get_y(_path, _enemy.pos_to_stop), active: true};
}

// Notification comes from combat death, never from Destroy/room cleanup/replacement.
function enemy_notify_combat_death(_enemy) {
	if (_enemy.hp > 0 || _enemy.death_notified || enemy_is_bonepile(_enemy)) return;
	_enemy.death_notified = true;
	var _radius = max(0, floor(tune_enemy("carrion", "feed_radius_tiles", 1)));
	for (var i = 0; i < instance_number(obj_carrion); i++) {
		var _carrion = instance_find(obj_carrion, i);
		if (_carrion == _enemy || _carrion.hp <= 0) continue;
		var _tile = world_to_grid(_carrion.x, _carrion.y);
		if (_tile == undefined || !enemy_overlaps_region(_enemy, _tile.col - _radius, _tile.col + _radius, _tile.lane - _radius, _tile.lane + _radius)) continue;
		var _hp = tune_value("enemies", "base_hp", BASE_HP) * _carrion.enrage_hp_mult;
		var _speed = tune_value("enemies", "base_speed", BASE_SPEED) * _carrion.enrage_spd_mult;
		_carrion.max_hp += _hp; _carrion.hp += _hp; _carrion.base_speed += _speed;
		_carrion.image_xscale += 0.1; _carrion.image_yscale += 0.1; _carrion.hit_w += 12;
		enemy_update_movement(_carrion);
		instance_create_depth(_enemy.x, _enemy.y - 30, _enemy.depth - 1, obj_siphon, {target: _carrion});
	}
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
	_enemy.my_speed = max(0, _enemy.base_speed * _multiplier * enemy_banner_speed(_enemy) * (1 - _slow));
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
