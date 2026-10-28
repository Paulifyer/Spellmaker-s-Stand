const assert=require('node:assert/strict');
const vm=require('node:vm');
const {read}=require('./gml-test-utils.cjs');
const {makeContext}=require('./construction-test-context.cjs');
const tuning=JSON.parse(read('datafiles/tune.json'));
function context() {
    const c=makeContext(20);
    c.tune_params=(group,id,key,fallback)=>tuning[group]?.[id]?.[key]??fallback;
    c.tune_setting=c.tune_params;
    return c;
}
const fx=(effect,mods=[])=>({effect,mods});
const spell=effects=>({form:'projectile',form_mods:[],effects});
const c=context();
assert.equal(c.compile_spell(spell([fx('harm')])).cooldown_penalty,0);
for(const [id,value] of [['pull',5],['hex',3],['discharge',2]])
    assert.equal(c.compile_spell(spell([fx(id)])).cooldown_penalty,value);
const plan=c.compile_spell(spell([fx('pull',['delay']),fx('pull'),fx('hex',['extend_time']),fx('discharge',['amplify'])]));
assert.equal(plan.cooldown_penalty,15);
const original=tuning.effects.pull.cooldown_penalty;
tuning.effects.pull.cooldown_penalty=7;
assert.equal(c.compile_spell(spell([fx('pull')])).cooldown_penalty,7);
assert.equal(plan.cooldown_penalty,15); // Existing casts retain their compiled settings.
for(const invalid of [-1,'5']) {
    tuning.effects.pull.cooldown_penalty=invalid;
    assert.throws(()=>c.compile_spell(spell([fx('pull')])),/cooldown_penalty/);
}
delete tuning.effects.pull.cooldown_penalty;
assert.equal(c.compile_spell(spell([fx('pull')])).cooldown_penalty,0);
tuning.effects.pull.cooldown_penalty=original;

const step=read('objects/Player/Step_0.gml').replace(/\[\$\s*([^\]]+)\]/g,'[$1]');
function harness(channelled=false,penalty=8,success=true,override=0.4) {
    const c=context();
    c.global.menu_lock=false;c.global.tuning={player:{spell_cd_by_slot:[override]}};
    c.global.spellbook=[spell([fx('pull'),fx('hex')])];
    const pressed=new Set([49]),held=new Set([49]);
    const p={channel:null,channel_key:-1,channel_slot:-1,channel_cooldown_penalty:0,
        cast_flash_slot:-1,cast_flash_ticks:0,cost:0,mana:100,max_mana:100,mana_ticks:6,
        mana_regen_rate:0.5,mana_exhausted:false,mana_exhausted_regen_multiplier:8,
        spell_cooldowns:[0,0,0,0],spell_cooldown_max:[0,0,0,0]};p.id=p;
    Object.assign(c,{p,mouse_x:0,mouse_y:0,obj_spellbook:'editor',noone:null,SPELL_CD:0.8,vk_space:32,vk_numpad1:97,
        window_has_focus:()=>true,instance_exists:o=>!!o&&typeof o==='object'&&!o.destroyed,
        keyboard_check_pressed:k=>pressed.has(k),keyboard_check:k=>held.has(k),ord:s=>s.charCodeAt(0),
        world_to_grid:()=>({col:2,row:0}),
        cast_spell:()=>({spell:success?{form:{is_channel:channelled},compiled:{cooldown_penalty:penalty}}:null,cost:15}),
        instance_destroy:o=>{o.destroyed=true;}});
    return {c,p,pressed,held,run:()=>vm.runInContext(`(function(){with(p){${step}}})()`,c)};
}
let h=harness();h.run();
assert.equal(h.p.spell_cooldowns[0],504);assert.equal(h.p.spell_cooldown_max[0],504);
assert.equal(h.p.spell_cooldowns[1],0);
h=harness(false,8,true,undefined);h.c.global.tuning.player.spell_cd_by_slot=[];h.run();
assert.equal(h.p.spell_cooldowns[0],528); // 0.8s fallback + 8s penalty.
h=harness(false,8,false);h.run();assert.equal(h.p.spell_cooldowns[0],0);
for(const ending of ['release','destroyed','mana','menu']) {
    h=harness(true);h.run();
    assert.equal(h.p.channel_cooldown_penalty,8);assert.equal(h.p.spell_cooldowns[0],0);
    h.pressed.clear();
    if(ending==='release') h.held.clear();
    if(ending==='destroyed') h.p.channel.destroyed=true;
    if(ending==='mana') h.p.mana=0;
    if(ending==='menu') h.c.global.menu_lock=true;
    h.run();
    assert.equal(h.p.channel,null);assert.equal(h.p.spell_cooldowns[0],504);
    assert.equal(h.p.spell_cooldown_max[0],504);assert.equal(h.p.channel_cooldown_penalty,0);
}
console.log('Cooldown penalty checks passed: tuning, repeated effects, snapshots, validation, slot overrides, failed casts and channel endings.');
