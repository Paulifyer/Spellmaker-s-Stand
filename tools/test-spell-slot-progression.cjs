const assert=require('node:assert/strict');
const vm=require('node:vm');
const {read,load}=require('./gml-test-utils.cjs');
const {makeContext}=require('./construction-test-context.cjs');
const counts=[2,2,3,3,4,4,4,4];
const config=JSON.parse(read('datafiles/level.json'));
const draft=JSON.parse(read('notes/level-campaign.draft.json'));
for(const source of [config,draft])assert.deepEqual(counts.map((_,i)=>source[`rm_level_${i+1}`].spell_slots),counts);
const ctx=makeContext();
ctx.global.level_config=config;
ctx.global.level_array=counts.map((_,i)=>`rm_level_${i+1}`);
ctx.global.spellbook=Array(4).fill(undefined);
assert.match(read('scripts/SpellbookHelperScripts/SpellbookHelperScripts.gml'),/#macro SPELL_SLOTS 4\b/);
assert.match(read('objects/Player/Create_0.gml'),/spell_cooldowns = array_create\(SPELL_SLOTS, 0\)/);
assert.match(read('objects/Player/Create_0.gml'),/spell_cooldown_max = array_create\(SPELL_SLOTS, 0\)/);
for(let n=1;n<=8;n++) {
    ctx.room=`rm_level_${n}`;
    assert.equal(ctx.spell_slot_count(),counts[n-1]);
    for(let slot=0;slot<4;slot++)assert.equal(ctx.spell_slot_unlocked(slot),slot<counts[n-1]);
}
assert.equal(ctx.spell_slot_unlocked(-1),false);
assert.equal(ctx.spell_slot_unlocked(4),false);
assert.deepEqual([0,1,2,3].map(i=>ctx.spell_slot_unlock_level(i)),[1,1,3,5]);
ctx.room='rm_spell_interaction_test'; assert.equal(ctx.spell_slot_count(),4);
ctx.room='rm_level_1';
assert.equal(ctx.spell_ensure(2),undefined);assert.equal(ctx.global.spellbook[2],undefined);
ctx.room='rm_level_3';assert.equal(ctx.global.spellbook[2],undefined);
const third=ctx.spell_ensure(2);third.name='Retained third';
ctx.room='rm_level_5';assert.equal(ctx.global.spellbook[3],undefined);
const fourth=ctx.spell_ensure(3);fourth.name='Retained fourth';
ctx.room='rm_level_1';
assert.equal(ctx.spell_ensure(3),undefined);
assert.equal(ctx.global.spellbook[3],fourth);
ctx.room='rm_level_8';assert.equal(ctx.spell_ensure(2),third);assert.equal(ctx.spell_ensure(3),fourth);
// Locked invalid/expensive spells do not block Start; unlocking revalidates them.
ctx.global.level_config.rm_level_1.max_glyphs=8;
ctx.global.level_config.rm_level_5.max_glyphs=8;
ctx.global.spellbook=[undefined,undefined,
    {form:'projectile',form_mods:[],effects:[]},
    {form:'projectile',form_mods:[],effects:[{effect:'harm',mods:['amplify','amplify']}]}];
ctx.room='rm_level_1';assert.equal(ctx.spellbook_start_message(20),'');assert.equal(ctx.spellbook_expensive_slots(20),'');
ctx.room='rm_level_3';assert.match(ctx.spellbook_start_message(20),/Spell 3: Add an Effect/);
assert.doesNotMatch(ctx.spellbook_start_message(20),/Spell 4/);
ctx.room='rm_level_5';assert.match(ctx.spellbook_start_message(20),/Spell 4: Spell is too expensive/);
assert.equal(ctx.spellbook_expensive_slots(20),'4');
// Parse real JSON and reject missing, fractional, out-of-range and nonnumeric limits.
Object.assign(ctx,{
    floor:Math.floor,variable_global_exists:()=>true,
    EnemyWaveDefinition:function(){},LevelWaveConfig:function(){},
});
ctx.global.EnemyCatalog={MOOK:{},RANGER:{},BRUTE:{}};
load(ctx,'scripts/LevelScript/LevelScript.gml',['parse_level_data']);
assert.equal(ctx.parse_level_data(config.rm_level_1).spell_slots,2);
for(const value of [undefined,0,-1,5,2.5,'4',null]) {
    assert.throws(()=>ctx.parse_level_data({...config.rm_level_1,spell_slots:value}),e=>String(e).includes('spell_slots'));
}
for(const value of [1,2,3,4])assert.equal(ctx.parse_level_data({...config.rm_level_1,spell_slots:value}).spell_slots,value);

// Run actual Player Step input/channel lifecycle with engine calls mocked.
const step=read('objects/Player/Step_0.gml').replace(/\[\$\s*([^\]]+)\]/g,'[$1]');
function playerHarness(count,key,channelled=false,slotCooldowns=[0.4,0.4,0.4]) {
    const c=makeContext();c.global.level_config.rm_test.spell_slots=count;
    c.global.menu_lock=false;c.global.tuning={player:{spell_cd_by_slot:slotCooldowns}};
    c.global.spellbook=Array.from({length:4},(_,i)=>({name:`Slot ${i+1}`,form:channelled?'beam':'projectile',form_mods:[],effects:[{effect:'harm',mods:[]}]}));
    const calls=[],pressed=new Set([key]),held=new Set([key]);
    const p={channel:null,channel_key:-1,channel_slot:-1,channel_cooldown_penalty:0,cast_flash_slot:-1,cast_flash_ticks:0,
        cost:0,mana:100,max_mana:100,mana_ticks:6,mana_regen_rate:0.5,mana_exhausted:false,mana_exhausted_regen_multiplier:8,
        spell_cooldowns:[0,0,0,0],spell_cooldown_max:[0,0,0,0]};p.id=p;
    Object.assign(c,{p,mouse_x:0,mouse_y:0,obj_spellbook:'editor',noone:null,SPELL_CD:0.8,vk_space:32,vk_numpad1:97,
        window_has_focus:()=>true,instance_exists:o=>!!o&&typeof o==='object'&&!o.destroyed,
        keyboard_check_pressed:k=>pressed.has(k),keyboard_check:k=>held.has(k),ord:s=>s.charCodeAt(0),
        world_to_grid:()=>({col:2,row:0}),max:Math.max,round:Math.round,is_array:Array.isArray,
        cast_spell:(caster,spell)=>{calls.push(spell);return {spell:{form:{is_channel:channelled},compiled:{cooldown_penalty:0}},cost:15};},
        instance_destroy:o=>{o.destroyed=true;},
    });
    const run=()=>vm.runInContext(`(function(){with(p){${step}}})()`,c);
    return {c,p,calls,pressed,held,run};
}
for(const count of [2,3,4])for(const key of [52,100]) {
    const h=playerHarness(count,key);h.run();
    assert.equal(h.calls.length,count===4?1:0);
    if(count===4) {
        assert.equal(h.calls[0],h.c.global.spellbook[3]);assert.equal(h.p.cast_flash_slot,3);
        assert.equal(h.p.spell_cooldowns[3],48); // missing override uses existing 0.8s default
        h.run();assert.equal(h.calls.length,1); // cooldown prevents a second cast
    }
}
let h=playerHarness(4,52,false,[0.4,0.4,0.4,0.25]);h.run();assert.equal(h.p.spell_cooldowns[3],15);
for(const key of [52,100]) {
    h=playerHarness(4,key,true);h.run();assert.equal(h.p.channel_slot,3);assert.equal(h.p.channel_key,key);
    const channel=h.p.channel;
    h.pressed.clear();h.run();assert.equal(h.calls.length,1);assert.ok(h.p.mana<100);
    h.held.clear();h.run();assert.equal(channel.destroyed,true);assert.equal(h.p.channel,null);assert.equal(h.p.spell_cooldowns[3],48);
}
h=playerHarness(4,52,true);h.run();h.c.global.level_config.rm_test.spell_slots=2;h.run();assert.equal(h.p.channel,null);

// Render the actual HUD calls: only available keys are advertised, retained locked forms stay hidden.
for(const count of [2,3,4]) {
    h=playerHarness(count,52);
    const labels=[],noop=()=>{};
    Object.assign(h.c,{
        world_to_grid:()=>undefined,display_get_gui_height:()=>1080,
        lerp:(a,b,t)=>a+(b-a)*t,floor:Math.floor,
        c_black:0,c_aqua:1,c_white:2,c_gray:3,c_red:4,fa_center:1,fa_left:0,fnt_Arcane:1,current_time:0,
        draw_set_alpha:noop,draw_rectangle:noop,draw_set_colour:noop,draw_set_color:noop,
        draw_set_halign:noop,draw_set_font:noop,draw_text:(x,y,text)=>labels.push(String(text)),
        draw_text_ext:(x,y,text)=>labels.push(String(text)),
    });
    h.p.mana_display=100;
    const hud=read('objects/Player/Draw_64.gml').replace('current_time div 500','Math.floor(current_time / 500)').replace(/\bmod\b/g,'%');
    vm.runInContext(`(function(){with(p){${hud}}})()`,h.c);
    assert.ok(labels.includes(`Hover a tile + press ${Array.from({length:count},(_,i)=>i+1).join('/')} to cast`));
    assert.equal(labels.filter(x=>x==='Locked').length,4-count);
    assert.equal(labels.includes('4 Slot 4'),count===4);
}
console.log('Spell slot checks passed: eight-level JSON progression, parsing, locks, retained spells, Start validation, fourth-slot keys, cooldown overrides/defaults and channel release.');
