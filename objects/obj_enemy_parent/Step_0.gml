/// @description Enemy Parent

// Set the sprite to the sideways sprite
sprite_index = walk_side_sprite;
	
// Ensures pull is set correctly
if (pull != undefined) enemy_update_pull(id);

combat_status_advance(id, 1);
if (mutation != undefined) mutation.on_step(id);


enemy_update_movement(id);

// Save it's current x and y
x_previous = x;
y_previous = y;

// Set image_speed as the ratio between my_speed and base_speed
image_speed = my_speed / base_speed; 
