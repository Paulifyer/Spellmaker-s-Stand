const assert=require('node:assert/strict');
const vm=require('node:vm');
const {read,extract,load}=require('./gml-test-utils.cjs');
const ctx=vm.createContext({max:Math.max,round:Math.round,TARGET_ROOM_SPEED:60,LIGHTNING_DURATION:1,
    tune_params:(_,__,___,fallback)=>fallback});
load(ctx,'scripts/EnemyHelper/EnemyHelper.gml',['enemy_advance_lightning']);
function hit(name){
    const body=extract(read('scripts/EffectGlyphs/EffectGlyphs.gml'),`Elem_${name}`);
    const part=body.slice(body.indexOf('on_hit = function')).replace('function(','function callback(');
    return vm.runInContext(`(${extract(part,'callback')})`,ctx);
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
