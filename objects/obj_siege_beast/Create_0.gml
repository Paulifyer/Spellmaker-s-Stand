/// @description Siege_Beast

// Inherit the parent event
event_inherited();

// This variable stores the name of the enemy as a string for tune
name = "siege_beast";
ward_variant = "wide";

// This variable stores the enemies max health and is used to scale the health bar
max_hp = max_hp * tune_enemy(name, "hp_mult", 4);

// Set the enemies hp to its max hp
hp = max_hp;

// This variable stores the amount of money the player will get when they defeat it
my_value = 5;

// This variable holds the charge speed of the enemy
charge_speed = base_speed * tune_enemy(name, "charge_spd_mult", 4);

normal_speed = base_speed * tune_enemy(name, "spd_mult", 1.1);

// This variable holds the base speed for the enemy
base_speed = charge_speed

// This variable holds the current speed for the enemy
my_speed = base_speed;

// This variable holds the speed the enemy should move at when moving vertically
v_speed = my_speed * 0.7;

charge_sprite = spr_enemy_siegebeast_charge;
walk_sprite = spr_enemy_siegebeast_walk;

// This variable holds the sprite to use when the enemy is moving sideways
walk_side_sprite = spr_enemy_siegebeast_charge;

// This variable holds the sprite to use when the enemy is moving up
walk_up_sprite = spr_frankenstein_walk_up;

// This variable holds the sprite to use when the enemy is moving down
walk_down_sprite = spr_frankenstein_walk_down;


// The defeated enemy to spawn if the enemy is moving sideways
defeat_side_object = obj_frankenstein_defeat_side;

// The defeated enemy to spawn if the enemy is moving down
defeat_down_object = obj_frankenstein_defeat_down;

// This variable is updated to match the health bar offset to the frankensteins height
health_offset_y = -190;

// This variable shows that the enemy is ready to attack
ready_to_attack = false;
charge_active = true;
charge_interrupt_reason = "";
siege_attack_timer = -1;

// This variable is the damage this enemy does each attack
damage_dealt = tune_enemy(name, "attack_dmg", 5);

// This variable is the delay in seconds between this enemy's attacks
max_attack_delay = tune_enemy(name, "attack_delay", 4);
attack_delay = max_attack_delay;



