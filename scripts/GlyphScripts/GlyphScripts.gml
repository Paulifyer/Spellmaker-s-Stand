/**
	This file contains the interfaces for each glyphs and their implementation
	Some are unfinished...
*/

#macro BASE_DAMAGE 100

function FormGlyph(_name, _cost) constructor {
	name = _name;
	cost = _cost;
	on_cast = function(spell) {};
	on_step = function(spell) {};
	on_hit = function(spell, target) {};
}

function ElementGlyph(_name, _cost) constructor {
	name = _name; cost = _cost;
	on_hit = function(spell, target) {};
}

function ModifierGlyph(_name, _cost) constructor {
	name = _name; cost = _cost;
	on_cast = function(spell) {};
	on_hit = undefined;
}

function Form_Projectile() : FormGlyph("Bolt", 1) constructor {
	on_cast = function(spell) { 
		spell.spd = 6; 
		spell.lifetime = TARGET_ROOM_SPEED * 1.5;
	};
	on_step = function(spell) { 
		spell.x += lengthdir_x(spell.spd, spell.dir);
		spell.y += lengthdir_y(spell.spd, spell.dir);
	};
	on_hit = function(spell, target) {
		deal_damage(target, BASE_DAMAGE);
	}
}

function Form_Beam() : FormGlyph("Beam", 1) constructor {
	on_cast = function(spell) {
		spell.spd = 0;
		spell.lifetime = TARGET_ROOM_SPEED * 3;
	}
	on_step = function(spell) {
		spell.x += lengthdir_x(10, spell.dir); // This needs the position of nearest enemy in lane to stop unless pierce
		spell.y += lengthdir_y(spell.spd, spell.dir);
	};
	on_hit = function(spell, target) {
		deal_damage(target, BASE_DAMAGE * 0.1);
	}
}

function Form_Strike() : FormGlyph("Strike", 1) constructor {
	on_cast = function(spell) {
		spell.spd = 6;
		spell.lifetime = TARGET_ROOM_SPEED * 1.5;
	}
	on_step = function(spell) {
		spell.x += lengthdir_x(spell.spd, spell.dir); 
		spell.y += lengthdir_y(spell.spd, spell.dir); // Need to spawn spell sprite above tile
	}
}

function Elem_Fire() : ElementGlyph("Fire", 0.5) constructor {
	on_hit = function(spell, target) {
		target.burn_timer = TARGET_ROOM_SPEED * 3;
	};
}

function Elem_Ice() : ElementGlyph("Ice", 0.5) constructor {
	on_hit = function(spell, target) {
		target.slow_timer = TARGET_ROOM_SPEED * 3;
	}
}

function Elem_Lightning() : ElementGlyph("Lightning", 0.5) constructor {
	on_hit = function(spell, target) {
		target.stun_timer = TARGET_ROOM_SPEED;
	}
}

function Mod_Area() : ModifierGlyph("Area", 2.5) constructor {
	on_hit = function(spell, target) {
		// Implement an area of effect once hit	
	};
}

function Mod_Amplify() : ModifierGlyph("Amplify", 2.5) constructor {
	on_hit = function(spell, target) {
		target.is_amplified = true;
	}
}

function Mod_Pierce() : ModifierGlyph("Pierce", 2.5) constructor {
	on_cast = function(spell) {
		spell.pierce = 50; // Probably should be a boolean based on how pierce works
	}
}
