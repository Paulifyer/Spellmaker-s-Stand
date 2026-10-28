#macro AMPLIFY_COST		15
#macro AMPLIFY_ADD_MULT	1
#macro PIERCE_COST		15
#macro PIERCE_AMT		2
#macro CHAIN_COST		20
#macro AREA_COST		25
#macro EXTEND_TIME_COST	5
#macro EXTEND_TIME_ADD	5
#macro DELAY_COST		5
#macro DELAY_AMT		1

function ModifierGlyph(_name, _cost) constructor {
	name = _name; cost = _cost;
	scope = "spell";
	is_stacks = false;
	allowed_forms = undefined;
	allowed_effects = undefined;
	icon = undefined;
	desc = "";
	on_cast = function(spell, fx) {};
	on_hit = undefined;
}

function Mod_Area() : ModifierGlyph("Area", AREA_COST) constructor {
	icon = spr_glyph_aoe;
	scope = "both";
	allowed_forms = ["projectile", "beam", "strike", "rune"];
	allowed_effects = ["combust", "discharge"];
	desc = "Expand a Form's delivery area or a compatible Effect's burst area. Pull keeps its normal 3x3 area.";
	cost = tune_params("modifiers", "area", "cost", AREA_COST);
	on_cast = function(spell, fx) {
		if (fx == undefined) spell.area = true; else fx.area = true;
	}
	on_hit = function(spell, target) {};
}

function Mod_Amplify() : ModifierGlyph("Amplify", AMPLIFY_COST) constructor {
	icon = spr_glyph_amplify;
	cost = tune_params("modifiers", "amplify", "cost", AMPLIFY_COST);
	is_stacks = true;
	scope = "effect";
	allowed_effects = ["harm", "fire", "snap", "combust", "discharge"];
	on_cast = function(spell, fx) {
		fx.effect_multiplier += tune_params("modifiers", "amplify", "dmg_multplier", AMPLIFY_ADD_MULT);
	}
}

function Mod_Pierce() : ModifierGlyph("Pierce", PIERCE_COST) constructor {
	icon = spr_glyph_pierce
	cost = tune_params("modifiers", "pierce", "cost", PIERCE_COST);
	is_stacks = true;
	scope = "spell";
	allowed_forms = ["projectile", "beam"];
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
	allowed_effects = ["fire", "ice", "lightning", "hex"];
	on_cast = function(spell, fx) {
		fx.duration += tune_params("modifiers", "extend_time", "duration_increase", EXTEND_TIME_ADD); // Uses fixed amount atm
	}
}

function Mod_Delay(): ModifierGlyph("Delay", DELAY_COST) constructor {
	icon = spr_glyph_delay;
	cost = tune_params("modifiers", "delay", "cost", DELAY_COST);
	is_stacks = true;
	scope = "effect";
	desc = "Delays the effects after this group. Allows an effect to repeat after the delay. Stacks add more time.";
	on_cast = function(spell, fx) {
		fx.delay_after += tune_params("modifiers", "delay", "delay_increase", DELAY_AMT);
	}
}

function Mod_None() : ModifierGlyph("none", 0) constructor {
}

function Mod_Chain() : ModifierGlyph("Chain", CHAIN_COST) constructor {
	icon = spr_glyph_chain;
	cost = tune_params("modifiers", "chain", "cost", CHAIN_COST);
	scope = "spell";
	is_stacks = true;
	allowed_forms = ["projectile", "beam", "strike", "rune"];
	desc = "Each fresh Form hit chains sequentially to nearby unhit enemies. Stacks add more hops.";
	on_cast = function(spell, fx) {
		var _hops = tune_setting("modifiers", "chain", "hops_per_stack", 2);
		if (!is_real(_hops) || _hops < 0 || floor(_hops) != _hops) throw "chain.hops_per_stack must be a non-negative integer";
		spell.chain_hops += _hops;
	};
}
