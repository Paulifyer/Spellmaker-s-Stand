
global.spell_glyphs = {
	form : {
		projectile : new Form_Projectile(),
		beam : new Form_Beam(),
		strike: new Form_Strike() 
	},
	element : {
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
	element	:	["fire", "ice", "lightning", "harm"],
	modifier:	["area", "amplify", "pierce", "extend_time"]
};


function spell_hit(spell, target) { // For non collision based 
	if (!instance_exists(target)) return false;
	if (array_contains(spell.hit_list, target)) return false;
	array_push(spell.hit_list, target);
	spell.form.on_hit(spell, target);
	for (var e = 0; e < array_length(spell.effects); e++) {
		var _fx = spell.effects[e];
		_fx.element.on_hit(spell, target, _fx);
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
	if (_caster.mana_exhausted) return { spell: noone, cost: 0 };
	
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
		var _el = _g.element[$ _loadout.effects[e].element];
		if (!is_struct(_el)) return { spell: noone, cost: 0 };
		_cost += _el.cost;
		
		var _mods = [];
		for (var i = 0; i < array_length(_loadout.effects[e].mods); i++) {
			var _m = _g.modifier[$ _loadout.effects[e].mods[i]];
			if (!is_struct(_m)) return { spell: noone, cost: 0 };
			array_push(_mods, _m);
			_cost += _m.cost;
		}
		
		array_push(_effects, {element: _el, mods: _mods, effect_multiplier: 1, duration: 1});
	}
	
	if (!is_instanceof(_f, Form_Beam)) _caster.mana = max(0, _caster.mana - _cost);
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
