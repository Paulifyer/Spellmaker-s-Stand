#macro AMPLIFY_COST		15
#macro AMPLIFY_ADD_MULT	1
#macro PIERCE_COST		15
#macro PIERCE_AMT		2
#macro CHAIN_COST		20
#macro AREA_COST		25
#macro EXTEND_TIME_COST	5
#macro EXTEND_TIME_ADD 5

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
	icon = spr_glyph_aoe;
	scope = "spell";
	cost = tune_params("modifiers", "area", "cost", AREA_COST);
	on_cast = function(spell, fx) {
		spell.area = true;
	}
	on_hit = function(spell, target) {};
}

function Mod_Amplify() : ModifierGlyph("Amplify", AMPLIFY_COST) constructor {
	icon = spr_glyph_amplify;
	cost = tune_params("modifiers", "amplify", "cost", AMPLIFY_COST);
	is_stacks = true;
	scope = "effect";
	on_cast = function(spell, fx) {
		fx.effect_multiplier += tune_params("modifiers", "amplify", "dmg_multplier", AMPLIFY_ADD_MULT);
	}
}

function Mod_Pierce() : ModifierGlyph("Pierce", PIERCE_COST) constructor {
	icon = spr_glyph_pierce
	cost = tune_params("modifiers", "pierce", "cost", PIERCE_COST);
	is_stacks = true;
	scope = "spell";
	on_cast = function(spell, fx) {
		spell.pierce += tune_params("modifiers", "pierce", "pierce_amt", PIERCE_AMT);
	}
	on_hit = function(spell, target) {}
}

function Mod_Extend_Time(): ModifierGlyph("ExtendTime", EXTEND_TIME_COST) constructor {
	icon = spr_glyph_extendtime;
	cost = tune_params("modifiers", "extend_time", "cost", EXTEND_TIME_COST);
	is_stacks = true;
	scope = "effect";
	on_cast = function(spell, fx) {
		fx.duration += tune_params("modifiers", "extend_time", "duration_increase", EXTEND_TIME_ADD); // Uses fixed amount atm
	}
	
}

function Mod_None() : ModifierGlyph("none", 0) constructor {
}
