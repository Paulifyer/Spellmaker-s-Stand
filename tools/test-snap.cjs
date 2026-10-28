const assert=require('node:assert/strict');
const {makePayoffContext}=require('./payoff-test-context.cjs');
const fx=(effect,mods=[])=>({effect,mods});
for(const stacks of [0,1,2,3]) {
    const h=makePayoffContext(),c=h.ctx,e=h.enemy(2,0,{dmg_reduction:0});
    for(let i=0;i<stacks;i++)c.combat_status_apply(e,'frost',180,0.2);
    const s=h.spell('projectile',[fx('snap')]);c.spell_deliver(s,e,2,0);
    assert.equal(e.hp,100000-stacks*120);assert.equal(e.slow_amt,0);assert.equal(c.combat_status_count(e),0);
    assert.equal(e.path_speed,stacks?1:undefined);
}
let h=makePayoffContext(),c=h.ctx,e=h.enemy(2,0,{dmg_reduction:0,hex_timer:60});
c.combat_status_apply(e,'frost',180,0.2);
c.enemy_ward_active=t=>!c.combat_status_active(t,'frost');
c.spell_deliver(h.spell('projectile',[fx('snap',['amplify'])]),e,2,0);
assert.equal(e.hp,100000-288); // 120 * 2 * 1.2 Hex, ward absent until after damage
assert.equal(c.enemy_ward_active(e),true);assert.equal(c.combat_status_count(e),1);
h=makePayoffContext();c=h.ctx;e=h.enemy(2,0,{dmg_reduction:0});
c.combat_status_apply(e,'frost',180,0.2);
const delayed=h.spell('projectile',[fx('harm',['delay']),fx('snap')]);
c.tune_params=(_,id,key,fallback)=>id==='snap'&&key==='damage_per_stack_mult'?5:fallback;
c.spell_deliver(delayed,e,2,0);h.tick(60);assert.equal(e.hp,100000-100-120); // captured 1.2
h=makePayoffContext();c=h.ctx;e=h.enemy(2,0,{dmg_reduction:0});c.combat_status_apply(e,'frost',180,0.2);
c.spell_deliver(h.spell('beam',[fx('snap')]),e,2,0);assert.equal(e.hp,100000-30);
console.log('Snap checks passed: 0-3 stacks, consumption, movement, ward/Hex ordering, Amplify, captured tuning, Delay and Beam scaling.');
