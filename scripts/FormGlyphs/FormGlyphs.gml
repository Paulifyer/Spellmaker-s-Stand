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
		spell.lifetime = TARGET_ROOM_SPEED * 5;
		var _lane = spell.target_row div ROWS_PER_LANE;
		spell.x = GRID_X0;
		spell.y = global.lane_top[_lane];
		spell.dir = 0;		
	};
	on_step = function(spell) { 
		spell.x += lengthdir_x(spell.spd, spell.dir);
		spell.y += lengthdir_y(spell.spd, spell.dir);
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
		spell.tick = 0;
	}
	on_step = function(spell) {
		// Handles AOE Modifier
		var _first = spell.area ? spell.lane - 1 : spell.lane;
		var _last  = spell.area ? spell.lane + 1 : spell.lane;
		_first = max(_first, 0);
		_last  = min(_last, LANE_COUNT - 1);

		if (++spell.tick mod (TARGET_ROOM_SPEED * 0.25) == 0) spell.hit_list = [];

		spell.beam_lanes = [];
		for (var l = _first; l <= _last; l++) { // iterate from 1st lane to last lane
			var _top = global.lane_top[l] + 20; // Middle-ish of lane
			var _end = GRID_X0 + GRID_COLS * TILE_W; // End of Lane
			var _pierce = spell.pierce;
			if (_pierce <= 0) {
				with (obj_enemy_parent) {
					if (y >= _top && y < _top + LANE_H && x < _end) _end = x;
				}
			}
			var _len = max(0, _end - spell.x);
			array_push(spell.beam_lanes, { lane: l, len: _len });
			with (obj_enemy_parent) {
				if (enemy_lane(id) == l && x >= spell.x && x <= _end) spell_hit(spell, id);
			}
		}
	};
	on_draw = function(spell) {
		for (var i = 0; i < array_length(spell.beam_lanes); i++) {
			var _b = spell.beam_lanes[i];
			draw_sprite_ext(sprite, 0, spell.x, global.lane_top[_b.lane] + TILE_H,
				_b.len / sprite_get_width(sprite), 0.5, 0, spell.col, 1);
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
		spell.spd = 30;
		spell.dir = 270; // straight down
		spell.landed = false;
		spell.lifetime = TARGET_ROOM_SPEED * 2;
	};
	on_step = function(spell) {
		if (spell.landed) exit;
		spell.y = min(spell.y + spell.spd, spell.target_y);
		if (spell.y >= spell.target_y) {
			spell.landed = true;
			spell.lifetime = TARGET_ROOM_SPEED * 0.3; //Impact frames
			
			var _c = spell.target_col;
			var _l = spell.target_row div ROWS_PER_LANE;
			if (spell.area) spell_hit_area(spell, _c -1, _c + 1, _l -1, _l + 1); // Handles AOE vs non-AOE
			else			spell_hit_area(spell, _c, _c, _l, _l);
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
		var scale = 0.5 * _size_multiplier;
		draw_sprite_ext(sprite, 0, spell.x, spell.y, scale, scale, 0, spell.col, 1);
	};
}

function Form_Rune() : FormGlyph("Rune", RUNE_COST) constructor {
	icon = spr_glyph_rune;
	sprite = spr_vfx_rune_complete;
	cost = tune_params("forms", "rune", "cost", RUNE_COST);
	on_cast = function(spell) {
		var _p = grid_to_world_center(spell.target_col, spell.target_row);
		spell.target_x = _p.x;
		spell.target_y = _p.y;
		spell.x = _p.x;
		spell.y = _p.y - 400;
		spell.spd = 0;
		spell.dir = 270; // straight down
		spell.lifetime = TARGET_ROOM_SPEED * 60;
	};
	on_hit = function(spell) {
		spell.y = min(spell.y + spell.spd, spell.target_y);
		if (spell.y >= spell.target_y) {
			spell.landed = true;
			spell.lifetime = TARGET_ROOM_SPEED * 0.3; //Impact frames
			
			var _c = spell.target_col;
			var _l = spell.target_row div ROWS_PER_LANE;
			if (spell.area) spell_hit_area(spell, _c -1, _c + 1, _l -1, _l + 1); // Handles AOE vs non-AOE
			else			spell_hit_area(spell, _c, _c, _l, _l);
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
		var scale = 0.5 * _size_multiplier;
		draw_sprite_ext(sprite, 0, spell.x, spell.y, scale, scale, 0, spell.col, 1);
	};
}


