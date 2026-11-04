const assert = require('node:assert/strict');
const vm = require('node:vm');
const {load, read} = require('./gml-test-utils.cjs');
const sprites = {};
for (const name of ['spr_discharge','spr_combust']) {
    sprites[name] = JSON.parse(read(`sprites/${name}/${name}.yy`).replace(/,\s*([}\]])/g,'$1'));
}
for (const kind of ['discharge','combust']) for (const count of [0,1,3]) {
    const calls = [];
    const c = vm.createContext({
        spr_discharge:'spr_discharge',spr_combust:'spr_combust',
        sprite_get_bbox_left:s=>sprites[s].bbox_left,
        sprite_get_bbox_right:s=>sprites[s].bbox_right,
        sprite_get_bbox_top:s=>sprites[s].bbox_top,
        sprite_get_bbox_bottom:s=>sprites[s].bbox_bottom,
        sprite_get_xoffset:s=>sprites[s].sequence.xorigin,
        sprite_get_yoffset:s=>sprites[s].sequence.yorigin,
        array_length:a=>a.length,instance_exists:()=>true,
        combat_status_consume_charge:()=>{},
        spell_reaction_targets:()=>Array.from({length:count},()=>({hp:100})),
        spell_reaction_claim_hit:()=>true,spell_discharge_enqueue:()=>{},
        spell_direct_damage:()=>{},combat_status_apply:()=>{},spell_damage_scale:()=>1,
        combat_spawn_vfx:(...args)=>calls.push(args),TARGET_ROOM_SPEED:60
    });
    load(c,'scripts/SpellExecution/SpellExecution.gml',['spell_drain_bursts']);
    c.spell_drain_bursts({}, {processing:false,cursor:0,queue:[{kind,x:500,y:300,source:{},fx:{params:{},effect_multiplier:1}}]});
    assert.equal(calls.length,1,'One visual per emitter, regardless of victim count');
    const [sprite,x,y] = calls[0], s = sprites[sprite];
    assert.equal(x+(s.bbox_left+s.bbox_right)/2-s.sequence.xorigin,500);
    assert.equal(y+(s.bbox_top+s.bbox_bottom)/2-s.sequence.yorigin,300);
}
console.log('Burst visual checks passed: centered artwork and one visual per Combust/Discharge emission.');
