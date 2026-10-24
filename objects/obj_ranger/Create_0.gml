/// @description Ranger

// Inherit the parent event
event_inherited();

// This variable stores the name of the enemy as a string for tune
name = "ranger";

// This variable stores the enemies max health and is used to scale the health bar
var hp_mult = tune_enemy(name, "hp_mult", 1);
max_hp = max_hp * hp_mult;

// Set the enemies hp to its max hp
hp = max_hp;

// This variable stores the amount of money the player will get when they defeat it
my_value = 3;

// This variable holds the base speed for the enemy
var spd_mult = tune_enemy(name, "spd_mult", 1.8);
base_speed = base_speed * spd_mult;
// This variable holds the current speed for the enemy
my_speed = base_speed;

// This variable holds the speed the enemy should move at when moving vertically
v_speed = my_speed * 0.6;

// This variable holds the sprite to use when the enemy is moving sideways
walk_side_sprite = spr_enemy_ranger;

// This variable holds the sprite to use when the enemy is moving up
walk_up_sprite = spr_zombie_walk_up;

// This variable holds the sprite to use when the enemy is moving down
walk_down_sprite = spr_zombie_walk_down;

// The defeated enemy to spawn if the enemy is moving sideways
defeat_side_object = obj_zombie_defeat_side;

// The defeated enemy to spawn if the enemy is moving down
defeat_down_object = obj_zombie_defeat_down;

// This variable is updated to match the health bar offset to the zombies height
health_offset_y = -170;

// This variable shows that the enemy is ready to attack
ready_to_attack = false;

// This variable is the damage this enemy does each attack
damage_dealt = tune_enemy(name, "attack_dmg", 1);

// This variable is the delay in seconds between this enemy's attacks
attack_delay = tune_enemy(name, "attack_delay", 2);

// Range Selector
pos_to_stop = 1 - (0.9 - random(0.4));

