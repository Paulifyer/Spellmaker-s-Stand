/// @description Enemy Parent

/*
	This is the enemy parent. We set up some default variables here,
	but many of them will be overridden in the child's create event.
*/

// This variable stores the enemies max health and is used to scale the health bar
max_hp = 150;

// Set the enemies hp to its max hp
hp = max_hp;

// Sets the object health bar to the enemy hp variable as a value between 0 and 100
health_bar = (hp / max_hp) * 100;

// These variables store the offset positions for the enemy healthbars
health_offset_x = -40;
health_offset_y = 0;

// This variable stores the amount of money the player will get when they defeat it
my_value = 2;

// This variable holds the base speed of an enemy
base_speed = 1;

// This variable holds the speed for the enemy
my_speed = base_speed;

// This variable is used for the enemy's hit flash.
// It is set to 1 when the enemy is hit by something
flash_alpha = 0;

// This variable store the color of the enemy's hit flash
flash_color = c_white;

// These variables hold the enemy's past x and y position which are used to get the enemies direction
x_previous = x;
y_previous = y;

// This variable holds the speed the enemy should move at when moving vertically
v_speed = my_speed * 0.6;

// This variable holds the sprite to use when the enemy is moving sideways
walk_side_sprite = spr_zombie_walk_side;

// This variable holds the sprite to use when the enemy is moving up
walk_up_sprite = spr_zombie_walk_up;

// This variable holds the sprite to use when the enemy is moving down
walk_down_sprite = spr_zombie_walk_down;

// The defeated enemy to spawn if the enemy is moving sideways
defeat_side_object = obj_zombie_defeat_side;

// The defeated enemy to spawn if the enemy is moving down
defeat_down_object = obj_zombie_defeat_down;

image_xscale = 0.6;
image_yscale = 0.6;

burn_dmg = 0;
burn_timer = 0;
slow_amt = 0;
slow_timer = 0;
stun_timer = 0;
stun_immune_timer = 0;

ready_to_attack = true;
damage_dealt = 0;
attack_delay = 0;

// Assigned by a wave manager after this Create event when the enemy is spawned.
wave_owner = noone;

// Description for Crystal Ball
notes = "";

//mutation_key
mutation = undefined;


