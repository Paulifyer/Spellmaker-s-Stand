
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
	effect	:	["fire", "ice", "lightning", "harm", "pull"],
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

/// @description Applies an effect on an enemy
/// @param {Struct|Asset.GMObject} _spell A snapshot of a spell
/// @param {Asset.GMObject} _target Enemy targetted
/// @param {Struct} _fx effects being passed
function apply_effect_group(_spell, _target, _fx) {
	_fx.effect.on_hit(_spell, _target, _fx);
	for (var i = 0; i < array_length(_fx.mods); i++)
		if (_fx.mods[i].on_hit != undefined) _fx.mods[i].on_hit(_spell, _target, _fx);
}

/// @description Applies a scheduled effect on an enemy
/// @param {Struct} _spell A snapshot of a spell
/// @param {Asset.GMObject} _target Enemy targetted
/// @param {Struct} _fx effects being passed
function schedule_effect(_spell, _target, _fx) {
	for (var i = 0; i < array_length(_target.pending_effects); i++)
		if (_target.pending_effects[i].fx == _fx) return;
	array_push(_target.pending_effects, {
		timer: max(1, round(_fx.delay * TARGET_ROOM_SPEED)),
		fx: _fx,
		spell: _spell
	})
}

/// @description Creates a spell snapshot struct
function spell_snapshot(_spell) {
	return {
		caster: _spell.caster,
		form: { is_channel: _spell.form.is_channel },
		col: _spell.col,
		x: _spell.x, y: _spell.y,
		target_col: _spell.target_col, target_row: _spell.target_row
	}
}

function spell_hit(spell, target) {
	if (!instance_exists(target)) return false;
	if (array_contains(spell.hit_list, target)) return false;
	array_push(spell.hit_list, target);
	for (var e = 0; e < array_length(spell.effects); e++) {
		var _fx = spell.effects[e];
		if (_fx.delay > 0) {
			schedule_effect(spell_snapshot(spell), target, _fx);
		} else {
			apply_effect_group(spell, target, _fx);
		}
	}
	return true;
}

function spell_impact(spell, col, lane) {
	for (var e = 0; e < array_length(spell.effects); e++) {
		var _fx = spell.effects[e];
		_fx.effect.on_impact(spell, _fx, col, lane);
	}
}

function spell_hit_area(_spell, _col1, _col2, _lane1, _lane2) {
	_col1 = max(_col1, 0); _col2  = min(_col2, GRID_COLS - 1);
	_lane1 = max(_lane1, 0); _lane2 = min(_lane2, LANE_COUNT - 1);

	with (obj_enemy_parent) {
		var _l = enemy_lane(id);
		var _c = (x - GRID_X0) div TILE_W;
		if (enemy_overlaps_region(id, _col1, _col2, _lane1, _lane2)) {
			spell_hit(_spell, id);
		}
	}
}

function cast_spell(_caster, _loadout, _col, _row) {
	if (_caster.mana_exhausted || !is_spell_usable(_loadout)) return { spell: noone, cost: 0 };

	var _g = global.spell_glyphs;
	var _f = _g.form[$ _loadout.form];
	if (!is_struct(_f)) return { spell: noone, cost: 0 };

	var _cost = _f.cost;

	var _fmods = [];

	for (var i = 0; i < array_length(_loadout.form_mods); i++) {
		var _m = _g.modifier[$ _loadout.form_mods[i]];
		if (!is_struct(_m)) return { spell: noone, cost: 0 };
		array_push(_fmods, _m);
		_cost += _m.cost;
	}

	var _effects = [];
	for (var e = 0; e < array_length(_loadout.effects); e++) {
		var _el = _g.effect[$ _loadout.effects[e].effect];
		if (!is_struct(_el)) return { spell: noone, cost: 0 };
		_cost += _el.cost;

		var _mods = [];
		for (var i = 0; i < array_length(_loadout.effects[e].mods); i++) {
			var _amp_count = 0;
			var _m = _g.modifier[$ _loadout.effects[e].mods[i]];
			if (!is_struct(_m)) return { spell: noone, cost: 0 };
			array_push(_mods, _m);
			_cost += _m.cost;
			if (is_instanceof(_m, Mod_Amplify)) { // Handles Multiple Amplifies on one effect
				var _amp_cost = tune_params("modifiers", "amplify", "cost_increase_per_stack", 5);
				_cost += (_amp_count * _amp_cost);
				_amp_count++;
			}
		}

		array_push(_effects, {effect: _el, mods: _mods, effect_multiplier: 1, duration: 1, delay: 0});
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
			caster		: _caster,
			form		: _f,
			form_mods	: _fmods,
			effects		: _effects,
			target_col	: _col,
			target_row	: _row,
			rune_spell_key: _rune_spell_key,
			rune_creation_order: _rune_creation_order
		});

	// Keep at most the max no. of live runes for this exact configured rune spell.
	if (_rune_spell_key != undefined) {
		var _rune_count = 0;
		var _oldest_rune = noone;
		var _oldest_order = _rune_creation_order;
		for (var i = 0; i < instance_number(obj_spells); i++) {
			var _existing = instance_find(obj_spells, i);
			if (_existing.form.name != "Rune" || _existing.rune_spell_key != _rune_spell_key) continue;
			_rune_count++;
			if (_existing.rune_creation_order < _oldest_order) {
				_oldest_order = _existing.rune_creation_order;
				_oldest_rune = _existing;
			}
		}
		var _max_placed = tune_params("forms", "rune", "max_placed", 6);
		if (_rune_count > 6 && _oldest_rune != noone) instance_destroy(_oldest_rune);
	}

	return {
	spell: _spell,
	cost: _cost
	};
}
