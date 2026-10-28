
// This function call ensures that tuning data is loaded before starting

global.spell_glyphs = {
	form : {
		projectile : new Form_Projectile(),
		beam : new Form_Beam(),
		strike: new Form_Strike(),
		rune: new Form_Rune(),
	},
	effect : {
		fire : new Elem_Fire(),
		ice : new Elem_Ice(),
		lightning : new Elem_Lightning(),
		hex : new Elem_Hex(),
		harm: new Elem_Harm(),
		pull: new Elem_Pull(),
		none : new Elem_None()
	},
	modifier : {
		area : new Mod_Area(),
		amplify : new Mod_Amplify(),
		pierce : new Mod_Pierce(),
		extend_time : new Mod_Extend_Time(),
		delay: new Mod_Delay(),
		none : new Mod_None()
	}
};

global.glyph_order = {
	form	:	["projectile", "beam", "strike", "rune"],
	effect	:	["fire", "ice", "lightning", "harm", "pull", "hex"],
	modifier:	["area", "amplify", "pierce", "extend_time", "delay"]
};

function validate_glyphs() {
    var _need = {
        form:     ["name", "cost", "icon", "desc", "on_cast", "on_step", "on_hit", "on_draw"],
        effect:  ["name", "cost", "icon", "desc", "col", "on_cast", "on_hit"],
        modifier: ["name", "cost", "icon", "desc", "scope", "on_cast"]
    };
    var _types = ["form", "effect", "modifier"];
    for (var t = 0; t < 3; t++) {
        var _ids = variable_struct_get_names(global.spell_glyphs[$ _types[t]]);
        for (var i = 0; i < array_length(_ids); i++) {
            var _g = global.spell_glyphs[$ _types[t]][$ _ids[i]];
            for (var k = 0; k < array_length(_need[$ _types[t]]); k++)
                if (!variable_struct_exists(_g, _need[$ _types[t]][k]))
                    show_error(_types[t] + " '" + _ids[i] + "' is missing " + _need[$ _types[t]][k], false);
        }
    }
}

// IDs distinguish casts, deliveries and scheduled applications.
function combat_next_id() {
	if (!variable_global_exists("combat_id")) global.combat_id = 0;
	global.combat_id += 1;
	return global.combat_id;
}

function spell_new_delivery(_spell) {
	_spell.delivery_index += 1;
	return {cast_id: _spell.cast_id, id: combat_next_id(), index: _spell.delivery_index};
}

function apply_effect_group(_spell, _target, _fx) {
	_fx.effect.on_hit(_spell, _target, _fx);
	for (var i = 0; i < array_length(_fx.mods); i++)
		if (_fx.mods[i].on_hit != undefined) _fx.mods[i].on_hit(_spell, _target, _fx);
}

// Snapshots retain immutable compiled values and shared cast hit records, never a projectile.
function spell_snapshot(_spell) {
	return {
		cast_id: _spell.cast_id, caster: _spell.caster,
		compiled: _spell.compiled, form: _spell.compiled.form, col: _spell.col,
		x: _spell.x, y: _spell.y, target_col: _spell.target_col, target_row: _spell.target_row,
		hit_state: _spell.hit_state
	};
}

// The limit belongs to one exact Rune configuration, across all prepared slots.
function rune_trim_to_limit(_key, _limit) {
	var _runes = [];
	for (var i = 0; i < instance_number(obj_spells); i++) {
		var _rune = instance_find(obj_spells, i);
		if (_rune.form.name == "Rune" && _rune.rune_spell_key == _key) array_push(_runes, _rune);
	}
	array_sort(_runes, function(_a, _b) { return _a.rune_creation_order - _b.rune_creation_order; });
	for (var i = 0; i < array_length(_runes) - _limit; i++) instance_destroy(_runes[i]);
}

// Read-only by convention after compilation. Delivery instances own mutable hit state.
function compile_effect_parameters(_id) {
	var _duration = 0;
	switch (_id) { case "fire": case "ice": _duration = 3; break; case "lightning": _duration = 1; break; case "hex": _duration = 5; break; }
	var _params = {base_damage: tune_value("combat", "base_dmg", 100),
		duration: tune_params("effects", _id, "duration", _duration),
		fire_mult: tune_params("effects", "fire", "fire_dmg_mult", 0.4),
		slow_per_stack: tune_params("effects", "ice", "slow_amt_per_stack", 0.2),
		pull_sec: tune_params("effects", "pull", "pull_sec", 0.4),
		hold_sec: tune_params("effects", "pull", "hold_sec", 1.0)};
	if (_id == "snap") {
		_params.damage_per_stack_mult = tune_params("effects", "snap", "damage_per_stack_mult", 1.2);
		if (!is_real(_params.damage_per_stack_mult) || _params.damage_per_stack_mult < 0)
			throw "effects.snap.damage_per_stack_mult must be non-negative";
	}
	if (_id == "combust" || _id == "discharge") {
		_params.damage_mult = tune_params("effects", _id, "damage_mult", 1);
		_params.radius_tiles = tune_params("effects", _id, "radius_tiles", 1);
		_params.area_radius_tiles = tune_params("effects", _id, "area_radius_tiles", 2);
		if (!is_real(_params.damage_mult) || _params.damage_mult < 0)
			throw "Effect damage_mult must be non-negative";
		if (!is_real(_params.radius_tiles) || _params.radius_tiles < 0 || floor(_params.radius_tiles) != _params.radius_tiles
		|| !is_real(_params.area_radius_tiles) || _params.area_radius_tiles < 0 || floor(_params.area_radius_tiles) != _params.area_radius_tiles)
			throw "Effect radii must be non-negative integers";
	}
	if (_id == "combust") {
		_params.explosion_damage_mult = tune_params("effects", _id, "explosion_damage_mult", 1);
		_params.burn_duration = tune_params("effects", _id, "burn_duration", 3);
		_params.burn_damage_mult = tune_params("effects", _id, "burn_damage_mult", 0.4);
		if (!is_real(_params.explosion_damage_mult) || _params.explosion_damage_mult < 0
		|| !is_real(_params.burn_duration) || _params.burn_duration < 0
		|| !is_real(_params.burn_damage_mult) || _params.burn_damage_mult < 0)
			throw "Combust explosion and burn parameters must be non-negative";
	}
	if (_id == "discharge") {
		_params.max_hits_per_enemy = tune_params("effects", _id, "max_hits_per_enemy", 3);
		if (!is_real(_params.max_hits_per_enemy) || _params.max_hits_per_enemy < 1 || floor(_params.max_hits_per_enemy) != _params.max_hits_per_enemy)
			throw "Discharge max_hits_per_enemy must be a positive integer";
	}
	return _params;
}

function compile_spell(_loadout) {
	if (_loadout == undefined || _loadout.form == undefined) return undefined;
	var _g = global.spell_glyphs;
	var _f = _g.form[$ _loadout.form];
	if (!is_struct(_f)) return undefined;

	var _cost = _f.cost;

	var _fmods = [];

	for (var i = 0; i < array_length(_loadout.form_mods); i++) {
		var _m = _g.modifier[$ _loadout.form_mods[i]];
		if (!is_struct(_m)) return undefined;
		array_push(_fmods, _m);
		_cost += _m.cost;
	}

	var _effects = [];
	for (var e = 0; e < array_length(_loadout.effects); e++) {
		var _el = _g.effect[$ _loadout.effects[e].effect];
		if (!is_struct(_el)) return undefined;
		_cost += _el.cost;

		var _mods = [];
		var _amp_count = 0;
		for (var i = 0; i < array_length(_loadout.effects[e].mods); i++) {
			var _m = _g.modifier[$ _loadout.effects[e].mods[i]];
			if (!is_struct(_m)) return undefined;
			array_push(_mods, _m);
			_cost += _m.cost;
			if (_loadout.effects[e].mods[i] == "amplify") {
				var _amp_cost = tune_params("modifiers", "amplify", "cost_increase_per_stack", 5);
				_cost += (_amp_count * _amp_cost);
				_amp_count++;
			}
		}

		array_push(_effects, {index: e, id: _loadout.effects[e].effect, params: compile_effect_parameters(_loadout.effects[e].effect), effect: _el, mods: _mods, effect_multiplier: 1, area: false, duration: 0, delay: 0, delay_after: 0});
	}
	var _compiled = {cost: _cost, form: _f, form_id: _loadout.form,
		form_mods: _fmods, effects: _effects, area: false, pierce: 0};
	if (_loadout.form == "beam") {
		var _ticks_per_second = tune_params("forms", "beam", "ticks_per_second", 4);
		var _damage_multiplier = tune_params("forms", "beam", "damage_multiplier_per_tick", 0.25);
		if (!is_real(_ticks_per_second) || _ticks_per_second <= 0
		|| _ticks_per_second > TARGET_ROOM_SPEED)
			throw "forms.beam.ticks_per_second must be greater than 0 and no more than room speed";
		if (!is_real(_damage_multiplier) || _damage_multiplier < 0)
			throw "forms.beam.damage_multiplier_per_tick must be non-negative";
		_compiled.beam_ticks_per_second = _ticks_per_second;
		_compiled.beam_damage_multiplier_per_tick = _damage_multiplier;
	}
	for (var i = 0; i < array_length(_fmods); i++) {
		var _fn = _fmods[i][$ "on_cast"];
		if (_fn != undefined) _fn(_compiled, undefined);
	}
	var _delay = 0;
	var _segment = 0;
	for (var e = 0; e < array_length(_effects); e++) {
		var _fx = _effects[e];
		for (var i = 0; i < array_length(_fx.mods); i++) {
			var _fn = _fx.mods[i][$ "on_cast"];
			if (_fn != undefined) _fn(_compiled, _fx);
		}
		_fx.delay = _delay;
		_fx.execution_segment = _segment;
		_delay += _fx.delay_after;
		if (array_contains(_loadout.effects[e].mods, "delay")) _segment++;
		_fx.target_policy = (_fx.effect[$ "delivery_kind"] == "location") ? "location" :
			((_compiled.form_id == "strike" || _compiled.form_id == "rune" || _compiled.area) && _compiled.form_id != "beam" ? "area" : "entity");
	}
	return _compiled;
}

function cast_spell(_caster, _loadout, _col, _row) {
	if (_caster.mana_exhausted || !is_spell_usable(_loadout)) return { spell: noone, cost: 0 };
	var _compiled = compile_spell(_loadout);
	if (!is_struct(_compiled)) return { spell: noone, cost: 0 };
	var _f = _compiled.form;
	var _cost = _compiled.cost;
	
	var _rune_limit = 0;
	if (_f.name == "Rune") {
		var _lane = _row div ROWS_PER_LANE;
		_rune_limit = floor(tune_params("forms", "rune", "max_placed", 6));
		if (_rune_limit < 1) return { spell: noone, cost: 0 };
		
		for (var i = 0; i < instance_number(obj_spells); i++) {
			var _existing = instance_find(obj_spells, i);
			if (_existing.form.name != "Rune") continue;
			
			if (_existing.target_col == _col && _existing.lane == _lane) {
				return { spell: noone, cost: 0 }
			}
			
		}
	}

	if (!is_instanceof(_f, Form_Beam)) {
		if (_caster.mana < _cost) {
			return { spell: noone, cost: 0 };
		}
		_caster.mana = max(0, _caster.mana - _cost);
	}
	if (_caster.mana <= 0) {
		_caster.mana = 0;
		_caster.mana_exhausted = true;
	}

	// Track rune casts by their configured spell
	var _rune_spell_key = undefined;
	var _rune_creation_order = -1;
	if (_f.name == "Rune") {
		_rune_spell_key = json_stringify({
			form: _loadout.form,
			form_mods: _loadout.form_mods,
			effects: _loadout.effects
		});
		if (!variable_global_exists("rune_creation_order")) global.rune_creation_order = 0;
		_rune_creation_order = global.rune_creation_order++;
	}

	var _spell = instance_create_layer(_caster.x, _caster.y, "Instances", obj_spells, {
			cast_id     : combat_next_id(),
			compiled    : _compiled,
			caster		: _caster,
			form		: _f,
			form_mods	: _compiled.form_mods,
			effects		: _compiled.effects,
			target_col	: _col,
			target_row	: _row,
			rune_spell_key: _rune_spell_key,
			rune_creation_order: _rune_creation_order
		});

	// Keep at most the max no. of live runes for this exact configured rune spell.
	if (_rune_spell_key != undefined) {
		rune_trim_to_limit(_rune_spell_key, _rune_limit);
	}

	return {
	spell: _spell,
	cost: _cost
	};
}
