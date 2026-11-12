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
	delivery_kind = "target";
	on_cast = function(spell, fx) {};
	on_hit = function(spell, target, fx) {};
	on_impact = function(spell, fx, col, lane) {};
}

function Elem_Fire() : EffectGlyph("Fire", FIRE_COST) constructor {
	icon = spr_glyph_fire;
	col = c_red
	cost = tune_params("effects", "fire", "cost", FIRE_COST);
	desc = "Burns enemies, dealing damage over time. Breaks fire wards.";
	on_hit = function(spell, target, fx) {
		var _base_dmg = fx.params.base_damage;
		var _fire_dmg_mult = fx.params.fire_mult;
		var _duration = fx.params.duration;
		combat_status_apply(target, "burn", TARGET_ROOM_SPEED * (_duration + fx.duration), _base_dmg * _fire_dmg_mult * fx.effect_multiplier);
	};
}

function Elem_Ice() : EffectGlyph("Ice", FROST_COST) constructor {
	icon = spr_glyph_frost;
	col = c_teal;
	cost = tune_params("effects", "ice", "cost", FROST_COST);
	desc = "Applies Frost, slowing enemies more with each stack. Breaks frost wards."
	on_hit = function(spell, target, fx) {
		var _duration = fx.params.duration;
		var slow_amt = fx.params.slow_per_stack;
		combat_status_apply(target, "frost", TARGET_ROOM_SPEED * (_duration + fx.duration), slow_amt);
	};
}

function Elem_Lightning() : EffectGlyph("Lightning", LIGHTNING_COST) constructor {
	icon = spr_glyph_lightning;
	col = c_yellow;
	desc = "Briefly stuns enemies, then leaves them Charged. Breaks lightning wards. Enemies can’t be stunned again until their Charge fades.";
	cost = tune_params("effects", "lightning", "cost", LIGHTNING_COST);
	on_hit = function(spell, target, fx) {
		var _duration = fx.params.duration;
		combat_status_apply(target, "lightning", TARGET_ROOM_SPEED * (_duration + fx.duration));
	};
}

function Elem_Hex() : EffectGlyph("Hex", HEX_COST) constructor {
	icon = spr_glyph_hex;
	col = c_fuchsia;
	desc = "Curses enemies, making them take 10% more damage for each active status.";
	cost = tune_params("effects", "hex", "cost", HEX_COST);
	on_hit = function(spell, target, fx) {
		var _duration = fx.params.duration;
		combat_status_apply(target, "hex", TARGET_ROOM_SPEED * (_duration + fx.duration));
	};
}

function Elem_Harm() : EffectGlyph("Harm", HARM_COST) constructor {
	icon = spr_glyph_harm;
	col = c_purple;
	desc = "Deals damage on hit.";
	cost = tune_params("effects", "harm", "cost", HARM_COST);
	on_hit = function(spell, target, fx) {
		var _dmg = fx.params.base_damage * fx.effect_multiplier;
		if (spell.form.is_channel) {
			_dmg *= spell.compiled.beam_damage_multiplier_per_tick;
		}
		var pos = enemy_get_leftpoint(target, spr_harm, "center", 0.5);
		combat_spawn_vfx(spr_harm, target.x, target.y, 0.5, 0.5);
		spell_direct_damage(spell, target, _dmg);
	}
}

function Elem_Pull() : EffectGlyph("Pull", PULL_COST) constructor {
	icon = spr_glyph_pull;
	col = c_ltgray;
	allowed_forms = ["projectile", "strike", "rune"];
	delivery_kind = "location";
	desc = "Pulls enemies in a 3x3 area around the point of impact.";
	
	on_impact = function(spell, fx, col, lane) {
		var _tx = GRID_X0 + col * TILE_W + TILE_W / 2;
        var _ty = global.lane_top[lane] + LANE_H / 2;          // the enemy path
        var _list = enemies_in_region_list(col - 1, col + 1, lane - 1, lane + 1);
		
		combat_spawn_vfx(spr_pull, _tx, _ty, 5, 5);
		
		for (var i = 0; i < array_length(_list); i++) {
			if (!enemy_can_receive_spell(_list[i], spell.compiled)) continue;
            // small random offset so pulled enemies don't stack on one pixel
            var _a = random(360), _r = random(28);
			
            enemy_begin_pull(_list[i], _tx + lengthdir_x(_r, _a), _ty + lengthdir_y(_r, _a),
                             lane, round(fx.params.pull_sec * TARGET_ROOM_SPEED),
                             round(fx.params.hold_sec * TARGET_ROOM_SPEED));
        }
	} 
}

function Elem_None() : EffectGlyph("none", 0) constructor {
}

function Elem_Combust() : EffectGlyph("Combust", 15) constructor {
	icon = spr_glyph_combust;
	col = c_orange;
	cost = tune_params("effects", "combust", "cost", 15);
	desc = "Deals damage to burning enemies. A direct kill with the spell causes an explosion and spreads Burn.";
	on_hit = function(spell, target, fx) {
		if (!combat_status_active(target, "burn")) return;
		spell_direct_damage(spell, target, fx.params.base_damage * fx.params.damage_mult * fx.effect_multiplier * spell_damage_scale(spell));
	};
}

function Elem_Discharge() : EffectGlyph("Discharge", 20) constructor {
	icon = spr_glyph_discharge;
	col = c_yellow;
	cost = tune_params("effects", "discharge", "cost", 20);
	desc = "Consumes Charged to deal damage nearby enemies. Other Charged enemies caught in the burst also discharge.";
	on_hit = function(spell, target, fx) {
		spell_discharge(spell, target, fx);
	};
}

function Elem_Snap() : EffectGlyph("Snap", 15) constructor {
	icon = spr_glyph_snap;
	col = c_teal;
	cost = tune_params("effects", "snap", "cost", 15);
	effect_sprites = [spr_snap_1, spr_snap_2, spr_snap_3];
	desc = "Removes all frost stacks from an enemy, dealing heavy damage for each Frost stack.";
	on_hit = function(spell, target, fx) {
		var _stacks = combat_status_frost_stacks(target);
		if (_stacks <= 0) return;
		var _sprite = fx.effect.effect_sprites[_stacks - 1];
		var _damage = fx.params.base_damage * fx.params.damage_per_stack_mult * _stacks * fx.effect_multiplier * spell_damage_scale(spell);
		var pos = enemy_get_leftpoint(target, _sprite, "center", 0);
		// The helper anchors the artwork's left edge; center Snap on the victim.
		pos.x -= (sprite_get_bbox_right(_sprite) - sprite_get_bbox_left(_sprite)) * pos.scale / 2;
		combat_spawn_vfx(_sprite, pos.x, pos.y, pos.scale, pos.scale);
		combat_status_clear(target, "frost");
		spell_direct_damage(spell, target, _damage);
		
		enemy_update_movement(target);
	};
}

function Elem_Force() : EffectGlyph("Force", 10) constructor {
	icon = spr_glyph_force;
	col = c_silver;
	allowed_forms = ["projectile", "strike", "rune"];
	cost = tune_params("effects", "force", "cost", 10);
	desc = "Pushes back enemies by 1 tile";
	on_hit = function(spell, target, fx) {
	    if (!enemy_can_be_displaced(target)) return;
	    if (target.pull != undefined) return;
	    if (target.force_push != undefined) return;

	    var _path = target.path_index;
	    if (_path < 0) return;

	    var _length = path_get_length(_path);
	    if (_length <= 0) return;
		var _push_mult = tune_params("effects", "force", "push_mult", 1);
		var _duration = tune_params("effects", "force", "duration", 0.1);

	    var _distance = TILE_W * _push_mult * fx.effect_multiplier;
		
		var pos = enemy_get_leftpoint(target, spr_force, "center", 1.3)
		combat_spawn_vfx(spr_force, pos.x, pos.y, 1.3, 1.3);
	    target.force_push = {
	        start: target.path_position,
	        finish: max(0, target.path_position - _distance / _length),
	        elapsed: 0,
	        duration: max(1, round(_duration * TARGET_ROOM_SPEED))
	    };

	    target.path_speed = 0;
	};
}

function Elem_Earth() : EffectGlyph("Earth", 20) constructor {
	icon = spr_glyph_earth;
	col = #331C00;
	delivery_kind = "location";
	allowed_forms = ["projectile", "strike", "rune"];
	cost = tune_params("effects", "earth", "cost", 20);
	desc = "Create a temporary barrier of earth to impede enemies";
	on_impact = function(spell, fx, col, lane) {
		if (spell.compiled.form_id == "projectile") col -= 1;
		col = clamp(col, 0, GRID_COLS - 1);
		if (lane < 0 || lane >= LANE_COUNT) return;
		var _xy = grid_to_world_center(col, lane * ROWS_PER_LANE);
		var _hp = tune_params("effects", "earth", "hp", 20);
		var _duration = tune_params("effects", "earth", "duration", 20);
		instance_create_layer(_xy.x, _xy.y, "Instances", obj_rock, {
			hp: _hp,
			lifetime: _duration * TARGET_ROOM_SPEED,
			image_xscale: 0.75,
			image_yscale: 1
		})
	}
}
