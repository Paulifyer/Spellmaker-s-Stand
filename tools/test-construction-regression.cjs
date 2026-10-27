const assert = require('node:assert/strict');
const vm = require('node:vm');
const {read, extract} = require('./gml-test-utils.cjs');
const {makeContext} = require('./construction-test-context.cjs');
const ctx=makeContext();
const fresh=()=>({form:'projectile',form_mods:[],effects:[]});
const draft=JSON.parse(read('notes/level-campaign.draft.json'));
for (let n=1;n<=8;n++) {
    const limit=draft[`rm_level_${n}`].max_glyphs;
    ctx.global.level_config.rm_test.max_glyphs=limit;
    const s=fresh();
    assert.equal(ctx.spell_add_glyph(s,'effect','harm',-1),'');
    while (ctx.spell_glyph_count(s)<limit) assert.equal(ctx.spell_add_glyph(s,'modifier','amplify',0),'');
    assert.equal(ctx.spell_glyph_count(s),limit);
    assert.equal(ctx.is_spell_usable(s),true);
    const before=JSON.stringify(s);
    assert.match(ctx.spell_add_glyph(s,'modifier','amplify',0),/limit/);
    assert.equal(JSON.stringify(s),before);
    s.effects[0].mods.pop(); // removal always repairs a spell
    if (limit>2) assert.equal(ctx.spell_add_glyph(s,'modifier','amplify',0),'');
}
ctx.global.level_config.rm_test.max_glyphs=8;
const delayed=fresh();
for (const [type,id,index] of [['effect','harm',-1],['modifier','delay',0],['effect','harm',-1],['modifier','extend_time',1]]) {
    const message=ctx.spell_add_glyph(delayed,type,id,index);
    if (id==='extend_time') assert.match(message,/Effect/); else assert.equal(message,'');
}
assert.equal(ctx.is_spell_usable(delayed),true);
assert.equal(ctx.spell_sequence_valid(delayed,-1,0,0),false);
const hex=fresh();ctx.spell_add_glyph(hex,'effect','hex',-1);
assert.equal(ctx.spell_add_glyph(hex,'modifier','extend_time',0),'');
assert.equal(ctx.is_spell_usable(hex),true);
ctx.is_glyph_available=(type,id)=>id!=='hex';
assert.equal(ctx.is_spell_usable(hex),false);
ctx.is_glyph_available=()=>true;

// Actual cast guard must reject invalid stored spells before spending mana or spawning.
Object.assign(ctx,{noone:null,Form_Beam:function(){},ROWS_PER_LANE:1});
const cast=extract(read('scripts/SpellCatalogScripts/SpellCatalogScripts.gml'),'cast_spell')
    .replace('_row div ROWS_PER_LANE','Math.floor(_row / ROWS_PER_LANE)')
    .replace('_existing.lane = _lane','_existing.lane == _lane');
vm.runInContext(cast,ctx);
const invalid=[fresh(),{form:'projectile',form_mods:[],effects:[{effect:'none',mods:[]}]},
    {form:'strike',form_mods:['pierce'],effects:[{effect:'harm',mods:[]}]},
    {form:'projectile',form_mods:[],effects:[{effect:'harm',mods:Array(7).fill('amplify')}]}
];
for (const s of invalid) {
    const caster={mana:100,mana_exhausted:false};
    assert.equal(ctx.cast_spell(caster,s,0,0).spell,null);
    assert.equal(caster.mana,100);
}
console.log('Construction regression checks passed across all eight documented limits, retained spells, Delay, Hex and cast rejection.');
