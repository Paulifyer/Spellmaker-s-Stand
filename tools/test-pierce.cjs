const assert=require('node:assert/strict');
const {makeExecutionContext}=require('./execution-test-context.cjs');
const vm=require('node:vm');
const {read}=require('./gml-test-utils.cjs');
const fx=effect=>({effect,mods:[]});
// Exercise the collision event itself, including concrete handles passed to methods.
for(const effects of [['fire'],['ice'],['fire','ice'],['ice','fire']]) {
    const h=makeExecutionContext();
    const s=h.spell('projectile',effects.map(fx));
    const target=h.enemy();
    target.id=target;
    let calls=0;
    h.ctx.id=s;
    h.ctx.self={}; // A scope reference must not escape into delivery methods.
    h.ctx.other={id:target,is_targetable:true};
    h.ctx.form={on_hit:(spell,enemy)=>{
        calls++;
        assert.equal(spell,s);
        assert.equal(enemy,target);
        h.ctx.forms.projectile.on_hit(spell,enemy);
    }};
    vm.runInContext(`(function(){${read('objects/obj_spells/Collision_obj_enemy_parent.gml').replace(/\bexit;/g,'return;')}})()`,h.ctx);
    assert.equal(calls,1);
    assert.equal(s.destroyed,true);
    assert.equal(target.hp,100000); // Status delivery requires no direct Harm damage.
    assert.equal(target.burn_timer,effects.includes('fire')?180:0);
    assert.equal(target.burn_dmg,effects.includes('fire')?40:0);
    assert.equal(target.slow_timer,effects.includes('ice')?180:0);
    assert.equal(target.slow_amt,effects.includes('ice')?0.2:0);
    assert.equal(h.ctx.manager.combat_execution.events.length,0);
}
let h=makeExecutionContext();
let s=h.spell('projectile',[fx('fire'),fx('ice')],['pierce']);
const a=h.enemy(1),b=h.enemy(2),c=h.enemy(3);
h.ctx.forms.projectile.on_hit(s,a);
for(let i=0;i<20;i++)h.ctx.forms.projectile.on_hit(s,a);
assert.equal(s.pierce,1);assert.equal(s.destroyed,undefined);assert.equal(h.log.length,2);
h.ctx.forms.projectile.on_hit(s,b);assert.equal(s.destroyed,undefined);
h.ctx.forms.projectile.on_hit(s,c);assert.equal(s.destroyed,true);
assert.deepEqual(h.log,['fire','ice','fire','ice','fire','ice']);
h=makeExecutionContext();s=h.spell('projectile',[fx('harm')],['area','pierce']);
const near=h.enemy(2),blastVictim=h.enemy(3);
h.ctx.forms.projectile.on_hit(s,near);h.ctx.forms.projectile.on_hit(s,blastVictim);
assert.equal(s.pierce,1);assert.equal(h.log.length,2);
const hidden=h.enemy(4,0,{is_targetable:false});h.ctx.forms.projectile.on_hit(s,hidden);assert.equal(s.pierce,1);
h=makeExecutionContext();s=h.spell('projectile',[fx('harm')]);h.ctx.forms.projectile.on_hit(s,h.enemy());
assert.equal(s.destroyed,true);
h=makeExecutionContext();
const distant=h.enemy(4),first=h.enemy(1),third=h.enemy(3),second=h.enemy(2);
h.enemy(0,1);s=h.spell('beam',[fx('harm')],['pierce']);
Object.assign(s,{tick:0,lane:0,beam_lanes:[]});
h.ctx.forms.beam.on_step(s);
assert.equal(first.hp,99975);assert.equal(second.hp,99975);assert.equal(third.hp,99975);assert.equal(distant.hp,100000);
assert.equal(s.beam_lanes[0].len,350);
h.ctx.forms.beam.on_step(s);assert.equal(h.log.length,3);
s.tick=14;h.ctx.forms.beam.on_step(s);assert.equal(h.log.length,6);
console.log('Pierce checks passed: Fire+Ice overlap, Area contacts, hidden targets, no-Pierce and finite per-tick Beam penetration.');
