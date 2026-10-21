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
        }
    };
}

function init_enemy_info() {
	global.enemy_info = {
		obj_mook : { name: "Mook", icon: spr_enemy_mook, notes: "Weakling" },
		obj_brute : { name: "Brute", icon: spr_enemy_brute, notes: "Brutish undead, seems to be harder to kill" },
		obj_ranger : { name: "Ranger", icon: spr_enemy_ranger, notes: "Pesky and annoying, will hit you from afar" }
	};
}