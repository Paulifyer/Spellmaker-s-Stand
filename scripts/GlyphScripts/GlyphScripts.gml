/**
	This file contains the interfaces for each glyphs and their implementation
	Some are unfinished...
*/

#macro FORM_MANA_COST 20
#macro ELEM_MANA_COST 10
#macro MODI_MANA_COST 20

#macro BASE_DAMAGE 100

function FormGlyph(_name, _cost) constructor {
	name = _name;
	cost = _cost;
	is_channel = false;
	drain_per_sec = 0;
	sprite = undefined;
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

function ElementGlyph(_name, _cost) constructor {
	name = _name; cost = _cost;
	on_cast = function(spell) {};
	on_hit = function(spell, target) {};
}

function ModifierGlyph(_name, _cost) constructor {
	name = _name; cost = _cost;
	on_cast = function(spell) {};
	on_hit = undefined;
}

function spell_hit(spell, target) { // For non collision based 
	if (array_contains(spell.hit_list, target)) return;
	array_push(spell.hit_list, target);
	spell.form.on_hit(spell, target);
	spell.element.on_hit(spell, target); 
	if (spell.modifier.on_hit != undefined) spell.modifier.on_hit(spell, target); 
}

function Form_Projectile() : FormGlyph("Projectile", FORM_MANA_COST) constructor {
	sprite = spr_projectile;
	on_cast = function(spell) {
		spell.spd = 15; 
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
	on_hit = function(spell, target) {
		deal_damage(target, BASE_DAMAGE * spell.dmg_multiplier);
	}
}

function Form_Beam() : FormGlyph("Beam", FORM_MANA_COST) constructor {
	sprite = spr_beam;
	is_channel = true;
	drain_per_sec = 5;
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
		var _first = spell.area ? spell.lane - 1 : spell.lane;
		var _last  = spell.area ? spell.lane + 1 : spell.lane;
		_first = max(_first, 0);
		_last  = min(_last, LANE_COUNT - 1);

		if (++spell.tick mod (TARGET_ROOM_SPEED * 0.25) == 0) spell.hit_list = [];

		spell.beam_lanes = [];
		for (var l = _first; l <= _last; l++) {
			var _top = global.lane_top[l] + 20;
			var _end = GRID_X0 + GRID_COLS * TILE_W;

			if (spell.pierce <= 0) {
				with (obj_enemy_parent) {
					if (y >= _top && y < _top + LANE_H && x < _end) _end = x;
				}
			}
			var _len = max(0, _end - spell.x);
			array_push(spell.beam_lanes, { lane: l, len: _len });

			var _list = ds_list_create();
			collision_rectangle_list(spell.x, _top, spell.x + _len, _top + LANE_H - 20,
				                     obj_enemy_parent, false, true, _list, false);
			for (var i = 0; i < ds_list_size(_list); i++) spell_hit(spell, _list[| i]);
			ds_list_destroy(_list);
		}
	};
	on_hit = function(spell, target) {
		deal_damage(target, BASE_DAMAGE * 0.1 * spell.dmg_multiplier);
	}
	on_draw = function(spell) {
		for (var i = 0; i < array_length(spell.beam_lanes); i++) {
			var _b = spell.beam_lanes[i];
			draw_sprite_ext(sprite, 0, spell.x, global.lane_top[_b.lane] + TILE_H,
				_b.len / sprite_get_width(sprite), 0.5, 0, spell.col, 1);
    }
	}
}

function Form_Strike() : FormGlyph("Strike", FORM_MANA_COST) constructor {
	sprite = spr_strike
	on_cast = function(spell) {
		var _p = grid_to_world_center(spell.target_col, spell.target_row);
		spell.target_x = _p.x;
		spell.target_y = _p.y;
		spell.x = _p.x;
		spell.y = _p.y - 400;
		spell.spd = 14;
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
		else _size_multiplier = 1;
		if (!spell.landed) { // Draws target indicator
			var _x_offs = 40 * _size_multiplier; var _y_offs = 15 * _size_multiplier;
			draw_set_alpha(0.3);
			draw_ellipse(spell.target_x - _x_offs, spell.target_y - _y_offs, spell.target_x + _x_offs, spell.target_y + _y_offs, false);
			draw_set_alpha(1); draw_set_color(c_red);
		}
		var scale = 0.5 * _size_multiplier;
		draw_sprite_ext(sprite, 0, spell.x, spell.y, scale, scale, 0, spell.col, 1);
	};
	on_hit = function(spell, target) {
		deal_damage(target, 0.35 * BASE_DAMAGE * spell.dmg_multiplier);
	}
}

function Elem_Fire() : ElementGlyph("Fire", ELEM_MANA_COST) constructor {
	on_cast = function(spell) {
		spell.col = c_red
	}
	on_hit = function(spell, target) {
		target.burn_dmg = 20 * spell.dmg_multiplier;
		target.burn_timer = TARGET_ROOM_SPEED * 3  * spell.elem_multiplier;
	};
}

function Elem_Ice() : ElementGlyph("Ice", ELEM_MANA_COST) constructor {
	on_cast = function(spell) {
		spell.col = c_teal
	};
	on_hit = function(spell, target) {
		target.slow_amt = 0.4 * spell.elem_multiplier;
		target.slow_timer = TARGET_ROOM_SPEED * 3  * spell.elem_multiplier;
	}
}

function Elem_Lightning() : ElementGlyph("Lightning", ELEM_MANA_COST) constructor {
	on_cast = function(spell) {
		spell.col = c_yellow
	};
	on_hit = function(spell, target) {
		target.stun_timer = TARGET_ROOM_SPEED * spell.elem_multiplier;
	}
}

function Elem_None() : ElementGlyph("none", 0) constructor {
}

function Mod_Area() : ModifierGlyph("Area", MODI_MANA_COST) constructor {
	on_cast = function(spell) {
		spell.area = true;
	}
	on_hit = function(spell, target) {};
}

function Mod_Amplify() : ModifierGlyph("Amplify", MODI_MANA_COST) constructor {
	on_cast = function(spell) {
		spell.dmg_multiplier = 3;
		spell.elem_multiplier = 2;
	}
}

function Mod_Pierce() : ModifierGlyph("Pierce", MODI_MANA_COST) constructor {
	on_cast = function(spell) {
		spell.pierce = 50; // Probably should be a boolean based on how pierce works
	}
	on_hit = function(spell, target) {}
}

function Mod_None() : ElementGlyph("none", 0) constructor {
}
