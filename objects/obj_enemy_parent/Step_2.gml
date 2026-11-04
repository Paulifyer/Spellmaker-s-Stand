/// @description Enemy Parent

// Set depth based on its y value
depth = -y;

// This is how we control the hit flash
// Check if flash_alpha is greater than zero
if (flash_alpha > 0) 
{
	// Reduce the flash
	flash_alpha -= 0.05;
}

// Updates health bar value from hp values as a number between 0 and 100
health_bar = (hp / max_hp) * 100;

// Check if this enemies hp is less than or equal to zero
if (hp <= 0) 
{
	enemy_notify_combat_death(id);
	if (!is_dying) {
		is_dying = true;
		ready_to_attack = false;
		alarm[0] = 10000 * TARGET_ROOM_SPEED;
	}
	if (is_dying) {
		image_alpha -= fade_speed;
		if (image_alpha <= 0) {
	// Give the player some money for destroying the enemey.
	// We do this here, rather than in the destroy event, because we don't want
	// to give any money anytime the enemy is destroyed, only when the enemy is killed.
			if (mutation != undefined) mutation.on_death(id);
	// Destroy this enemy
			instance_destroy(id);
		}
	}
}
