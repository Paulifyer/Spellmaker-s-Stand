
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
		none : new Elem_None()
	},
	modifier : {
		area : new Mod_Area(),
		amplify : new Mod_Amplify(),
		pierce : new Mod_Pierce(),
		none : new Mod_None()
	}
};

global.slot_order = ["form", "element", "modifier"];

global.glyph_order = {
	form	:	["projectile", "beam", "strike"],
	element	:	["fire", "ice", "lightning"],
	modifier:	["area", "amplify", "pierce"]
};



function spell_cost(_l) {
	if (_l == undefined || _l.form == undefined) return 0;
	var _f_cost; var _e_cost; var _m_cost;
	return global.spell_glyphs.form[$ _l.form].cost
         + global.spell_glyphs.element[$ (_l.element ?? "none")].cost
         + global.spell_glyphs.modifier[$ (_l.modifier ?? "none")].cost;
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
	if (_caster.mana_exhausted) return noone;

	var _f = global.spell_glyphs.form[$ _loadout.form];
	var _e = global.spell_glyphs.element[$ (_loadout.element ?? "none") ];
	var _m = global.spell_glyphs.modifier[$ (_loadout.modifier ?? "none")];
	
	if (!is_struct(_f) || !is_struct(_e) || !is_struct(_m)) return noone;
	var _cost = _f.cost + _e.cost + _m.cost;
	if (!is_instanceof(_f, Form_Beam)) _caster.mana = max(0, _caster.mana - _cost);
	if (_caster.mana <= 0) {
		_caster.mana = 0;
		_caster.mana_exhausted = true;
	}
	
	return instance_create_layer(_caster.x, _caster.y, "Instances", obj_spells, {
		caster		: _caster,
		form		: _f,
		element		: _e,
		modifier	: _m,
		target_col	: _col,
		target_row	: _row
	});
}
