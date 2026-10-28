const assert=require('node:assert/strict');
const vm=require('node:vm');
const {read,load}=require('./gml-test-utils.cjs');
const {makeExecutionContext}=require('./execution-test-context.cjs');
const fx=(effect,mods=[])=>({effect,mods});
function setup(){
 const h=makeExecutionContext(),ctx=h.ctx;
 load(ctx,'scripts/MutationScripts/MutationScripts.gml',['enemy_capture_status','enemy_age_status','enemy_restore_status']);
 ctx.obj_bonepile='bone';ctx.path_action_stop=0;ctx.path_start=()=>{};
 ctx.instance_create_layer=(x,y,layer,type)=>h.enemy(Math.floor(x/100),Math.floor(y/100),{hp:type==='bone'?15:600,max_hp:type==='bone'?15:600,base_speed:type==='bone'?0:1,wave_owner:null});
 function manager(source){
  const lineage=ctx.enemy_get_lineage(source);lineage.gap=true;lineage.target=null;source.destroyed=true;
  const m={lineage,status_state:ctx.enemy_capture_status(source),spawn_delay:1,revive_delay:3,ex:source.x,ey:source.y,
   held_enemy:'brute',wave_owner:{active_enemy_count:1},e_path_index:1,e_path_position:0.5,alarm:[],_bones:null,bones_spawned:false};
  m.id=m;return m;
 }
 function alarm(file,m){ctx.reviver=m;ctx.other=m;vm.runInContext('(function(){with(reviver){'+read('objects/obj_revive_manager/'+file).replace(/\bexit;/g,'return;')+'}})()',ctx);}
 return {...h,manager,alarm};
}
let h=setup();let source=h.enemy();
h.ctx.global.spell_glyphs.effect.harm.on_hit=(s,e)=>{e.hp-=5;};
const spell=h.spell('projectile',[fx('fire',['delay']),fx('harm',['delay','delay','delay','delay']),fx('harm')]);
h.ctx.spell_deliver(spell,source,2,0);
Object.assign(source,{burn_timer:120,burn_dmg:1,slow_timer:500,slow_amt:0.4,stun_timer:90,hex_timer:500});
const m=h.manager(source);h.tick(60);h.alarm('Alarm_0.gml',m);
assert.equal(m._bones.hp,10);assert.equal(m._bones.max_hp,15);assert.equal(m._bones.burn_timer,60);
assert.equal(m._bones.slow_timer,440);assert.equal(m._bones.stun_timer,30);assert.equal(m._bones.hex_timer,440);
assert.equal(h.ctx.manager.combat_execution.events.length,1);
const snapshot=h.ctx.enemy_capture_status(m._bones);h.ctx.enemy_age_status(snapshot,180);
h.ctx.enemy_restore_status(m._bones,snapshot);h.tick(180);
h.alarm('Alarm_1.gml',m);
const revived=m.lineage.target;
assert.equal(revived.hp,600);assert.equal(revived.mutation,undefined);assert.equal(revived.wave_owner,m.wave_owner);
assert.equal(revived.slow_timer,260);assert.equal(revived.stun_immune_timer,30);
assert.equal(revived.burn_timer,0);assert.equal(revived.hex_timer,260);
h.tick(60);assert.equal(revived.hp,595);assert.equal(h.ctx.manager.combat_execution.events.length,0);
h=setup();source=h.enemy();h.ctx.spell_deliver(h.spell('projectile',[fx('fire',['delay']),fx('harm')]),source,2,0);
const lethal=h.manager(source);h.tick(60);h.alarm('Alarm_0.gml',lethal);
assert.equal(lethal._bones.destroyed,true);assert.equal(lethal.destroyed,true);assert.equal(lethal.alarm[1],undefined);
const race=h.manager(h.enemy());race._bones=h.enemy(2,0,{hp:0});
h.alarm('Alarm_1.gml',race);assert.equal(race.destroyed,true);
const missing=h.manager(h.enemy());h.alarm('Alarm_1.gml',missing);assert.equal(missing.destroyed,true);
console.log('Skeletal checks passed: shared scheduled lineage, gap-overdue hits, status expiry, revival and lethal-pile cancellation.');
