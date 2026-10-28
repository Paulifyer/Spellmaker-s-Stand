const assert=require('node:assert/strict');
const vm=require('node:vm');
const {read,extract,load,loadStatuses}=require('./gml-test-utils.cjs');
const ctx=vm.createContext({max:Math.max,round:Math.round,clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),TARGET_ROOM_SPEED:60,LIGHTNING_DURATION:1,
    tune_params:(_,__,___,fallback)=>fallback});
load(ctx,'scripts/EnemyHelper/EnemyHelper.gml',['enemy_advance_lightning']);
loadStatuses(ctx);
ctx.tune_value=(_,__,v)=>v;
load(ctx,'scripts/SpellCatalogScripts/SpellCatalogScripts.gml',['compile_effect_parameters']);
function hit(name){
    const body=extract(read('scripts/EffectGlyphs/EffectGlyphs.gml'),`Elem_${name}`);
    const part=body.slice(body.indexOf('on_hit = function')).replace('function(','function callback(');
    const fn=vm.runInContext(`(${extract(part,'callback')})`,ctx);
    return (spell,target,fx)=>fn(spell,target,{...fx,params:ctx.compile_effect_parameters(name.toLowerCase())});
}
const lightning=hit('Lightning');
const target={stun_timer:0,stun_immune_timer:0};
lightning({},target,{duration:0});assert.equal(target.stun_timer,60);
ctx.enemy_advance_lightning(target,10);lightning({},target,{duration:5});
assert.equal(target.stun_timer,50); // no refresh while stunned
ctx.enemy_advance_lightning(target,50);assert.equal(target.stun_immune_timer,180);
lightning({},target,{duration:0});assert.equal(target.stun_timer,0);
ctx.enemy_advance_lightning(target,179);assert.equal(target.stun_immune_timer,1);
ctx.enemy_advance_lightning(target,1);assert.equal(target.stun_immune_timer,0);
ctx.enemy_advance_lightning(target,30);assert.equal(target.stun_immune_timer,0);
lightning({},target,{duration:5});assert.equal(target.stun_timer,360);
const gap={stun_timer:20,stun_immune_timer:0};
ctx.enemy_advance_lightning(gap,60);assert.equal(gap.stun_timer,0);assert.equal(gap.stun_immune_timer,140);
console.log('Status interaction checks passed: first stun, no refresh, finite charged immunity, Extend Time and gap transitions.');
load(ctx,'scripts/EnemyHelper/EnemyHelper.gml',['enemy_update_movement']);
const mover={base_speed:1.1,slow_amt:0.6,slow_timer:100,stun_timer:0,pull:undefined};
ctx.enemy_update_movement(mover);assert.ok(Math.abs(mover.path_speed-0.44)<1e-9);
ctx.enemy_update_movement(mover,2);assert.ok(Math.abs(mover.path_speed-0.88)<1e-9);
mover.stun_timer=1;ctx.enemy_update_movement(mover,2);assert.equal(mover.path_speed,0);
mover.stun_timer=0;mover.pull={};ctx.enemy_update_movement(mover);assert.equal(mover.path_speed,0);
mover.pull=undefined;mover.slow_timer=0;ctx.enemy_update_movement(mover);assert.equal(mover.path_speed,1.1);
mover.base_speed=0;ctx.enemy_update_movement(mover);assert.equal(mover.path_speed,0);
// Run actual child events against the same shared movement helper.
function child(file,enemy){ctx.enemy=enemy;ctx.event_inherited=()=>{};vm.runInContext(`(function(){with(enemy){${read(file)}}})()`,ctx);}
Object.assign(mover,{self:mover,hp:20,max_hp:100,attack_delay:2,max_attack_delay:2,enrage_mult:2,base_speed:1.1,slow_timer:60,slow_amt:0.6});
child('objects/obj_brute/Step_0.gml',mover);assert.ok(Math.abs(mover.path_speed-0.88)<1e-9);assert.equal(mover.attack_delay,1);
Object.assign(mover,{base_speed:4,normal_speed:0.6,stun_timer:1});
ctx.enemy=mover;ctx.event_inherited=()=>{mover.stun_timer=0;};
vm.runInContext(`(function(){with(enemy){${read('objects/obj_siege_beast/Step_0.gml')}}})()`,ctx);
assert.equal(mover.base_speed,0.6);assert.ok(Math.abs(mover.path_speed-0.24)<1e-9);
console.log('Movement checks passed: Frost, enrage, Stun, Pull, stationary enemies and charge interruption.');
