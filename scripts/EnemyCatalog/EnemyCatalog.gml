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