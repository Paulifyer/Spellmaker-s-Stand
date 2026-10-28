const assert=require('node:assert/strict');
const {load}=require('./gml-test-utils.cjs');
const {makeExecutionContext}=require('./execution-test-context.cjs');
const fx=(effect,mods=[])=>({effect,mods});
function setup(){
    const h=makeExecutionContext();h.stops=0;h.ctx.path_end=()=>h.stops++;
    load(h.ctx,'scripts/EnemyHelper/EnemyHelper.gml',['enemy_can_be_displaced','enemy_begin_pull']);
    h.beast=h.enemy(2,0,{charge_active:true,normal_speed:0.6,base_speed:4,path_speed:4,
        is_pull_immune:false,ready_to_attack:false,siege_attack_timer:-1,image_xscale:1,image_yscale:1});
    return h;
}
let h=setup(),c=h.ctx,e=h.beast;
c.enemy_begin_pull(e,100,100,0,24,12);
assert.equal(c.enemy_can_be_displaced(e),false);assert.equal(e.pull,undefined);
assert.equal(h.stops,0);assert.equal(e.charge_active,true);assert.equal(e.path_speed,4);
// Arrival or a successful interruption unlocks displacement immediately.
for(const reason of ['impact','stun','barricade']) {
    h=setup();c=h.ctx;e=h.beast;c.enemy_interrupt_charge(e,reason);
    assert.equal(c.enemy_can_be_displaced(e),true);
    c.enemy_begin_pull(e,100,100,0,24,12);assert.ok(e.pull);assert.equal(h.stops,1);
}
// Written order is respected: a successful stun before Pull permits it in this delivery.
h=setup();c=h.ctx;e=h.beast;c.spell_deliver(h.spell('strike',[fx('lightning'),fx('pull')]),null,2,0);
assert.equal(e.charge_active,false);assert.ok(e.pull);assert.equal(h.stops,1);
// Pull before Lightning is rejected and is not retried after the later interruption.
h=setup();c=h.ctx;e=h.beast;c.spell_deliver(h.spell('strike',[fx('pull'),fx('lightning')]),null,2,0);
assert.equal(e.charge_active,false);assert.equal(e.pull,undefined);assert.equal(h.stops,0);
// A rejected stun (Charged) does not interrupt charge or allow displacement.
h=setup();c=h.ctx;e=h.beast;e.stun_immune_timer=60;
c.spell_deliver(h.spell('strike',[fx('lightning'),fx('pull')]),null,2,0);
assert.equal(e.charge_active,true);assert.equal(e.pull,undefined);
// Delayed Pull checks current charge state when it activates, not when cast.
h=setup();c=h.ctx;e=h.beast;
c.spell_deliver(h.spell('strike',[fx('harm',['delay']),fx('pull')]),null,2,0);
c.enemy_interrupt_charge(e,'stun');h.tick(60);assert.ok(e.pull);
// Ordinary enemies and the independent Pull-immunity flag keep their existing behavior.
h=setup();c=h.ctx;e=h.enemy(3,0,{is_pull_immune:false,image_xscale:1,image_yscale:1});
assert.equal(c.enemy_can_be_displaced(e),true);c.enemy_begin_pull(e,0,0,0,24,12);assert.ok(e.pull);
const original=e.pull;c.enemy_begin_pull(e,50,50,0,24,12);assert.equal(e.pull,original);
e=h.enemy(3,0,{is_pull_immune:true});c.enemy_begin_pull(e,0,0,0,24,12);assert.equal(e.pull,undefined);
console.log('Siege displacement checks passed: charge immunity, impact/stun/barricade release, effect ordering, rejected stun, delayed activation and existing Pull rules.');
