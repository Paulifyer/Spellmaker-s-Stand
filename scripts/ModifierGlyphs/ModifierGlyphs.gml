#macro AMPLIFY_COST		15
#macro PIERCE_COST		15
#macro CHAIN_COST		20
#macro AREA_COST		25

function ModifierGlyph(_name, _cost) constructor {
	name = _name; cost = _cost;
	scope = "spell";
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
	scope = "effect";
	on_cast = function(spell, fx) {
		fx.effect_multiplier += 1;
	}
}

function Mod_Pierce() : ModifierGlyph("Pierce", PIERCE_COST) constructor {
	icon = spr_glyph_pierce
	scope = "spell"
	on_cast = function(spell, fx) {
		spell.pierce += 2; // Probably should be a boolean based on how pierce works
	}
	on_hit = function(spell, target) {}
}

function Mod_None() : ModifierGlyph("none", 0) constructor {
}
