/// @description Enemy Parent

var _is_dead = hp <= 0;
var _is_skeletal = enemy_has_mutation(self, "skeletal") && combat_lineage != undefined && combat_lineage.gap;
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


// Check if the enemy is walking sideways
if (sprite_index == walk_side_sprite) 
{
	// If so, create an instance of their defeat_side_object and use with to access its variables
	with (instance_create_depth(x, y, depth, defeat_side_object)) 
	{
		// Set image_xscale to the xscale of the instance that created it
		// This will make the newly created instance face the right way
		image_xscale = other.image_xscale;
	}
} 
// If it is not walking sideways
else 
{	
	// Create this instance's defeat_down_object
	instance_create_depth(x, y, depth, defeat_down_object);
}

