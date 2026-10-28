const assert=require('node:assert/strict');
const {makePayoffContext}=require('./payoff-test-context.cjs');
const fx=(effect,mods=[])=>({effect,mods});
function charged(h,col=2,extra={}){return h.enemy(col,0,{dmg_reduction:0,stun_immune_timer:180,...extra});}
let h=makePayoffContext(),c=h.ctx,a=charged(h),b=charged(h,3),victim=h.enemy(2,0,{dmg_reduction:0});
c.spell_deliver(h.spell('projectile',[fx('discharge')]),a,2,0);
assert.equal(a.hp,99800);assert.equal(b.hp,99800);assert.equal(victim.hp,99800);
assert.equal(a.stun_immune_timer,0);assert.equal(b.stun_immune_timer,0);
// Even a dense group emits once each, and an uncharged bystander receives at most three hits.
h=makePayoffContext();c=h.ctx;const crowd=Array.from({length:12},()=>charged(h));const bystander=h.enemy(2,0,{dmg_reduction:0});
c.spell_deliver(h.spell('strike',[fx('discharge')]),null,2,0);
assert.equal(bystander.hp,99700);assert.ok(crowd.every(e=>e.hp===99700&&e.stun_immune_timer===0));
// Lethal incoming damage still permits the victim's reserved burst.
h=makePayoffContext();c=h.ctx;a=charged(h,2);b=charged(h,3,{hp:50});const far=h.enemy(4,0,{dmg_reduction:0});
c.spell_deliver(h.spell('projectile',[fx('discharge')]),a,2,0);assert.ok(b.hp<=0);assert.equal(far.hp,99900);
// Stun is distinct from Charged; Discharge does not remove stun or invent a charge.
h=makePayoffContext();c=h.ctx;a=charged(h,2,{stun_timer:60,stun_immune_timer:0});
c.spell_deliver(h.spell('projectile',[fx('discharge')]),a,2,0);assert.equal(a.hp,100000);assert.equal(a.stun_timer,60);
// Effect Area expands the burst, independently from Form Area. Amplify scales every burst.
h=makePayoffContext();c=h.ctx;a=charged(h);b=h.enemy(4,0,{dmg_reduction:0});
c.spell_deliver(h.spell('projectile',[fx('discharge',['area','amplify'])]),a,2,0);assert.equal(b.hp,99800);
// Rune-origin splashes do not affect or consume a Swarmer's Charged; hidden Moles stay excluded.
h=makePayoffContext();c=h.ctx;a=charged(h);b=charged(h,3,{object_index:'swarmer'});const hidden=charged(h,3,{is_targetable:false});
c.spell_deliver(h.spell('rune',[fx('discharge')]),null,2,0);assert.equal(b.hp,100000);assert.equal(b.stun_immune_timer,180);assert.equal(hidden.hp,100000);
// Beam target deliveries share one effect/tick budget, even when targets do not chain into each other.
h=makePayoffContext();c=h.ctx;c.tune_params=(_,id,key,fallback)=>id==='discharge'&&key==='radius_tiles'?0:fallback;
a=charged(h,2);b=charged(h,3);const beam=h.spell('beam',[fx('discharge')]);
c.spell_deliver(beam,a,2,0);c.spell_deliver(beam,b,3,0);
assert.equal(a.hp,99975);assert.equal(b.hp,99975);assert.equal(Object.keys(beam.discharge_reactions).length,1);
assert.equal(Object.keys(beam.discharge_reactions['0'].emitted).length,2);
const prior=beam.discharge_reactions['0'].id;beam.hit_state.epoch++;beam.hit_state.contacts=[];a.stun_immune_timer=180;
c.spell_deliver(beam,a,2,0);assert.notEqual(beam.discharge_reactions['0'].id,prior);assert.equal(a.hp,99950);
console.log('Discharge checks passed: charged-only roots, consumption, dense hit caps, lethal emitters, independent Effect AoE, Amplify, Rune/hidden immunity and Beam tick isolation.');
