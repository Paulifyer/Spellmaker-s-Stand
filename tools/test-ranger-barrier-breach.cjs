const assert = require('node:assert/strict');
const vm = require('node:vm');
const { load, read } = require('./gml-test-utils.cjs');

let villageHp = 1;
let shots = 0;
const ranger = {
    x: 1200, y: 216, depth: -216, hp: 150, is_bonepile: false,
    path_position: 0.4, pos_to_stop: 0.3, is_stop_reached: true,
    is_targetable: true, is_ranged: true, ready_to_attack: true,
    base_speed: 1.8, attack_delay: 2, damage_dealt: 1, range_obj: 'arrow', detection_dist: 48,
    stun_timer: 0, hitstun_timer: 0, slow_timer: 0, slow_amt: 0, alarm: [0],
    walk_side_sprite: 'walk', delay_spr: 'delay', delay_frame: 0, delay_speed: 0,
    rock: -1, is_blocked: false, path_speed: 0, my_speed: 0,
    attack_sprite: undefined, pull: undefined, force_push: undefined, mutation: undefined
};
const ctx = vm.createContext({
    ranger, id: ranger, object_index: 'ranger', obj_mook: 'mook', obj_brute: 'brute',
    obj_siege_beast: 'siege', obj_barrier: 'barrier',
    GRID_X0: 128, TARGET_ROOM_SPEED: 60, noone: -1, max: Math.max,
    get_village_hp: () => villageHp,
    enemy_detect_obstacle: () => -1,
    enemy_shoot_prj: () => { shots++; },
    enemy_banner_speed: () => 1,
    variable_instance_exists: Object.hasOwn,
    combat_status_advance() {},
    sprite_get_number: () => 1
});
load(ctx, 'scripts/EnemyHelper/EnemyHelper.gml', ['enemy_update_movement']);

const begin = new vm.Script('with (ranger) {' + read('objects/obj_enemy_parent/Step_1.gml') + '}');
const step = new vm.Script('with (ranger) {' + read('objects/obj_enemy_parent/Step_0.gml') + '}');
begin.runInContext(ctx);
step.runInContext(ctx);
assert.equal(shots, 1);
assert.equal(ranger.path_speed, 0);

villageHp = 0;
ranger.ready_to_attack = true;
begin.runInContext(ctx);
step.runInContext(ctx);
assert.equal(shots, 1);
assert.equal(ranger.is_stop_reached, false);
assert.equal(ranger.path_speed, ranger.base_speed);

ctx.enemy_detect_obstacle = () => ({hp: 3});
ranger.ready_to_attack = true;
begin.runInContext(ctx);
step.runInContext(ctx);
assert.equal(ranger.rock.hp, 2);
assert.equal(ranger.path_speed, 0);
assert.equal(shots, 1);

villageHp = 1;
ranger.is_ranged = false;
ranger.ready_to_attack = true;
ranger.path_position = 0.9;
ranger.x = 280;
ctx.enemy_detect_obstacle = () => -1;
ctx.instance_find = () => ({front_x: 276});
ctx.instance_exists = instance => !!instance;
let hits = 0;
ctx.reduce_village_hp = () => { hits++; };
begin.runInContext(ctx);
step.runInContext(ctx);
assert.equal(hits, 0);
assert.equal(ranger.path_speed, ranger.base_speed);

ranger.x = 276;
begin.runInContext(ctx);
step.runInContext(ctx);
assert.equal(hits, 1);
assert.equal(ranger.path_speed, 0);

villageHp = 0;
begin.runInContext(ctx);
step.runInContext(ctx);
assert.equal(ranger.path_speed, ranger.base_speed);
console.log('Ranger fires while the barrier stands and resumes advancing when it breaks.');
