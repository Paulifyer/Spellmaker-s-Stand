const assert=require('node:assert/strict');
const {makeExecutionContext}=require('./execution-test-context.cjs');
const runContracts=require('./spell-execution-contracts.cjs');
const fx=(effect,mods=[])=>({effect,mods});
runContracts({
    strikePullHarm(delayed){
        const h=makeExecutionContext();const e=h.enemy(3);const order=[];
        const s=h.spell('strike',[fx('pull',delayed?['delay']:[]),fx('harm')]);
        const execute=h.ctx.combat_execute_event;
        h.ctx.combat_execute_event=event=>{order.push(event.fx.id);execute(event);};
        h.ctx.spell_deliver(s,null,2,0);const initial=e.hp;const immediate=100000-e.hp;
        h.finishPull(e);h.tick(60);
        return {immediate,later:(initial-e.hp)/100,order};
    },
    areaReselect(form){
        const h=makeExecutionContext();const e=h.enemy(4);
        const s=h.spell(form,[fx('fire',['delay']),fx('harm')],form==='projectile'?['area']:[]);
        h.ctx.spell_deliver(s,null,2,0,form==='projectile'?1:0);e.x=250;h.tick(60);return e.hp===99900;
    },
    directFollowsLineage(){
        const h=makeExecutionContext();const e=h.enemy();const s=h.spell('projectile',[fx('fire',['delay']),fx('harm')]);
        h.ctx.spell_deliver(s,e,2,0);const line=e.combat_lineage;line.gap=true;line.target=null;e.destroyed=true;
        h.tick(60);assert.equal(h.ctx.manager.combat_execution.events.length,1);
        const pile=h.enemy(8);h.ctx.enemy_bind_lineage(pile,line);h.ctx.combat_flush_lineage(line);
        return pile.hp===99900&&h.ctx.manager.combat_execution.events.length===0;
    },
    beamTicksRemainIndependent(){
        const h=makeExecutionContext();const e=h.enemy();const s=h.spell('beam',[fx('fire',['delay']),fx('harm')]);
        h.ctx.spell_deliver(s,e,2,0);h.tick(15);s.hit_state.contacts=[];s.hit_state.epoch++;
        h.ctx.spell_deliver(s,e,2,0);h.tick(45);assert.equal(e.hp,99975);h.tick(15);return e.hp===99950;
    },
    pauseAndRoomReset(){
        const h=makeExecutionContext();const e=h.enemy();const s=h.spell('strike',[fx('fire',['delay']),fx('harm')]);
        h.ctx.spell_deliver(s,null,2,0);h.tick(60,true);assert.equal(h.ctx.manager.combat_execution.clock,0);
        h.ctx.manager.combat_execution=h.ctx.combat_execution_create();h.tick(60);return e.hp===100000;
    },
    equalTimeOrder(){
        const h=makeExecutionContext();const e=h.enemy();const s=h.spell('projectile',[fx('fire',['delay']),fx('ice'),fx('hex')]);
        h.ctx.spell_deliver(s,e,2,0);h.log.length=0;h.tick(60);return h.log.join(',')==='ice,hex';
    }
});
// Immediate location and entity effects share written order in both directions.
for(const order of [['harm','pull'],['pull','harm']]){
    const h=makeExecutionContext();h.enemy();const s=h.spell('strike',order.map(e=>fx(e)));
    h.ctx.spell_deliver(s,null,2,0);assert.deepEqual(h.log,order);
}
// Permanent death cancels following work; a destroyed delivery object does not.
{
    const h=makeExecutionContext();const e=h.enemy();const s=h.spell('projectile',[fx('fire',['delay']),fx('harm')]);
    h.ctx.spell_deliver(s,e,2,0);h.ctx.instance_destroy(e);h.ctx.instance_destroy(s);h.tick(60);
    assert.equal(h.ctx.manager.combat_execution.events.length,0);
}
console.log('Execution contracts passed: ordered effects, delayed reselection, lineage, Beam ticks, pause/reset and cancellation.');
// Already-due work precedes an instant delivery created later on the same frame.
// A consumed Rune can hit a new entrant later, without following its original victim.
{
    const h=makeExecutionContext();const original=h.enemy();const newcomer=h.enemy(4);
    const s=h.spell('rune',[fx('fire',['delay']),fx('harm')]);
    Object.assign(s,{armed:true,lane:0,charges:1});h.ctx.forms.rune.on_hit(s,original);
    assert.equal(s.destroyed,true);original.x=850;newcomer.x=250;h.tick(60);
    assert.equal(original.hp,100000);assert.equal(newcomer.hp,99900);
}
// Captured tuning remains valid after the delivery instance disappears.
{
    const h=makeExecutionContext();const e=h.enemy();const s=h.spell('projectile',[fx('fire',['delay']),fx('harm')]);
    h.ctx.spell_deliver(s,e,2,0);h.ctx.instance_destroy(s);h.ctx.tune_value=()=>999;h.tick(60);
    assert.equal(e.hp,99900);
}
// Already-due work precedes an instant delivery created later on the same frame.
{
    const h=makeExecutionContext();const e=h.enemy();
    h.ctx.spell_deliver(h.spell('projectile',[fx('fire',['delay']),fx('ice')]),e,2,0);
    h.ctx.manager.combat_execution.clock=60;h.log.length=0;
    h.ctx.spell_deliver(h.spell('strike',[fx('hex')]),null,2,0);
    assert.deepEqual(h.log,['ice','hex']);
}
// Old Beam applications do not reserve contacts in a newer epoch.
{
    const h=makeExecutionContext();const e=h.enemy();const s=h.spell('beam',[fx('fire',['delay']),fx('harm')]);
    h.ctx.spell_deliver(s,e,2,0);s.hit_state.contacts=[];s.hit_state.epoch++;
    h.tick(60);assert.equal(s.hit_state.contacts.length,0);
    assert.equal(h.ctx.spell_deliver(s,e,2,0),true);
}
