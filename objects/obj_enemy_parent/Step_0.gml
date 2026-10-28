/// @description Enemy Parent

// Set the sprite to the sideways sprite
sprite_index = walk_side_sprite;
	
// Ensures pull is set correctly
if (pull != undefined) enemy_update_pull(id);

combat_status_advance(self, 1);


enemy_update_movement(self);

// Save it's current x and y
x_previous = x;
y_previous = y;
