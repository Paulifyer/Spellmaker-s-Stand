/// @description Enemy Parent

var _is_dead = hp <= 0;
var _is_skeletal = enemy_has_mutation(id, "skeletal") && combat_lineage != undefined && combat_lineage.gap;
if (combat_lineage != undefined && !combat_lineage.gap && combat_lineage.target == id) {
	combat_lineage.alive = false;
	combat_lineage.target = noone;
}

// Always notify the spawning manager, including when this enemy reaches a base.
// Skeletal deaths are excluded because their replacement is still active.
if (!_is_skeletal && instance_exists(wave_owner))
{
	wave_owner.active_enemy_count = max(0, wave_owner.active_enemy_count - 1);
	wave_owner = noone;
}
