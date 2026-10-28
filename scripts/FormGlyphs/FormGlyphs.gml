/**
	This file contains the interfaces for each glyphs and their implementation
	Some are unfinished...
*/

#macro PROJECTILE_COST	5
#macro PROJECTILE_SPD	15
#macro STRIKE_COST		15
#macro BEAM_COST		5
#macro RUNE_COST		15

#macro BASE_DAMAGE 100

function FormGlyph(_name, _cost) constructor {
	name = _name;
	cost = _cost;
	is_channel = false;
	uses_mask = false;
	sprite = undefined;
	icon = undefined;
	desc = "";
	on_cast = function(spell) {};
	on_step = function(spell) {};
	on_hit = function(spell, target) {};
	on_draw = function(spell) {
		if (sprite != undefined) {
			var _size_modifier = 0;
			if (spell.area) _size_modifier = 0.25;
			else _size_modifier = 0;
			draw_sprite_ext(sprite, 0, spell.x, spell.y, 1, 0.5 + _size_modifier, spell.dir, spell.col, 1); 
		}
	}
}

function Form_Projectile() : FormGlyph("Projectile", PROJECTILE_COST) constructor {
	icon = spr_glyph_projectile;
	sprite = spr_projectile;
	uses_mask = true;
	cost = tune_params("forms", "projectile", "cost", PROJECTILE_COST);
	on_cast = function(spell) {
		spell.spd = tune_params("forms", "projectile", "spd", PROJECTILE_SPD);
		// Animation belongs to each cast, since the form is shared by spells.
		spell.projectile_state = "start";
		spell.projectile_sprite = spr_projectile_start;
		spell.projectile_frame = 0;
		spell.lifetime = TARGET_ROOM_SPEED * 5;
		var _lane = spell.target_row div ROWS_PER_LANE;
		spell.x = GRID_X0;
		spell.y = global.lane_top[_lane];
		spell.dir = 0;
	};
	on_hit = function(spell, target) {
		// Overlap events repeat each frame, including for enemies hit by an earlier blast.
		// Only a new, targetable contact consumes one penetration.
		if (!instance_exists(target) || !target.is_targetable) return;
		if (spell_contacted(spell, target)) return;
		if (spell.projectile_state == "end") return;
		var _col = floor((target.x - GRID_X0) / TILE_W);
		if (!spell_deliver(spell, target, _col, enemy_lane(target), spell.area ? 1 : 0)) return;
		if (spell.pierce-- <= 0) {
			spell.projectile_state = "end";
			spell.projectile_sprite = spr_projectile_end;
			spell.projectile_frame = 0;
			spell.spd = 0;
			// Let the complete impact animation outlive the flight timer.
			spell.lifetime = -1;
		}
	}
	on_step = function(spell) { 
		var _sprite = spell.projectile_sprite;
		var _rate = sprite_get_speed(_sprite);
		if (sprite_get_speed_type(_sprite) == spritespeed_framespersecond) {
			_rate /= game_get_speed(gamespeed_fps);
		}
		spell.projectile_frame += _rate;
		var _frames = sprite_get_number(_sprite);
		if (spell.projectile_frame >= _frames) {
			switch (spell.projectile_state) {
				case "start":
					spell.projectile_state = "mid";
					spell.projectile_sprite = spr_projectile_mid;
					spell.projectile_frame = 0;
					break;
				case "mid":
					spell.projectile_frame = spell.projectile_frame mod _frames;
					break;
				case "end":
					instance_destroy(spell);
					return;
			}
		}
		if (spell.projectile_state != "end") {
			spell.x += lengthdir_x(spell.spd, spell.dir);
			spell.y += lengthdir_y(spell.spd, spell.dir);
		}
	};
	on_draw = function(spell) {
		var _yscale = spell.area ? 2.0 : 1.5;
		draw_sprite_ext(spell.projectile_sprite, floor(spell.projectile_frame),
			spell.x, spell.y, 2.0, 1.5, spell.dir, spell.col, 0.5);
	};
}

function Form_Beam() : FormGlyph("Beam", BEAM_COST) constructor {
	icon = spr_glyph_beam;
	sprite = spr_beam;
	cost = tune_params("forms", "beam", "cost", BEAM_COST);
	is_channel = true;
	on_cast = function(spell) {
		spell.spd = 0;
		spell.lifetime = TARGET_ROOM_SPEED * 3;
		var _lane = spell.target_row div ROWS_PER_LANE;
		spell.lane = _lane;
		spell.x = GRID_X0;
		spell.y = global.lane_top[_lane] + TILE_H;
		spell.dir = 0;
		spell.beam_len = 0;
		spell.beam_frame = 0;
		spell.tick = 0;
	}
	on_step = function(spell) {
		// Each channel loops independently at the sprite's configured speed.
		var _rate = sprite_get_speed(sprite);
		if (sprite_get_speed_type(sprite) == spritespeed_framespersecond) {
			_rate /= game_get_speed(gamespeed_fps);
		}
		spell.beam_frame = (spell.beam_frame + _rate) mod sprite_get_number(sprite);

		// Handles AOE Modifier
		var _first = spell.area ? spell.lane - 1 : spell.lane;
		var _last  = spell.area ? spell.lane + 1 : spell.lane;
		_first = max(_first, 0);
		_last  = min(_last, LANE_COUNT - 1);

		spell.tick += 1;
		if (floor(spell.tick * spell.compiled.beam_ticks_per_second / TARGET_ROOM_SPEED)
		> floor((spell.tick - 1) * spell.compiled.beam_ticks_per_second / TARGET_ROOM_SPEED)) {
			spell.hit_state.contacts = [];
			spell.hit_state.epoch += 1;
		}

		spell.beam_lanes = [];
		var _direct_targets = [];
		for (var l = _first; l <= _last; l++) { // iterate from 1st lane to last lane
			var _end = GRID_X0 + GRID_COLS * TILE_W; // End of Lane
			var _targets = [];
			for (var i = 0; i < instance_number(obj_enemy_parent); i++) {
				var _enemy = instance_find(obj_enemy_parent, i);
				if (!_enemy.is_targetable || enemy_lane(_enemy) != l) continue;
				if (_enemy.x < spell.x || _enemy.x > _end) continue;
				array_push(_targets, _enemy);
			}
			array_sort(_targets, function(_a, _b) { return _a.x - _b.x; });
			// Pierce adds targets after the first, independently for each affected lane.
			var _hit_count = min(array_length(_targets), 1 + max(0, floor(spell.pierce)));
			if (_hit_count > 0) _end = _targets[_hit_count - 1].x;
			var _len = max(0, _end - spell.x);
			array_push(spell.beam_lanes, { lane: l, len: _len });
			for (var i = 0; i < _hit_count; i++) {
				array_push(_direct_targets, _targets[i]);
			}
		}
		spell_chain_reserve_roots(spell, _direct_targets);
		for (var i = 0; i < array_length(_direct_targets); i++) {
			var _target = _direct_targets[i];
			if (instance_exists(_target)) spell_deliver(spell, _target, floor((_target.x - GRID_X0) / TILE_W), enemy_lane(_target));
		}
	};
	on_draw = function(spell) {
		for (var i = 0; i < array_length(spell.beam_lanes); i++) {
			var _b = spell.beam_lanes[i];
			draw_sprite_ext(sprite, floor(spell.beam_frame), spell.x, global.lane_top[_b.lane] + TILE_H,
				_b.len / sprite_get_width(sprite), 1, 0, spell.col, 0.5);
		}
	};
}

function Form_Strike() : FormGlyph("Strike", STRIKE_COST) constructor {
	icon = spr_glyph_strike;
	sprite = spr_strike
	cost = tune_params("forms", "strike", "cost", STRIKE_COST);
	on_cast = function(spell) {
		var _p = grid_to_world_center(spell.target_col, spell.target_row);
		spell.target_x = _p.x;
		spell.target_y = _p.y;
		spell.x = _p.x;
		spell.y = _p.y - 400;
		spell.spd = 400 / spell.compiled.strike_cast_frames;
		spell.strike_elapsed = 0;
		spell.dir = 270; // straight down
		spell.landed = false;
		// Lifetime is decremented before on_step; leave a frame for the impact.
		spell.lifetime = max(TARGET_ROOM_SPEED * 2, spell.compiled.strike_cast_frames + 1);
		spell.strike_state = "start";
		spell.strike_sprite = spr_strike_start;
		spell.strike_frame = 0;
	};
	on_step = function(spell) {
		var _sprite = spell.strike_sprite;
		var _rate = sprite_get_speed(_sprite);
		if (sprite_get_speed_type(_sprite) == spritespeed_framespersecond) {
			_rate /= game_get_speed(gamespeed_fps);
		}
		spell.strike_frame += _rate;
		var _frames = sprite_get_number(_sprite);
		if (spell.strike_frame >= _frames) {
			switch (spell.strike_state) {
				case "start":
					spell.strike_state = "mid";
					spell.strike_sprite = spr_strike_mid;
					spell.strike_frame = 0;
					break;
				case "mid":
					spell.strike_frame = spell.strike_frame mod _frames;
					break;
				case "end":
					instance_destroy(spell);
					return;
			}
		}

		if (spell.landed) exit;
		spell.strike_elapsed++;
		spell.y = min(spell.y + spell.spd, spell.target_y);
		// Count frames explicitly to avoid a floating-point extra frame on arrival.
		if (spell.strike_elapsed >= spell.compiled.strike_cast_frames) {
			spell.y = spell.target_y;
			spell.landed = true;
			spell.lifetime = TARGET_ROOM_SPEED * 0.3; //Impact frames
			spell.strike_state = "end";
			spell.strike_sprite = spr_strike_end;
			spell.strike_frame = 0;
			
			var _c = spell.target_col;
			var _l = spell.target_row div ROWS_PER_LANE;
			spell_deliver(spell, noone, _c, _l, spell.area ? 1 : 0);
		}	
	};
	on_draw = function(spell) {
		var _size_multiplier = 1;
		if (spell.area) _size_multiplier = 3;
		if (!spell.landed) { // Draws target indicator
			var _x_offs = 40 * _size_multiplier; var _y_offs = 15 * _size_multiplier;
			draw_set_alpha(0.3);
			draw_ellipse(spell.target_x - _x_offs, spell.target_y - _y_offs, spell.target_x + _x_offs, spell.target_y + _y_offs, false);
			draw_set_alpha(1); draw_set_color(c_red);
		}
		var scale = 1 * _size_multiplier;
		draw_sprite_ext(spell.strike_sprite, floor(spell.strike_frame), spell.x, spell.y + 10, scale, scale, 0, spell.col, 1);
	};
}

function Form_Rune() : FormGlyph("Rune", RUNE_COST) constructor {
	icon = spr_glyph_rune;
	sprite = spr_vfx_rune_arming;
	cost = tune_params("forms", "rune", "cost", RUNE_COST);
	arming_time = 3 * TARGET_ROOM_SPEED;
	max_charges = 1;
	on_cast = function(spell) {
		var _p = grid_to_world_center(spell.target_col, spell.target_row);
		var _lane = spell.target_row div ROWS_PER_LANE;
		spell.lane = _lane;
		spell.x = GRID_X0 + spell.target_col * TILE_W + TILE_W / 2;
		spell.y = global.lane_top[_lane] + LANE_H / 2;
		spell.lifetime = TARGET_ROOM_SPEED * 120;
		spell.arm_timer = arming_time;
		spell.armed = false;
		spell.charges = max_charges
		spell.trigger_cd = 0;
		spell.image_xscale = 0.5
	};
	on_step = function(spell) {
		if (!spell.armed && --spell.arm_timer <= 0) {
			spell.armed = true;
			spell.mask_index = spr_vfx_rune_complete;
		}
	};
	on_hit = function(spell, target) {
		if (!spell.armed) return;
		if (enemy_lane(target) != spell.lane) return; //ignore sprites poking from neighbouring lanes
		var _c = spell.target_col;
		var _l = spell.lane;
		if (spell_deliver(spell, target, _c, _l, spell.area ? 1 : 0)) spell.charges--;
		if (spell.charges <= 0) instance_destroy(spell);
	};
	on_draw = function(spell) {
		var _sprite = spell.armed ? spr_vfx_rune_complete : spr_vfx_rune_arming;
		var _size_multiplier = 1;
		var scale = 0.5 * _size_multiplier;
		draw_sprite_ext(_sprite, 0, spell.x, spell.y, scale, scale, 0, spell.col, 1);
	};
}


