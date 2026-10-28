const assert=require('node:assert/strict');
const vm=require('node:vm');
const {loadStatuses}=require('./gml-test-utils.cjs');
const ctx=vm.createContext({global:{}});loadStatuses(ctx);
const enemy={burn_timer:0,burn_dmg:0,slow_timer:0,slow_amt:0,stun_timer:0,stun_immune_timer:0,hex_timer:0};
ctx.combat_status_apply(enemy,'burn',120,40);ctx.combat_status_apply(enemy,'frost',60,0.2);
ctx.combat_status_apply(enemy,'hex',120);assert.equal(ctx.combat_status_count(enemy),3);
ctx.combat_status_apply(enemy,'frost',60,0.2);ctx.combat_status_apply(enemy,'frost',60,0.2);
ctx.combat_status_apply(enemy,'frost',60,0.2);assert.equal(enemy.slow_amt,0.6);
const state=ctx.combat_status_capture(enemy);ctx.combat_status_advance(state,60,false);
assert.equal(state.slow_amt,0);assert.equal(ctx.combat_status_count(state),2);
const pile={};ctx.combat_status_restore(pile,state);assert.equal(pile.burn_timer,60);assert.equal(pile.hex_timer,60);
// A registered status automatically participates in count, transfer, and expiry.
ctx.combat_status_definitions().push({key:'test',timer:'test_timer',fields:['test_timer'],colour:0});
pile.test_timer=5;const next=ctx.combat_status_capture(pile);
assert.equal(ctx.combat_status_count(next),3);ctx.combat_status_advance(next,5,false);
assert.equal(next.test_timer,0);assert.equal(ctx.combat_status_count(next),2);
console.log('Status lifecycle checks passed: apply, refresh, cap, inspect, expiry and registry-driven transfer.');
