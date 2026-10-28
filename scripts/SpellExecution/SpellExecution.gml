// A room-owned clock and queue. Begin Step advances time; End Step drains due work.
function combat_execution_create() {
	return {clock: 0, events: [], processing: false};
}

function spell_damage_scale(_spell) {
	return _spell.form.is_channel ? _spell.compiled.beam_damage_multiplier_per_tick : 1;
}

function spell_direct_damage(_spell, _enemy, _amount, _allow_combust = true) {
	if (_enemy.hp <= 0) return;
	var _burning = combat_status_active(_enemy, "burn");
	deal_damage(_enemy, _amount);
	if (!_allow_combust || !_burning || _enemy.hp > 0) return;
	if (!is_struct(_spell) || !variable_struct_exists(_spell, "execution_scope")) return;
	var _scope = _spell.execution_scope;
	if (!is_struct(_scope) || _scope.combust == undefined) return;
	var _eligible = (_scope.combust.target_policy == "entity")
		? (_scope.lineage == enemy_get_lineage(_enemy))
		: enemy_overlaps_region(_enemy, _scope.col - _scope.radius, _scope.col + _scope.radius, _scope.lane - _scope.radius, _scope.lane + _scope.radius);
	if (!_eligible) return;
	var _key = string(enemy_get_lineage(_enemy).id);
	if (variable_struct_exists(_scope.exploded, _key)) return;
	_scope.exploded[$ _key] = true;
	array_push(_scope.queue, {kind: "combust", fx: _scope.combust, x: _enemy.x, y: _enemy.y});
	spell_drain_bursts(_spell, _scope);
}

// Each Delay boundary owns a separate immediate execution context.
function spell_execution_scope_create(_spell, _segment, _target, _col, _lane, _radius) {
	var _combust = undefined;
	for (var i = 0; i < array_length(_spell.effects); i++) {
		var _fx = _spell.effects[i];
		if (_fx.execution_segment == _segment && _fx.id == "combust") _combust = _fx;
	}
	return {id: combat_next_id(), combust: _combust,
		lineage: instance_exists(_target) ? enemy_get_lineage(_target) : undefined,
		col: _col, lane: _lane, radius: _radius, exploded: {}, reactions: {}, queue: [], cursor: 0, processing: false};
}

function spell_drain_bursts(_spell, _scope) {
	if (_scope.processing) return;
	_scope.processing = true;
	while (_scope.cursor < array_length(_scope.queue)) {
		var _burst = _scope.queue[_scope.cursor++];
		var _fx = _burst.fx;
		var _radius = _fx.area ? _fx.params.area_radius_tiles : _fx.params.radius_tiles;
		var _targets = spell_reaction_targets(_spell, _burst.x, _burst.y, _radius);
		for (var i = 0; i < array_length(_targets); i++) {
			var _target = _targets[i];
			if (!instance_exists(_target) || _target.hp <= 0) continue;
			if (_burst.kind == "combust") {
				spell_direct_damage(_spell, _target, _fx.params.base_damage * _fx.params.explosion_damage_mult * _fx.effect_multiplier * spell_damage_scale(_spell), false);
				combat_status_apply(_target, "burn", _fx.params.burn_duration * TARGET_ROOM_SPEED, _fx.params.base_damage * _fx.params.burn_damage_mult * _fx.effect_multiplier);
			}
		}
	}
	_scope.queue = []; _scope.cursor = 0; _scope.processing = false;
}

// Mutable reaction state belongs to one effect occurrence, not the glyph singleton.
function spell_reaction_create() {
	return {id: combat_next_id(), emitted: {}, hits: {}};
}

function spell_reaction_claim_emitter(_reaction, _enemy) {
	var _key = string(enemy_get_lineage(_enemy).id);
	if (variable_struct_exists(_reaction.emitted, _key)) return false;
	_reaction.emitted[$ _key] = true;
	return true;
}

function spell_reaction_claim_hit(_reaction, _enemy, _limit) {
	var _key = string(enemy_get_lineage(_enemy).id);
	var _count = variable_struct_exists(_reaction.hits, _key) ? _reaction.hits[$ _key] : 0;
	if (_count >= _limit) return false;
	_reaction.hits[$ _key] = _count + 1;
	return true;
}

function spell_reaction_targets(_spell, _x, _y, _radius) {
	var _tile = world_to_grid(_x, _y);
	if (_tile == undefined) return [];
	var _candidates = enemies_in_region_list(_tile.col - _radius, _tile.col + _radius, _tile.lane - _radius, _tile.lane + _radius);
	var _targets = [];
	for (var i = 0; i < array_length(_candidates); i++) {
		var _enemy = _candidates[i];
		if (_enemy.hp > 0 && enemy_can_receive_spell(_enemy, _spell.compiled)) array_push(_targets, _enemy);
	}
	return _targets;
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
	_event.spell.execution_scope = _event.scope;
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
	var _scopes = {};
	for (var e = 0; e < array_length(_spell.effects); e++) {
		var _fx = _spell.effects[e];
		var _segment_key = string(_fx.execution_segment);
		if (!variable_struct_exists(_scopes, _segment_key))
			_scopes[$ _segment_key] = spell_execution_scope_create(_spell, _fx.execution_segment, _target, _col, _lane, _radius);
		var _lineage = (_fx.target_policy == "entity" && instance_exists(_target)) ? enemy_get_lineage(_target) : undefined;
		if (_fx.target_policy == "entity" && _lineage == undefined) continue;
		var _event = {due: _state.clock + max(0, round(_fx.delay * TARGET_ROOM_SPEED)), order: combat_next_id(),
			cast_id: _delivery.cast_id, delivery_id: _delivery.id, fx: _fx, policy: _fx.target_policy,
			lineage: _lineage, col: _col, lane: _lane, radius: _radius,
			epoch: _spell.hit_state.epoch, spell: _snapshot, scope: _scopes[$ _segment_key]};
		array_push(_state.events, _event);
	}
	combat_execution_flush(_state);
	return true;
}
