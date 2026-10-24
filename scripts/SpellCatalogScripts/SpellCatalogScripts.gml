
// This function call ensures that tuning data is loaded before starting

global.spell_glyphs = {
	form : {
		projectile : new Form_Projectile(),
		beam : new Form_Beam(),
		strike: new Form_Strike() 
	},
	effect : {
		fire : new Elem_Fire(),
		ice : new Elem_Ice(),
		lightning : new Elem_Lightning(),
		harm: new Elem_Harm(),
		none : new Elem_None()
	},
	modifier : {
		area : new Mod_Area(),
		amplify : new Mod_Amplify(),
		pierce : new Mod_Pierce(),
		extend_time : new Mod_Extend_Time(),
		none : new Mod_None()
	}
};

global.glyph_order = {
	form	:	["projectile", "beam", "strike"],
	effect	:	["fire", "ice", "lightning", "harm"],
	modifier:	["area", "amplify", "pierce", "extend_time"]
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

function spell_hit(spell, target) {
	if (!instance_exists(target)) return false;
	if (array_contains(spell.hit_list, target)) return false;
	array_push(spell.hit_list, target);
	spell.form.on_hit(spell, target);
	for (var e = 0; e < array_length(spell.effects); e++) {
		var _fx = spell.effects[e];
		_fx.effect.on_hit(spell, target, _fx);
		for (var i = 0; i < array_length(spell.effects[e].mods); i++) {
			var _mod = spell.effects[e].mods[i];
			if (_mod.on_hit != undefined) _mod.on_hit(spell, target);	
		}
	}
	return true;
}

function spell_hit_area(_spell, _col1, _col2, _lane1, _lane2) {
	_col1 = max(_col1, 0); _col  = min(_col2, GRID_COLS - 1);
	_lane1 = max(_lane1, 0); _lane2 = min(_lane2, LANE_COUNT - 1);
	
	with (obj_enemy_parent) {
		var _l = enemy_lane(id);
		var _c = (x - GRID_X0) div TILE_W;
		if (_l >= _lane1 && _l <= _lane2 && _c >= _col1 && _c <= _col2) {
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
		
		array_push(_effects, {effect: _el, mods: _mods, effect_multiplier: 1, duration: 1});
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
	
	return {
	spell: instance_create_layer(_caster.x, _caster.y, "Instances", obj_spells, {
			caster		: _caster,
			form		: _f,
			form_mods	: _fmods,
			effects		: _effects,
			target_col	: _col,
			target_row	: _row
		}),
	cost: _cost
	};
}
