const assert=require('node:assert/strict');
const vm=require('node:vm');
const {read,load}=require('./gml-test-utils.cjs');
const {makeEnemyContext}=require('./enemy-test-context.cjs');
const h=makeEnemyContext(),ctx=h.ctx;
Object.assign(ctx,{obj_mole:'mole',path_exists:p=>p===1,path_get_x:(p,t)=>1000-800*t,path_get_y:()=>432});
load(ctx,'scripts/EnemyHelper/EnemyHelper.gml',['enemy_initialize_mole_marker']);
const e=h.enemy(2,0,{object_index:'mole',pos_to_stop:0.4,path_position:0.5,path_speed:1,emerged:false,ready_to_attack:false,
 attack_delay:3,alarm:[1],walk_side_sprite:0,normal_sprite:1,base_speed:1,my_speed:1,emergence_marker:undefined});
ctx.enemy_initialize_mole_marker(e,1);assert.equal(e.emergence_marker.x,680);assert.equal(e.emergence_marker.y,432);
ctx.actor=e;vm.runInContext('(function(){with(actor){'+read('objects/obj_mole/Step_1.gml')+'}})()',ctx);
assert.equal(e.emerged,true);assert.equal(e.emergence_marker.active,false);assert.equal(e.x,680);assert.equal(e.y,432);
assert.equal(e.is_targetable,true);assert.equal(e.path_position,0.4);assert.equal(e.path_speed,0);
const ordinary=h.enemy();ctx.enemy_initialize_mole_marker(ordinary,1);assert.equal(ordinary.emergence_marker,undefined);
console.log('Mole marker checks passed: assigned-path destination, exact emergence, marker removal and other enemies unchanged.');
