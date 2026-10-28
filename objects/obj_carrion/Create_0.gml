/// @description Carrion

// Inherit the parent event
event_inherited();

// This variable stores the name of the enemy as a string for tune
name = "carrion";
ward_variant = "wide";

// This variable stores the enemies max health and is used to scale the health bar
max_hp = max_hp * tune_enemy(name, "hp_mult", 4);

// Set the enemies hp to its max hp
hp = max_hp;
base_hp = tune_value("enemies", "base_hp", BASE_HP);

// This variable stores the amount of money the player will get when they defeat it
my_value = 5;

hit_w = 48

// This variable holds the base speed for the enemy
base_speed = base_speed * tune_enemy(name, "spd_mult", 1.1);

// This variable holds the current speed for the enemy
my_speed = base_speed;

// This variable holds the speed the enemy should move at when moving vertically
v_speed = my_speed * 0.7;

// This variable holds the sprite to use when the enemy is moving sideways
walk_side_sprite = spr_enemy_carrionwalk_new;

// This variable holds the sprite to use when the enemy is moving up
attack_sprite = spr_enemy_carrionpreview;

// This variable holds the sprite to use when the enemy is moving down
walk_down_sprite = spr_frankenstein_walk_down;
// Keep gameplay collisions stable while the displayed pose changes.
mask_index = spr_enemy_carrionwalk;


// The defeated enemy to spawn if the enemy is moving sideways
defeat_side_object = obj_frankenstein_defeat_side;

// The defeated enemy to spawn if the enemy is moving down
defeat_down_object = obj_frankenstein_defeat_down;

// This variable is updated to match the health bar offset to the frankensteins height
health_offset_y = -190;

// This variable shows that the enemy is ready to attack
ready_to_attack = false;

// This variable is the damage this enemy does each attack
damage_dealt = tune_enemy(name, "attack_dmg", 3);

// This variable is the delay in seconds between this enemy's attacks
max_attack_delay = tune_enemy(name, "attack_delay", 3);
attack_delay = max_attack_delay;

// Nearby deaths grant standard HP; frenzy multiplies this Carrion's speed once.
hp_gain_per_death_mult = max(0, tune_enemy(name, "hp_gain_per_death_mult", 0.2));
// Percentage points: 15 heals 15% of the newly increased maximum HP.
heal_on_nearby_death_pct = clamp(tune_enemy(name, "heal_on_nearby_death_pct", 15), 0, 100);
deaths_to_frenzy = max(1, floor(tune_enemy(name, "deaths_to_frenzy", 5)));
frenzy_speed_mult = max(1, tune_enemy(name, "frenzy_speed_mult", 3));
nearby_deaths = 0;
frenzied = false;
screech_duration_frames = max(1, round(tune_enemy(name, "screech_duration", 0.5) * TARGET_ROOM_SPEED));
screech_timer = 0;
is_rune_immune = false;
