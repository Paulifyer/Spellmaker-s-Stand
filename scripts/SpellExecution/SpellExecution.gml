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
	var _eligible = (_scope.combust.target_policy == "entity" && !_scope.force_area)
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
function spell_execution_scope_create(_spell, _segment, _target, _col, _lane, _radius, _shared_reactions = undefined, _force_area = false) {
	var _combust = undefined;
	for (var i = 0; i < array_length(_spell.effects); i++) {
		var _fx = _spell.effects[i];
		if (_fx.execution_segment == _segment && _fx.id == "combust") _combust = _fx;
	}
	return {id: combat_next_id(), combust: _combust, force_area: _force_area,
		lineage: instance_exists(_target) ? enemy_get_lineage(_target) : undefined,
		col: _col, lane: _lane, radius: _radius, exploded: {}, reactions: (_shared_reactions == undefined) ? {} : _shared_reactions, queue: [], cursor: 0, processing: false};
}

function spell_discharge_enqueue(_scope, _fx, _source, _reaction) {
	if (!combat_status_charged(_source) || !spell_reaction_claim_emitter(_reaction, _source)) return;
	array_push(_scope.queue, {kind: "discharge", fx: _fx, source: _source, x: _source.x, y: _source.y, reaction: _reaction});
}

function spell_discharge(_spell, _target, _fx) {
	if (_target.hp <= 0 || !combat_status_charged(_target)) return;
	var _scope = _spell.execution_scope;
	var _key = string(_fx.index);
	if (!variable_struct_exists(_scope.reactions, _key)) _scope.reactions[$ _key] = spell_reaction_create();
	spell_discharge_enqueue(_scope, _fx, _target, _scope.reactions[$ _key]);
	spell_drain_bursts(_spell, _scope);
}

function spell_drain_bursts(_spell, _scope) {
	if (_scope.processing) return;
	_scope.processing = true;
	while (_scope.cursor < array_length(_scope.queue)) {
		var _burst = _scope.queue[_scope.cursor++];
		var _fx = _burst.fx;
		if (_burst.kind == "discharge" && instance_exists(_burst.source)) combat_status_consume_charge(_burst.source);
		var _radius = _fx.area ? _fx.params.area_radius_tiles : _fx.params.radius_tiles;
		var _targets = spell_reaction_targets(_spell, _burst.x, _burst.y, _radius);
		for (var i = 0; i < array_length(_targets); i++) {
			var _target = _targets[i];
			if (!instance_exists(_target) || _target.hp <= 0) continue;
			if (_burst.kind == "combust") {
				spell_direct_damage(_spell, _target, _fx.params.base_damage * _fx.params.explosion_damage_mult * _fx.effect_multiplier * spell_damage_scale(_spell), false);
				combat_status_apply(_target, "burn", _fx.params.burn_duration * TARGET_ROOM_SPEED, _fx.params.base_damage * _fx.params.burn_damage_mult * _fx.effect_multiplier);
			} else if (_burst.kind == "discharge") {
				if (!spell_reaction_claim_hit(_burst.reaction, _target, _fx.params.max_hits_per_enemy)) continue;
				// Reserve a charged victim's emission before lethal damage can remove it.
				spell_discharge_enqueue(_scope, _fx, _target, _burst.reaction);
				spell_direct_damage(_spell, _target, _fx.params.base_damage * _fx.params.damage_mult * _fx.effect_multiplier * spell_damage_scale(_spell));
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
function spell_deliver_payload(_spell, _target, _col, _lane, _radius = 0, _force_area = false) {
	var _state = combat_execution_state();
	if (!is_struct(_state)) return false;
	if (instance_exists(_target)) {
		if (!enemy_can_receive_spell(_target, _spell.compiled) || spell_contacted(_spell, _target)) return false;
		spell_record_contact(_spell, _target);
	}
	var _delivery = spell_new_delivery(_spell);
	var _snapshot = spell_snapshot(_spell);
	var _scopes = {};
	var _shared_reactions = undefined;
	if (_spell.form.is_channel) {
		var _has_epoch = is_struct(_spell) ? variable_struct_exists(_spell, "reaction_epoch") : variable_instance_exists(_spell, "reaction_epoch");
		if (!_has_epoch || _spell.reaction_epoch != _spell.hit_state.epoch) {
			_spell.reaction_epoch = _spell.hit_state.epoch;
			_spell.discharge_reactions = {};
		}
		_shared_reactions = _spell.discharge_reactions;
	}
	for (var e = 0; e < array_length(_spell.effects); e++) {
		var _fx = _spell.effects[e];
		var _segment_key = string(_fx.execution_segment);
		if (!variable_struct_exists(_scopes, _segment_key))
			_scopes[$ _segment_key] = spell_execution_scope_create(_spell, _fx.execution_segment, _target, _col, _lane, _radius, _shared_reactions, _force_area);
		var _policy = (_force_area && _fx.target_policy != "location") ? "area" : _fx.target_policy;
		var _lineage = (_policy == "entity" && instance_exists(_target)) ? enemy_get_lineage(_target) : undefined;
		if (_policy == "entity" && _lineage == undefined) continue;
		var _event = {due: _state.clock + max(0, round(_fx.delay * TARGET_ROOM_SPEED)), order: combat_next_id(),
			cast_id: _delivery.cast_id, delivery_id: _delivery.id, fx: _fx, policy: _policy,
			lineage: _lineage, col: _col, lane: _lane, radius: _radius,
			epoch: _spell.hit_state.epoch, spell: _snapshot, scope: _scopes[$ _segment_key]};
		array_push(_state.events, _event);
	}
	combat_execution_flush(_state);
	return true;
}

function spell_chain_state(_spell) {
	var _hits = _spell.hit_state;
	if (!variable_struct_exists(_hits, "chain") || _hits.chain.epoch != _hits.epoch)
		_hits.chain = {epoch: _hits.epoch, visited: {}, reserved_roots: {}};
	return _hits.chain;
}

function spell_chain_fresh(_spell, _enemy) {
	if (!enemy_can_receive_spell(_enemy, _spell.compiled) || _enemy.hp <= 0 || spell_contacted(_spell, _enemy)) return false;
	return !variable_struct_exists(spell_chain_state(_spell).visited, string(enemy_get_lineage(_enemy).id));
}

function spell_chain_nearest(_spell, _candidates, _x, _y, _exclude_roots = true) {
	var _best = noone, _distance = 1e30, _best_id = 1e30;
	var _state = spell_chain_state(_spell);
	for (var i = 0; i < array_length(_candidates); i++) {
		var _enemy = _candidates[i];
		if (!spell_chain_fresh(_spell, _enemy)) continue;
		var _id = enemy_get_lineage(_enemy).id;
		if (_exclude_roots && variable_struct_exists(_state.reserved_roots, string(_id))) continue;
		var _dx = _enemy.x - _x, _dy = _enemy.y - _y;
		var _d = _dx * _dx + _dy * _dy;
		if (_d < _distance || (_d == _distance && _id < _best_id)) {
			_best = _enemy; _distance = _d; _best_id = _id;
		}
	}
	return _best;
}

function spell_chain_visit_region(_spell, _col, _lane, _radius) {
	var _state = spell_chain_state(_spell);
	var _targets = enemies_in_region_list(_col - _radius, _col + _radius, _lane - _radius, _lane + _radius);
	for (var i = 0; i < array_length(_targets); i++) {
		var _enemy = _targets[i];
		if (enemy_can_receive_spell(_enemy, _spell.compiled) && _enemy.hp > 0)
			_state.visited[$ string(enemy_get_lineage(_enemy).id)] = true;
	}
}

// Reserve Beam's primary hits before traversal, so earlier chains cannot steal later roots.
function spell_chain_reserve_roots(_spell, _targets) {
	if (_spell.compiled.chain_hops <= 0) return;
	var _state = spell_chain_state(_spell);
	for (var i = 0; i < array_length(_targets); i++)
		_state.reserved_roots[$ string(enemy_get_lineage(_targets[i]).id)] = true;
}

function spell_chain_add_link(_spell, _x1, _y1, _x2, _y2) {
	var _state = combat_execution_state();
	if (!is_struct(_state) || _spell.compiled.chain_visual_frames <= 0) return;
	if (!variable_struct_exists(_state, "chain_links")) _state.chain_links = [];
	array_push(_state.chain_links, {x1: _x1, y1: _y1, x2: _x2, y2: _y2, colour: _spell.col,
		born: _state.clock, duration: _spell.compiled.chain_visual_frames});
}

function spell_deliver(_spell, _target, _col, _lane, _radius = 0) {
	if (_spell.compiled.chain_hops <= 0) return spell_deliver_payload(_spell, _target, _col, _lane, _radius);
	var _execution = combat_execution_state();
	if (!is_struct(_execution)) return false;
	var _seed = _target;
	if (instance_exists(_seed)) {
		if (!spell_chain_fresh(_spell, _seed)) return false;
	} else {
		var _candidates = enemies_in_region_list(_col - _radius, _col + _radius, _lane - _radius, _lane + _radius);
		_seed = spell_chain_nearest(_spell, _candidates, GRID_X0 + (_col + 0.5) * TILE_W, global.lane_top[_lane] + LANE_H / 2, false);
	}
	// A location-only effect may still execute in an empty tile; it has no chain root.
	if (!instance_exists(_seed)) return spell_deliver_payload(_spell, _target, _col, _lane, _radius);
	var _last_x = _seed.x, _last_y = _seed.y;
	var _state = spell_chain_state(_spell);
	_state.visited[$ string(enemy_get_lineage(_seed).id)] = true;
	if (_spell.compiled.form_id == "strike" || _spell.compiled.form_id == "rune" || (_spell.area && !_spell.form.is_channel))
		spell_chain_visit_region(_spell, _col, _lane, _radius);
	if (!spell_deliver_payload(_spell, _target, _col, _lane, _radius)) return false;
	for (var h = 0; h < _spell.compiled.chain_hops; h++) {
		var _near = spell_reaction_targets(_spell, _last_x, _last_y, _spell.compiled.chain_range_radius);
		var _next = spell_chain_nearest(_spell, _near, _last_x, _last_y);
		if (!instance_exists(_next)) break;
		var _x = _next.x, _y = _next.y, _tile = world_to_grid(_x, _y);
		if (_tile == undefined) break;
		_state.visited[$ string(enemy_get_lineage(_next).id)] = true;
		var _r = _spell.area ? 1 : 0;
		if (_spell.area || _spell.compiled.form_id == "strike" || _spell.compiled.form_id == "rune")
			spell_chain_visit_region(_spell, _tile.col, _tile.lane, _r);
		spell_chain_add_link(_spell, _last_x, _last_y, _x, _y);
		spell_deliver_payload(_spell, _next, _tile.col, _tile.lane, _r, _spell.form.is_channel && _spell.area);
		_last_x = _x; _last_y = _y;
	}
	return true;
}
