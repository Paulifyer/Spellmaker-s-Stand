// A room-owned clock and queue. Begin Step advances time; End Step drains due work.
function combat_execution_create() {
	return {clock: 0, events: [], processing: false};
}

function combat_execution_state() {
	var _manager = instance_find(obj_gameplay_manager, 0);
	return instance_exists(_manager) ? _manager.combat_execution : undefined;
}

function spell_contacted(_spell, _enemy) {
	return array_contains(_spell.hit_state.contacts, enemy_get_lineage(_enemy).id);
}

function enemy_can_receive_spell(_enemy, _compiled) {
	if (!instance_exists(_enemy) || !_enemy.is_targetable) return false;
	if (_compiled.form_id == "rune" && _enemy.object_index == obj_swarmer) return false;
	return true;
}

function spell_record_contact(_spell, _enemy) {
	var _id = enemy_get_lineage(_enemy).id;
	if (!array_contains(_spell.hit_state.contacts, _id)) array_push(_spell.hit_state.contacts, _id);
}

function spell_apply_once(_event, _enemy) {
	if (!enemy_can_receive_spell(_enemy, _event.spell.compiled)) return;
	var _lineage = enemy_get_lineage(_enemy);
	var _key = string(_event.fx.index) + ":" + string(_event.epoch) + ":" + string(_lineage.id);
	if (variable_struct_exists(_event.spell.hit_state.applications, _key)) return;
	_event.spell.hit_state.applications[$ _key] = true;
	// An old delayed Beam tick must not claim a contact in the current tick.
	if (!_event.spell.form.is_channel || _event.epoch == _event.spell.hit_state.epoch) spell_record_contact(_event.spell, _enemy);
	apply_effect_group(_event.spell, _enemy, _event.fx);
}

function combat_execute_event(_event) {
	switch (_event.policy) {
		case "location":
			_event.fx.effect.on_impact(_event.spell, _event.fx, _event.col, _event.lane);
			break;
		case "area":
			var _r = _event.radius;
			var _targets = enemies_in_region_list(_event.col - _r, _event.col + _r, _event.lane - _r, _event.lane + _r);
			for (var i = 0; i < array_length(_targets); i++) spell_apply_once(_event, _targets[i]);
			break;
		case "entity":
			if (_event.lineage.alive && !_event.lineage.gap) spell_apply_once(_event, _event.lineage.target);
			break;
	}
}

function combat_event_before(_a, _b) {
	return (_a.due == _b.due) ? _a.order - _b.order : _a.due - _b.due;
}

// A lineage flush runs gap-overdue work when the pile first becomes available.
function combat_execution_flush(_state, _lineage = undefined) {
	if (_state.processing) return;
	_state.processing = true;
	while (true) {
		var _ready = [];
		var _waiting = [];
		for (var i = 0; i < array_length(_state.events); i++) {
			var _event = _state.events[i];
			if (_event.policy == "entity" && !_event.lineage.alive) continue;
			var _eligible = _event.due <= _state.clock;
			if (_lineage != undefined && _event.lineage != _lineage) _eligible = false;
			if (_event.policy == "entity" && (_event.lineage.gap || !instance_exists(_event.lineage.target))) _eligible = false;
			if (_eligible) array_push(_ready, _event); else array_push(_waiting, _event);
		}
		_state.events = _waiting;
		if (array_length(_ready) == 0) break;
		array_sort(_ready, combat_event_before);
		for (var i = 0; i < array_length(_ready); i++) {
			var _event = _ready[i];
			if (_event.policy == "entity") {
				if (!_event.lineage.alive) continue;
				if (_event.lineage.gap) { array_push(_state.events, _event); continue; }
			}
			combat_execute_event(_event);
		}
	}
	_state.processing = false;
}

function combat_flush_lineage(_lineage) {
	var _state = combat_execution_state();
	if (is_struct(_state)) combat_execution_flush(_state, _lineage);
}

// A delivery starts all Effects in written order. Delay schedules activation;
// it never waits implicitly for Pull movement to finish.
function spell_deliver(_spell, _target, _col, _lane, _radius = 0) {
	var _state = combat_execution_state();
	if (!is_struct(_state)) return false;
	if (instance_exists(_target)) {
		if (!enemy_can_receive_spell(_target, _spell.compiled) || spell_contacted(_spell, _target)) return false;
		spell_record_contact(_spell, _target);
	}
	var _delivery = spell_new_delivery(_spell);
	var _snapshot = spell_snapshot(_spell);
	for (var e = 0; e < array_length(_spell.effects); e++) {
		var _fx = _spell.effects[e];
		var _lineage = (_fx.target_policy == "entity" && instance_exists(_target)) ? enemy_get_lineage(_target) : undefined;
		if (_fx.target_policy == "entity" && _lineage == undefined) continue;
		var _event = {due: _state.clock + max(0, round(_fx.delay * TARGET_ROOM_SPEED)), order: combat_next_id(),
			cast_id: _delivery.cast_id, delivery_id: _delivery.id, fx: _fx, policy: _fx.target_policy,
			lineage: _lineage, col: _col, lane: _lane, radius: _radius,
			epoch: _spell.hit_state.epoch, spell: _snapshot};
		array_push(_state.events, _event);
	}
	combat_execution_flush(_state);
	return true;
}
