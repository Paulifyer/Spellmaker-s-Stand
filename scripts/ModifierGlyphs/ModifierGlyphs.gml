#macro AMPLIFY_COST		15
#macro PIERCE_COST		15
#macro CHAIN_COST		20
#macro AREA_COST		25
#macro EXTEND_TIME_COST	5
#macro EXTEND_TIME_MULT 5

function ModifierGlyph(_name, _cost) constructor {
	name = _name; cost = _cost;
	scope = "spell";
	is_stacks = false;
	allowed_forms = undefined;
	icon = undefined;
	desc = "";
	on_cast = function(spell, fx) {};
	on_hit = undefined;
}

function Mod_Area() : ModifierGlyph("Area", AREA_COST) constructor {
	icon = spr_glyph_pierce;
	scope = "spell";
	on_cast = function(spell, fx) {
		spell.area = true;
	}
	on_hit = function(spell, target) {};
}

function Mod_Amplify() : ModifierGlyph("Amplify", AMPLIFY_COST) constructor {
	icon = spr_glyph_amplify;
	is_stacks = true;
	scope = "effect";
	on_cast = function(spell, fx) {
		fx.effect_multiplier += 1;
	}
}

function Mod_Pierce() : ModifierGlyph("Pierce", PIERCE_COST) constructor {
	icon = spr_glyph_pierce
	is_stacks = true;
	scope = "spell";
	on_cast = function(spell, fx) {
		spell.pierce += 2; // Probably should be a boolean based on how pierce works
	}
	on_hit = function(spell, target) {}
}

function Mod_Extend_Time(): ModifierGlyph("ExtendTime", EXTEND_TIME_COST) constructor {
	icon = spr_placeholder_extendtime;
	is_stacks = true;
	scope = "effect";
	on_cast = function(spell, fx) {
		fx.duration += EXTEND_TIME_MULT; // Uses fixed amount atm
	}
	
}

function Mod_None() : ModifierGlyph("none", 0) constructor {
}
