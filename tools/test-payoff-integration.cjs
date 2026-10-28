const assert=require('node:assert/strict');
const {makePayoffContext}=require('./payoff-test-context.cjs');
const {read,load}=require('./gml-test-utils.cjs');
const fx=(effect,mods=[])=>({effect,mods});
for(const form of ['projectile','strike','rune','beam']) {
    const h=makePayoffContext(),c=h.ctx,e=h.enemy(2,0,{dmg_reduction:0});
    const s=h.spell(form,[fx('ice'),fx('snap'),fx('fire'),fx('combust')]);
    c.spell_deliver(s,form==='strike'||form==='rune'?null:e,2,0);
    const scale=form==='beam'?0.25:1;
    assert.equal(e.hp,100000-(120+100)*scale);assert.equal(e.frost_stacks,0);assert.equal(e.burn_timer,180);
}
// Repeated status/consumer pairs separated by Delay use the same scheduler and independent segments.
let h=makePayoffContext(),c=h.ctx,e=h.enemy(2,0,{dmg_reduction:0});
c.spell_deliver(h.spell('projectile',[fx('ice'),fx('snap',['delay']),fx('ice'),fx('snap')]),e,2,0);
assert.equal(e.hp,99880);h.tick(59);assert.equal(e.hp,99880);h.tick();assert.equal(e.hp,99760);
// Zero-duration Delay still separates Combust attribution, even though both effects run on the same frame.
h=makePayoffContext();c=h.ctx;c.tune_params=(_,id,key,value)=>id==='delay'?0:value;e=h.enemy(2,0,{hp:150,dmg_reduction:0,burn_timer:180});
let neighbor=h.enemy(3,0,{dmg_reduction:0});c.spell_deliver(h.spell('projectile',[fx('combust',['delay']),fx('harm')]),e,2,0);assert.equal(neighbor.hp,100000);
// A burst has its own damage accounting, not the root cast's contact deduplication.
h=makePayoffContext();c=h.ctx;e=h.enemy(2,0,{hp:50,dmg_reduction:0,burn_timer:180});neighbor=h.enemy(3,0,{hp:250,dmg_reduction:0,burn_timer:180});
c.spell_deliver(h.spell('strike',[fx('harm'),fx('combust')],['area']),null,2,0,1);
assert.ok(e.hp<=0&&neighbor.hp<=0);assert.equal(neighbor.burn_timer,180);
// A pile retains exact Frost count; Snap consumes it and it is absent in subsequent snapshots.
h=makePayoffContext();c=h.ctx;e=h.enemy(2,0,{dmg_reduction:0});
for(let i=0;i<3;i++)c.combat_status_apply(e,'frost',180,0.2);
const saved=c.combat_status_capture(e),pile=h.enemy(2,0,{dmg_reduction:0,is_bonepile:true});
c.combat_status_restore(pile,saved);c.spell_deliver(h.spell('projectile',[fx('snap')]),pile,2,0);
assert.equal(pile.hp,99640);assert.equal(c.combat_status_capture(pile).frost_stacks,0);
// Captured Combust tuning governs explosions and fresh Burn, not later global edits.
h=makePayoffContext();c=h.ctx;c.tune_params=(_,id,key,value)=>id==='combust'?({damage_mult:2,explosion_damage_mult:3,burn_damage_mult:0.7,burn_duration:5}[key]??value):value;
const delayed=h.spell('projectile',[fx('harm',['delay']),fx('combust')]);
e=h.enemy(2,0,{hp:250,dmg_reduction:0,burn_timer:180});neighbor=h.enemy(3,0,{dmg_reduction:0});
c.tune_params=(_,id,key,value)=>value;c.spell_deliver(delayed,e,2,0);h.tick(60);
assert.equal(neighbor.hp,99700);assert.equal(neighbor.burn_dmg,70);assert.equal(neighbor.burn_timer,300);
// Modifier compatibility is shared by editing, Start and casting.
for(const id of ['snap','combust','discharge']) {
    assert.equal(c.mod_valid_for_effect('amplify',id),true);
    assert.equal(c.mod_valid_for_effect('delay',id),true);
    assert.equal(c.mod_valid_for_effect('extend_time',id),false);
    assert.equal(c.mod_valid_for_effect('area',id),id!=='snap');
}
// Malformed new tuning is rejected during compilation rather than during a reaction.
for(const [id,key,value]of [['snap','damage_per_stack_mult',-1],['combust','burn_duration',-1],['combust','radius_tiles',1.5],['discharge','max_hits_per_enemy',0],['discharge','damage_mult','bad']]) {
    c.tune_params=(_,effect,param,fallback)=>effect===id&&param===key?value:fallback;
    assert.throws(()=>c.compile_spell({form:'projectile',form_mods:[],effects:[fx(id)]}));
}
// Progression and unlock previews work with the new temporary text-only icons.
const levels=JSON.parse(read('datafiles/level.json'));
for(const [n,id]of [[3,'combust'],[4,'snap'],[7,'discharge']])assert.ok(levels[`rm_level_${n}`].unlocked_glyphs.some(g=>g.type==='effect'&&g.id===id));
c.global.level_config=levels;c.room_exists=()=>true;c.room_get_name=x=>x;
for(const id of ['snap','combust','discharge'])Object.assign(c.global.spell_glyphs.effect[id],{name:id,icon:undefined});
load(c,'scripts/GameplayScripts/GameplayScripts.gml',['handle_next_level_glyphs']);
assert.ok(Array.from(c.handle_next_level_glyphs('rm_level_3',false)).includes('combust'));
console.log('Payoff integration passed: all Forms, status/effect ordering, Delay boundaries, area overlap, skeletal transfer, captured tuning, compatibility, validation and unlock previews.');
