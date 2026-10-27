#macro HARM_COST			10
#macro FIRE_COST			10
#macro FIRE_MULT			0.4
#macro FIRE_DURATION		3
#macro LIGHTNING_COST		10
#macro LIGHTNING_DURATION	1
#macro FROST_COST			10
#macro FROST_SLOW			0.2
#macro FROST_DURATION		3
#macro PULL_COST			25
#macro HEX_COST 20
#macro HEX_DURATION 5
#macro HEX_DAMAGE_PER_STATUS 0.1

function EffectGlyph(_name, _cost) constructor {
	name = _name; cost = _cost;
	icon = undefined;
	col = c_white
	desc = "";
	allowed_forms = undefined;
	on_cast = function(spell, fx) {};
	on_hit = function(spell, target, fx) {};
	on_impact = function(spell, fx, col, lane) {};
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
		var slow_amt = tune_params("effects", "ice", "slow_amt_per_stack", FROST_SLOW);
		target.slow_amt = clamp(target.slow_amt + slow_amt, 0, 0.6); // Cap total slow at 60% (three default stacks).
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
		if (target.stun_immune_timer <= 0 && target.stun_timer <= 0)
			target.stun_timer = TARGET_ROOM_SPEED * (_duration + fx.duration);
	};
}

function Elem_Hex() : EffectGlyph("Hex", HEX_COST) constructor {
	icon = spr_glyph_hex;
	col = c_fuchsia;
	desc = "Increases damage taken by 10% per active status, including Hex.";
	cost = tune_params("effects", "hex", "cost", HEX_COST);
	on_hit = function(spell, target, fx) {
		var _duration = tune_params("effects", "hex", "duration", HEX_DURATION);
		target.hex_timer = TARGET_ROOM_SPEED * (_duration + fx.duration);
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

function Elem_Pull() : EffectGlyph("Pull", PULL_COST) constructor {
	icon = spr_glyph_pull;
	col = c_ltgray;
	allowed_forms = ["projectile", "strike", "rune"];
	desc = "Pulls enemies in a 3x3 area. Form AoE does not enlarge Pull.";
	pull_sec = tune_params("effects", "pull", "pull_sec", 0.4); // travel time
	hold_sec = tune_params("effects", "pull", "hold_sec", 1.0); // time held
	
	on_impact = function(spell, fx, col, lane) {
		show_debug_message(lane);
		var _tx = GRID_X0 + col * TILE_W + TILE_W / 2;
        var _ty = global.lane_top[lane] + LANE_H / 2;          // the enemy path
        var _list = enemies_in_region_list(col - 1, col + 1, lane - 1, lane + 1);
		
		 for (var i = 0; i < array_length(_list); i++) {
            // small random offset so pulled enemies don't stack on one pixel
            var _a = random(360), _r = random(28);
            enemy_begin_pull(_list[i], _tx + lengthdir_x(_r, _a), _ty + lengthdir_y(_r, _a),
                             lane, round(pull_sec * TARGET_ROOM_SPEED),
                             round(hold_sec * TARGET_ROOM_SPEED * fx.duration));
        }
	} 
}

function Elem_None() : EffectGlyph("none", 0) constructor {
}
