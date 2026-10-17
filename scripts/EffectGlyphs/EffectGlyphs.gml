#macro HARM_COST			10
#macro FIRE_COST			10
#macro FIRE_DURATION		3
#macro LIGHTNING_COST		10
#macro LIGHTNING_DURATION	1
#macro FROST_COST			10
#macro FROST_DURATION		3

function EffectGlyph(_name, _cost) constructor {
	name = _name; cost = _cost;
	icon = undefined;
	col = c_white
	desc = "";
	on_cast = function(spell, fx) {};
	on_hit = function(spell, target, fx) {};
}

function Elem_Fire() : EffectGlyph("Fire", FIRE_COST) constructor {
	icon = spr_glyph_fire;
	col = c_red
	on_hit = function(spell, target, fx) {
		target.burn_dmg = 20 * fx.effect_multiplier;
		target.burn_timer = TARGET_ROOM_SPEED * (FIRE_DURATION + fx.duration);
	};
}

function Elem_Ice() : EffectGlyph("Ice", FROST_COST) constructor {
	icon = spr_glyph_frost;
	col = c_teal;
	on_hit = function(spell, target, fx) {
		target.slow_amt += (0.2);
		// Hypothetically, frost stacks also will inherit extend time
		target.slow_timer = TARGET_ROOM_SPEED * (FROST_DURATION + fx.duration); 
	};
}

function Elem_Lightning() : EffectGlyph("Lightning", LIGHTNING_COST) constructor {
	icon = spr_glyph_pierce;
	col = c_yellow;
	on_hit = function(spell, target, fx) {
		target.stun_timer = TARGET_ROOM_SPEED * (LIGHTNING_DURATION + fx.duration);
	};
}

function Elem_Harm() : EffectGlyph("Harm", HARM_COST) constructor {
	icon = spr_glyph_harm;
	col = c_purple;
	on_hit = function(spell, target, fx) {
		var _dmg = BASE_DAMAGE * fx.effect_multiplier;
		if (spell.form.is_channel) {
			_dmg /= TARGET_ROOM_SPEED;
		}
		deal_damage(target, _dmg);
	}
}

function Elem_None() : EffectGlyph("none", 0) constructor {
}
