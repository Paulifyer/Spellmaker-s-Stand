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

function spell_hit_area(_spell, _col1, _col2, _lane1, _lane2) {
	_col1 = max(_col1, 0); _col2 = min(_col2, GRID_COLS - 1);
	_lane1 = max(_lane1, 0); _lane2 = min(_lane2, LANE_COUNT - 1);
	var _x1 = GRID_X0 + _col1 * TILE_W;
    var _x2 = GRID_X0 + (_col2 + 1) * TILE_W;
    var _y1 = global.lane_top[_lane1];
    var _y2 = global.lane_top[_lane2] + LANE_H;
	
	var _list = ds_list_create();
    collision_rectangle_list(_x1, _y1, _x2, _y2, obj_enemy_parent, false, true, _list, false);
    for (var i = 0; i < ds_list_size(_list); i++) spell_hit(_spell, _list[| i]);
    ds_list_destroy(_list);
}

function cast_spell(_caster, _loadout, _col, _row) {
	var _f = global.spell_glyphs.form[$ _loadout.form];
	var _e = global.spell_glyphs.element[$ (_loadout.element ?? "none") ];
	var _m = global.spell_glyphs.modifier[$ (_loadout.modifier ?? "none")];
	
	if (!is_struct(_f) || !is_struct(_e) || !is_struct(_m)) return noone;
	var _cost = _f.cost + _e.cost + _m.cost;
	if (_caster.mana < _cost) return noone;
	_caster.mana -= _cost;
	
	return instance_create_layer(_caster.x, _caster.y, "Instances", obj_spells, {
		caster		: _caster,
		form		: _f,
		element		: _e,
		modifier	: _m,
		target_col	: _col,
		target_row	: _row
	});
}