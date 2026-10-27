const assert = require('node:assert/strict');
const vm = require('node:vm');
const {read, load} = require('./gml-test-utils.cjs');
const effects = [];
const ctx = vm.createContext({
    array_length:a=>a.length, array_push:(a,v)=>a.push(v), array_delete:(a,i,n)=>a.splice(i,n),
    max:Math.max,round:Math.round,TARGET_ROOM_SPEED:60,
    tune_params:(_,__,___,fallback)=>fallback,
    noone:null,obj_bonepile:'bone',obj_revive_manager:'manager',path_action_stop:0,
});
load(ctx,'scripts/MutationScripts/MutationScripts.gml',[
    'enemy_capture_status','enemy_age_status','enemy_restore_status','enemy_apply_overdue_effects'
]);
load(ctx,'scripts/SpellCatalogScripts/SpellCatalogScripts.gml',['apply_effect_group']);
function enemy(overrides={}) {
    return Object.assign({
        hp:15,max_hp:15,base_speed:0,my_speed:0,mutation:undefined,
        burn_dmg:40,burn_timer:120,slow_amt:0.4,slow_timer:180,
        stun_timer:90,stun_immune_timer:0,hex_timer:150,pending_effects:[],
        path_index:1,path_position:0.5,x:300,y:200,object_index:'brute',wave_owner:{active_enemy_count:1}
    },overrides);
}
const pending=(name,timer,damage=0)=>({timer,spell:{name},fx:{
    mods:[],effect:{on_hit:(spell,target)=>{effects.push(spell.name);target.hp-=damage;}}
}});
const original=enemy({pending_effects:[pending('later',100),pending('early',20),pending('at-spawn',60),pending('early-tie',20)]});
const state=ctx.enemy_capture_status(original);
assert.notEqual(state.pending_effects,original.pending_effects);
assert.notEqual(state.pending_effects[0],original.pending_effects[0]);
ctx.enemy_age_status(state,60);
assert.equal(original.pending_effects[0].timer,100);
assert.equal(state.burn_timer,60);assert.equal(state.slow_timer,120);
assert.equal(state.slow_amt,0.4);assert.equal(state.stun_timer,30);
assert.equal(state.hex_timer,90);assert.equal(effects.length,0); // no invisible target or burn tick
const pile=enemy({burn_dmg:0,burn_timer:0,slow_amt:0,slow_timer:0,stun_timer:0,hex_timer:0});
ctx.enemy_restore_status(pile,state);
ctx.enemy_apply_overdue_effects(pile);
assert.equal(pile.max_hp,15);assert.equal(pile.hp,15);assert.equal(pile.my_speed,0);
assert.deepEqual(effects,['early','early-tie','at-spawn']);
assert.equal(pile.pending_effects.length,1);assert.equal(pile.pending_effects[0].timer,40);
ctx.enemy_apply_overdue_effects(pile);assert.equal(effects.length,3); // execute once

// Expired statuses stay expired; a stun ending during the gap starts its charged period.
const expired=ctx.enemy_capture_status(enemy({burn_timer:20,slow_timer:30,stun_timer:20,hex_timer:60}));
ctx.enemy_age_status(expired,60);
assert.equal(expired.burn_timer,0);assert.equal(expired.slow_timer,0);assert.equal(expired.slow_amt,0);
assert.equal(expired.hex_timer,0);assert.equal(expired.stun_timer,0);assert.equal(expired.stun_immune_timer,140);
const charged=ctx.enemy_capture_status(enemy({stun_timer:0,stun_immune_timer:100}));
ctx.enemy_age_status(charged,60);assert.equal(charged.stun_immune_timer,40);

// Exercise the actual Alarm events with engine object creation/destruction mocked.
const destroyed=[]; const paths=[];
Object.assign(ctx,{
    instance_exists:o=>!!o&&!o.destroyed,
    instance_destroy:o=>{destroyed.push({object:o,owner:o.wave_owner});o.destroyed=true;},
    instance_create_layer:(x,y,layer,type)=>enemy({
        x,y,hp:type==='bone'?15:600,max_hp:type==='bone'?15:600,
        base_speed:type==='bone'?0:1.1,burn_dmg:0,burn_timer:0,slow_amt:0,slow_timer:0,
        stun_timer:0,stun_immune_timer:0,hex_timer:0,pending_effects:[],wave_owner:null
    }),
    path_start:(...args)=>paths.push(args),
});
function runAlarm(file, manager) {
    ctx.manager=manager;
    const event=read(file).replace(/\bexit;/g,'return;');
    vm.runInContext(`(function(){with(manager){${event}\n}})()`,ctx);
}
function managerFor(source) {
    const m={status_state:ctx.enemy_capture_status(source),spawn_delay:1,revive_delay:3,
        ex:source.x,ey:source.y,held_enemy:'brute',wave_owner:source.wave_owner,
        e_path_index:source.path_index,e_path_position:source.path_position,alarm:[],_bones:null,bones_spawned:false};
    m.id=m;
    return m;
}
effects.length=0;
const manager=managerFor(enemy({pending_effects:[pending('gap-hit',30,5),pending('remaining-hit',100)]}));
runAlarm('objects/obj_revive_manager/Alarm_0.gml',manager);
assert.equal(manager._bones.hp,10);assert.equal(manager._bones.burn_timer,60);
assert.equal(manager._bones.pending_effects[0].timer,40);assert.equal(manager.alarm[1],180);
assert.deepEqual(effects,['gap-hit']);

// Tick the actual queued-effect handler for 30 pile frames before revival.
ctx.pile=manager._bones;ctx.pile.id=ctx.pile;
const step=read('objects/obj_enemy_parent/Step_0.gml');
const handler=step.slice(step.indexOf('// Delay Handler'),step.indexOf('// Save'));
for(let i=0;i<30;i++) vm.runInContext(`(function(){with(pile){${handler}}})()`,ctx);
assert.equal(manager._bones.pending_effects[0].timer,10);
manager._bones.burn_timer=30;manager._bones.slow_timer=90;
manager._bones.stun_timer=10;manager._bones.hex_timer=60;
ctx.other=manager;
runAlarm('objects/obj_revive_manager/Alarm_1.gml',manager);
assert.equal(manager.destroyed,true);
assert.equal(destroyed.find(d=>d.object===manager._bones).owner,null); // no decrement during replacement
assert.equal(paths[0][1],0); // carried stun prevents immediate movement

let replacement;
const create=ctx.instance_create_layer;
ctx.instance_create_layer=(...args)=>(replacement=create(...args));
const survivor=managerFor(enemy({pending_effects:[pending('after-revival',300)]}));
runAlarm('objects/obj_revive_manager/Alarm_0.gml',survivor);
survivor._bones.pending_effects[0].timer=7;
survivor._bones.burn_timer=12;survivor._bones.burn_dmg=45;
survivor._bones.hex_timer=18;survivor._bones.stun_timer=0;
survivor._bones.stun_immune_timer=21;
survivor._bones.slow_timer=19;survivor._bones.slow_amt=0.6;
ctx.other=survivor;runAlarm('objects/obj_revive_manager/Alarm_1.gml',survivor);
assert.equal(replacement.hp,600);assert.equal(replacement.max_hp,600);
assert.equal(replacement.burn_dmg,45);assert.equal(replacement.burn_timer,12);
assert.equal(replacement.hex_timer,18);assert.equal(replacement.stun_immune_timer,21);
assert.equal(replacement.slow_timer,19);assert.equal(replacement.slow_amt,0.6);
assert.equal(replacement.pending_effects[0].timer,7);assert.equal(replacement.mutation,undefined);
assert.equal(replacement.wave_owner,survivor.wave_owner);
ctx.pile=replacement;replacement.id=replacement;
for(let i=0;i<7;i++) vm.runInContext(`(function(){with(pile){${handler}}})()`,ctx);
assert.equal(replacement.pending_effects.length,0);assert.ok(effects.includes('after-revival'));

// A gap-due killing blow destroys the pile and cancels the revival immediately.
const killed=managerFor(enemy({pending_effects:[pending('lethal',10,100)]}));
runAlarm('objects/obj_revive_manager/Alarm_0.gml',killed);
assert.equal(killed._bones.destroyed,true);assert.equal(killed.destroyed,true);
assert.equal(killed.alarm[1],undefined);
// A lethal hit on the revival frame also cancels it, even before End Step destroys the pile.
const race=managerFor(enemy());race._bones=enemy({hp:0});
const before=paths.length;runAlarm('objects/obj_revive_manager/Alarm_1.gml',race);
assert.equal(race.destroyed,true);assert.equal(paths.length,before);
const missing=managerFor(enemy());runAlarm('objects/obj_revive_manager/Alarm_1.gml',missing);
assert.equal(missing.destroyed,true);assert.equal(paths.length,before);
console.log('Skeletal status checks passed: copied queues, gap expiry/order, deferred hits, pile death, revival transfer and replacement ownership.');
