//obj_spell Create

spd = 4; dmg = 1; lifetime = 60; pierce = 0; dir = 0;
dmg_multiplier = 1; elem_multiplier = 1;
col = c_white
landed = false;
lane = 0;
target_x = 0; target_y = 0;
area = false; // If area glyph is used
hit_list = [];
beam_lanes = [];

// This stores the form of the spell
//form = undefined;

// This stores the modifiers for the form alone
//form_mods = [];

// This stores the struct and modifiers for the effects {effect, mods[], power, duration}
//effects = [];

show_debug_message(variable_struct_get_names(form))

form.on_cast(self);
for (var i = 0; i < array_length(form_mods); i++) form_mods[i].on_cast(self, undefined);
for (var e = 0; e < array_length(effects); e++) {
	var _fx = effects[e];
	_fx.element.on_cast(self, _fx);
	for (var i = 0; i < array_length(_fx.mods); i++) _fx.mods[i].on_cast(self, _fx);
}

col = (array_length(effects) > 0) ? effects[0].element.col : c_white;

if (form.uses_mask && form.sprite != undefined) {
	mask_index = form.sprite;
	image_yscale = 0.5;
	image_angle = dir;
}
