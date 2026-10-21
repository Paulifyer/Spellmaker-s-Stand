// Create 
#macro MAX_MANA				100
#macro MANA_REGEN_RATE		1
#macro MANA_EXHAUST_MULT	3
#macro SPELL_CD				0.8

channel = noone // Holds the spell being channeled
cost = 0 // Holds the drain cost of the spell casted for channels
max_mana = tune_player("player", "max_mana", MAX_MANA);
mana = max_mana;
mana_display = mana;
mana_ticks = 6;
mana_regen_rate = tune_player("player", "mana_regen_rate", MANA_REGEN_RATE); // mana regen per sec
mana_exhausted_regen_multiplier = tune_player("player", "mana_exhaust_regen_mult", MANA_EXHAUST_MULT);
is_spell_on_cd = false;
mana_exhausted = false; // Locks spellcasting and boosts regeneration until mana is full
spell_selected = -1;
input_slot = 0;
