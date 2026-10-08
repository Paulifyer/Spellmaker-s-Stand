// Create 
#macro MAX_MANA 150

channel = noone // Holds the spell being channeled
mana = 150;
mana_ticks = 6; mana_regen_rate = 1; // mana regen rate per 6 ticks
mana_exhausted = false; // Locks spellcasting and triples regeneration until mana is full
input_slot = 0;
input_glyphs = [undefined, undefined, undefined];
