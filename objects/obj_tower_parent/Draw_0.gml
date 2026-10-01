/// @description Tower Parent


// Draw the tower shadow underneath the tower
draw_sprite(spr_tower_shadow, 0, x, y);

// Then draw the tower itself
draw_self();

// Use a for loop to draw the upgrade stars
for (var _i = 0; _i < level; _i += 1) 
{
	// Declare the temporary variables
	var _x = 0, _y = 0;
	
	// The x position should equal the tower's x plus 70 (off to the right)
	_x = x + 70;
	
	// The y position should equal the tower's y minus 150 (up) and
	// we should add space for every iteration of the loop 
	_y = (y - 150) + (_i * 36);
	
	// Draw the upgrade star
	draw_sprite(spr_level_star, 0, _x, _y);
}



