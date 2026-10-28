const assert=require('node:assert/strict');
const {makePayoffContext}=require('./payoff-test-context.cjs');
const fx=(effect,mods=[])=>({effect,mods});
function setup(hp=150,burning=true){const h=makePayoffContext();const e=h.enemy(2,0,{hp,dmg_reduction:0});const neighbor=h.enemy(3,0,{dmg_reduction:0});if(burning)h.ctx.combat_status_apply(e,'burn',180,40);return {...h,e,neighbor};}
for(const order of [['combust','harm'],['harm','combust']]) {
    const h=setup(order[0]==='harm'?80:150);h.ctx.spell_deliver(h.spell('projectile',order.map(x=>fx(x))),h.e,2,0);
    assert.ok(h.e.hp<=0);assert.equal(h.neighbor.hp,99900);assert.equal(h.neighbor.burn_timer,180);assert.equal(h.neighbor.burn_dmg,40);
}
let h=setup(80,false);h.ctx.spell_deliver(h.spell('projectile',[fx('harm'),fx('combust')]),h.e,2,0);assert.equal(h.neighbor.hp,100000);
h=setup(150);h.ctx.spell_deliver(h.spell('projectile',[fx('combust',['delay']),fx('harm')]),h.e,2,0);h.tick(60);assert.equal(h.neighbor.hp,100000);
h=setup(120);h.ctx.spell_deliver(h.spell('projectile',[fx('combust')]),h.e,2,0);h.ctx.combat_status_advance(h.e,60);assert.ok(h.e.hp<=0);assert.equal(h.neighbor.hp,100000);
h=setup(80);const distant=h.enemy(4,0,{dmg_reduction:0});h.ctx.spell_deliver(h.spell('projectile',[fx('combust',['area','amplify'])]),h.e,2,0);
assert.equal(distant.hp,99800);assert.equal(distant.burn_dmg,80);
h=setup(80);h.neighbor.hp=50;h.ctx.combat_status_apply(h.neighbor,'burn',180,40);const far=h.enemy(4,0,{dmg_reduction:0});
h.ctx.spell_deliver(h.spell('projectile',[fx('combust')]),h.e,2,0);assert.ok(h.neighbor.hp<=0);assert.equal(far.hp,100000); // splash kills do not recursively combust
// Distinct deliveries may not reuse the previous execution's Combust context.
h=setup(150);h.ctx.spell_deliver(h.spell('projectile',[fx('combust')]),h.e,2,0);h.ctx.spell_deliver(h.spell('projectile',[fx('harm')]),h.e,2,0);assert.equal(h.neighbor.hp,100000);
console.log('Combust checks passed: direct kills before/after Combust, burning requirement, Delay/burn/cast isolation, Effect AoE, Amplify and nonrecursive explosions.');
