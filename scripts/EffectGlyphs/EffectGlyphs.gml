#macro HARM_COST			10
#macro FIRE_COST			10
#macro FIRE_MULT			0.4
#macro FIRE_DURATION		3
#macro LIGHTNING_COST		10
#macro LIGHTNING_DURATION	1
#macro FROST_COST			10
#macro FROST_SLOW			0.2
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
	cost = tune_params("effects", "fire", "cost", FIRE_COST);
	on_hit = function(spell, target, fx) {
		var _base_dmg = tune_value("combat", "base_dmg", BASE_DAMAGE);
		var _fire_dmg_mult = tune_params("effects", "fire", "fire_dmg_mult", FIRE_MULT);
		var _duration = tune_params("effects", "fire", "duration", FIRE_DURATION);
		target.burn_dmg = _base_dmg * _fire_dmg_mult * fx.effect_multiplier;
		target.burn_timer = TARGET_ROOM_SPEED * (_duration + fx.duration);
	};
}

function Elem_Ice() : EffectGlyph("Ice", FROST_COST) constructor {
	icon = spr_glyph_frost;
	col = c_teal;
	cost = tune_params("effects", "ice", "cost", FROST_COST);
	on_hit = function(spell, target, fx) {
		var _duration = tune_params("effects", "ice", "duration", FROST_DURATION);
		target.slow_amt += tune_params("effects", "ice", "slow_amt_per_stack", FROST_SLOW);
		// Hypothetically, older frost stacks also will inherit extend time
		target.slow_timer = TARGET_ROOM_SPEED * (_duration + fx.duration); 
	};
}

function Elem_Lightning() : EffectGlyph("Lightning", LIGHTNING_COST) constructor {
	icon = spr_glyph_lightning;
	col = c_yellow;
	cost = tune_params("effects", "lightning", "cost", LIGHTNING_COST);
	on_hit = function(spell, target, fx) {
		var _duration = tune_params("effects", "lightning", "duration", LIGHTNING_DURATION);
		if (target.stun_immune_timer <= 0 && target.stun_timer > 0)
			target.stun_timer = TARGET_ROOM_SPEED * (_duration + fx.duration);
	};
}

function Elem_Harm() : EffectGlyph("Harm", HARM_COST) constructor {
	icon = spr_glyph_harm;
	col = c_purple;
	cost = tune_params("effects", "harm", "cost", HARM_COST);
	on_hit = function(spell, target, fx) {
		var _dmg = tune_value("combat", "base_dmg", BASE_DAMAGE) * fx.effect_multiplier;
		if (spell.form.is_channel) {
			var _tmp = _dmg;
			_dmg = _tmp / 4; // Enemies are hit 4 times every second see Form_Beam for details
		}
		deal_damage(target, _dmg);
	}
}

function Elem_None() : EffectGlyph("none", 0) constructor {
}
