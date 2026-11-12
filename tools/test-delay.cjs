const assert=require('node:assert/strict');
const {makeExecutionContext}=require('./execution-test-context.cjs');
const fx=(effect,mods=[])=>({effect,mods});
const h=makeExecutionContext();
const s=h.spell('projectile',[fx('fire',['delay']),fx('ice',['delay']),fx('harm')]);
assert.deepEqual(Array.from(s.effects,e=>e.delay),[0,1,2]);
const e=h.enemy();h.ctx.spell_deliver(s,e,2,0);
assert.deepEqual(h.log,['fire']);h.tick(59);assert.deepEqual(h.log,['fire']);
h.tick(1);assert.deepEqual(h.log,['fire','ice']);h.tick(60);
assert.deepEqual(h.log,['fire','ice','harm']);
assert.equal(h.ctx.manager.combat_execution.events.length,0);
const t=makeExecutionContext();const target=t.enemy();
const tied=t.spell('projectile',[fx('fire',['delay']),fx('ice'),fx('hex')]);
t.ctx.spell_deliver(tied,target,2,0);t.log.length=0;t.tick(60);
assert.deepEqual(t.log,['ice','hex']);
const stacked=t.spell('projectile',[fx('fire',['delay','delay']),fx('harm')]);
assert.equal(stacked.effects[1].delay,2);
assert.equal(stacked.compiled.cost,t.ctx.spell_cost({form:'projectile',form_mods:[],effects:[fx('fire',['delay','delay']),fx('harm')]}));
const paused=makeExecutionContext();const p=paused.enemy();
paused.ctx.spell_deliver(paused.spell('projectile',[fx('fire',['delay']),fx('harm')]),p,2,0);
paused.tick(100,true);assert.equal(p.hp,100000);paused.tick(60);assert.equal(p.hp,99900);
const spell={form:'projectile',form_mods:[],effects:[fx('harm')]};
assert.notEqual(t.ctx.spell_add_glyph(spell,'effect','harm',-1),'');
assert.equal(t.ctx.spell_add_glyph(spell,'modifier','delay',0),'');
assert.equal(t.ctx.spell_add_glyph(spell,'effect','harm',-1),'');
assert.equal(t.ctx.spell_sequence_valid(spell,-1,0,0),false);

for (const follow of [false, true]) {
    const h=makeExecutionContext();
    h.ctx.tune_setting=(group,id,key,fallback)=>
        group==='modifiers'&&id==='delay'&&key==='follow_original_targets'?follow:fallback;
    const original=h.enemy(2), splash=h.enemy(3,1), newcomer=h.enemy(5), dead=h.enemy(2);
    const s=h.spell('strike',[fx('fire',['delay']),fx('harm')],['area']);
    h.ctx.spell_deliver(s,null,2,0,1);
    original.x=850; original.lane=2; splash.x=950; newcomer.x=250;
    h.ctx.instance_destroy(dead);
    h.tick(60);
    assert.deepEqual([original.hp,splash.hp,newcomer.hp,dead.hp],
        follow?[99900,99900,100000,100000]:[100000,100000,99900,100000]);
}

{
    const h=makeExecutionContext();
    h.ctx.tune_setting=(group,id,key,fallback)=>key==='follow_original_targets'?true:fallback;
    const original=h.enemy(2), newcomer=h.enemy(6);
    const s=h.spell('strike',[fx('fire',['delay']),fx('pull')]);
    h.ctx.spell_deliver(s,null,2,0);
    original.x=850; newcomer.x=250;
    h.tick(60);
    assert.equal(original.pull,undefined);
    assert.equal(newcomer.pull.tx,250);
}

console.log('Delay checks passed: timing, order, pause, cost, repetition, original targets and location effects.');
