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
		obj_mook : { name: "Mook", icon: spr_enemy_mook, notes: "Weakling" },
		obj_brute : { name: "Brute", icon: spr_enemy_brute, notes: "Brutish undead, beefier and becomes faster when its in danger" },
		obj_ranger : { name: "Ranger", icon: spr_enemy_ranger, notes: "Pesky and annoying, will hit you from afar" },
		obj_siege_beast : { name: "Siege Beast", icon: spr_enemy_siegebeast, notes: "Will charge at you unless stunned by lightning" },
		obj_swarmer: { name: "Swarmer", icon: spr_enemy_swarmer, notes: "Spawns in swarms of 3, large bugs attracted by the scent of death" },
		obj_carrion: { name: "Carrion", icon: spr_enemy_carrionpreview, notes: "Grows and heals from nearby deaths. After enough deaths it screeches, then flies faster and becomes immune to Runes." },
		obj_mole: { name: "Mole", icon: spr_enemy_mole, notes: "Subterrainean creature attracted to the scent of death, has a devastating ranged attack as well. While burrowing it is untargettable" }
	};
}
