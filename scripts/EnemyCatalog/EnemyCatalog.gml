function init_enemy_catalog() {
    if (!variable_global_exists("tuning")) load_tuning();
    global.EnemyCatalog = {
        MOOK: {
            object: obj_mook,
            cost: tune_enemy("mook", "spawn_weight", 1),
        },
        RANGER: {
            object: obj_ranger,
            cost: tune_enemy("ranger", "spawn_weight", 2),
        },

        BRUTE: {
            object: obj_brute,
            cost: tune_enemy("brute", "spawn_weight", 4),
        },
		SWARMER: {
			object: obj_swarmer,
			cost: tune_enemy("swarmer", "spawn_weight", 2)
		},
		SIEGE_BEAST: {
			object: obj_siege_beast,
			cost: tune_enemy("siege_beast", "spawn_weight", 10)
		},
		MOLE: {
			object: obj_mole,
			cost: tune_enemy("mole", "spawn_weight", 3)
		},
		CARRION: {
			object: obj_carrion,
			cost: tune_enemy("carrion", "spawn_weight", 7)
		}
    };
}

function init_enemy_info() {
	global.enemy_info = {
		obj_mook : { name: "Mook", icon: spr_enemy_mook_old, notes: "Malformed, decomposing cadaver. Weakling" },
		obj_brute : { name: "Brute", icon: spr_enemy_brute_old, notes: "Putrid flesh clad in the remnants of a champion's armour. Its honour has rotted away, but its fury remains." },
		obj_ranger : { name: "Ranger", icon: spr_enemy_ranger_old, notes: "A skilled marksman, as it was in life. Prefers to attack from a comfortable distance." },
		obj_siege_beast : { name: "Siege Beast", icon: spr_enemy_siegebeast, notes: "Charges headlong into the first thing in its way. Easily dazed." },
		obj_swarmer: { name: "Swarmer", icon: spr_enemy_swarmer_old, notes: "Attracted by the scent of death. They rarely appear alone." },
		obj_carrion: { name: "Carrion", icon: spr_enemy_carrionpreview, notes: "Grotesque scavanger that feasts on fallen corpses. Grows stronger with every meal." },
		obj_mole: { name: "Mole", icon: spr_enemy_mole, notes: "Loathsome burrower whos arrival is annouced by trembling ground." }
	};
}
