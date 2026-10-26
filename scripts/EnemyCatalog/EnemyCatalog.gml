function init_enemy_catalog() {
    global.EnemyCatalog = {
        MOOK: {
            object: obj_mook,
            cost: 1,
        },
        RANGER: {
            object: obj_ranger,
            cost: 2,
        },

        BRUTE: {
            object: obj_brute,
            cost: 4,
        },
		SWARMER: {
			object: obj_swarmer,
			cost: 2
		},
		SIEGE_BEAST: {
			object: obj_siege_beast,
			cost: 10
		},
		MOLE: {
			object: obj_mole,
			cost: 3
		}
    };
}

function init_enemy_info() {
	global.enemy_info = {
		obj_mook : { name: "Mook", icon: spr_enemy_mook, notes: "Weakling" },
		obj_brute : { name: "Brute", icon: spr_enemy_brute, notes: "Brutish undead, beefier and becomes faster when its in danger" },
		obj_ranger : { name: "Ranger", icon: spr_enemy_ranger, notes: "Pesky and annoying, will hit you from afar" },
		obj_siege_beast : { name: "Siege_Beast", icon: spr_enemy_siegebeast, notes: "Will charge at you unless stunned by lightning"}
	};
}