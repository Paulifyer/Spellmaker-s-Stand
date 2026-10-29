// Create 
#macro MAX_MANA				100
#macro MANA_REGEN_RATE		1
#macro MANA_EXHAUST_MULT	3
#macro SPELL_CD				0.8

channel = noone // Holds the spell being channeled
channel_key = -1; // Exact number-row or numpad key holding the channel
channel_slot = -1;
channel_cooldown_penalty = 0;
cast_flash_slot = -1;
cast_flash_ticks = 0;
cost = 0 // Holds the drain cost of the spell casted for channels
max_mana = tune_value("player", "max_mana", MAX_MANA);
var _player_tuning = global.tuning[$ "player"];
var _mana_increases = is_struct(_player_tuning) ? _player_tuning[$ "max_mana_increase_by_level"] : undefined;
if (is_array(_mana_increases)) {
	// Index 0 applies to level 1; add all increases through the current level.
	var _level_count = min(global.current_level + 1, array_length(_mana_increases));
	for (var _i = 0; _i < _level_count; _i++) {
		max_mana += _mana_increases[_i];
	}
}
mana = max_mana;
mana_display = mana;
mana_ticks = 6;
mana_regen_rate = tune_value("player", "mana_regen_rate", MANA_REGEN_RATE); // Percent of max mana regenerated every 6 frames
mana_exhausted_regen_multiplier = tune_value("player", "mana_exhaust_regen_mult", MANA_EXHAUST_MULT);
spell_cooldowns = array_create(SPELL_SLOTS, 0);
spell_cooldown_max = array_create(SPELL_SLOTS, 0);
mana_exhausted = false; // Locks spellcasting and boosts regeneration until mana is full
