if (!paused && !game_over) {
	combat_execution_flush(combat_execution);
	if (village_hp > 0) enemy_resolve_siege_attacks();
	spell_chain_prune_links(combat_execution);
}
