//obj_spell Create

spd = 4; dmg = 1; lifetime = 60; pierce = compiled.pierce; dir = 0;
col = c_white
landed = false;
lane = 0;
target_x = 0; target_y = 0;
area = compiled.area;
hit_state = {contacts: [], applications: {}, epoch: 0};
delivery_index = 0;
beam_lanes = [];

// form/effects/compiled are supplied before Create by cast_spell().
form.on_cast(self);
for (var e = 0; e < array_length(effects); e++) {
	var _fx = effects[e];
	_fx.effect.on_cast(self, _fx);
}

// Delays are cumulative boundaries: Harm + Delay, Fire + Delay, Harm
// activates at 0, 1, and 2 seconds (with the default one-second Delay).
// Modifier values and cumulative delays are already resolved by compile_spell().

col = spell_effect_colour(effects);

// This checks if the form glyph handles effects through collisions or steps
if (form.uses_mask && form.sprite != undefined) { 
	mask_index = form.sprite;
	image_yscale = 0.5;
	image_angle = dir;
	
}
