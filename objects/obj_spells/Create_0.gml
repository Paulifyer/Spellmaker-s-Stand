//obj_spell Create

spd = 4; dmg = 1; lifetime = 60; pierce = compiled.pierce; dir = 0;
col = c_white
landed = false;
lane = 0;
target_x = 0; target_y = 0;
area = compiled.area;
hit_list = [];
delivery_index = 0;
beam_lanes = [];

// This stores the form of the spell
//form = undefined;

// This stores the modifiers for the form alone
//form_mods = [];

// This stores the struct and modifiers for the effects {effect, mods[], power, duration}
//effects = [];


form.on_cast(self);
for (var e = 0; e < array_length(effects); e++) {
	var _fx = effects[e];
	_fx.effect.on_cast(self, _fx);
}

// Delays are cumulative boundaries: Harm + Delay, Fire + Delay, Harm
// activates at 0, 1, and 2 seconds (with the default one-second Delay).
// Modifier values and cumulative delays are already resolved by compile_spell().

col = c_white;
if (array_length(effects) > 0) {
	col = effects[0].effect.col;
	for (var i = 1; i < array_length(effects); i++) {
		col = merge_colour(col, effects[i].effect.col, 0.5);		
	}	
}

// This checks if the form glyph handles effects through collisions or steps
if (form.uses_mask && form.sprite != undefined) { 
	mask_index = form.sprite;
	image_yscale = 0.5;
	image_angle = dir;
	
}
