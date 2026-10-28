const assert=require('node:assert/strict');
const {makePayoffContext}=require('./payoff-test-context.cjs');
const {load,read}=require('./gml-test-utils.cjs');
const fx=(effect='harm',mods=[])=>({effect,mods});
// Every Form reuses the same effect sequence and only its own original damage scaling.
for(const form of ['projectile','strike','rune','beam']) {
    const h=makePayoffContext(),c=h.ctx,a=h.enemy(2,0,{dmg_reduction:0}),b=h.enemy(3,0,{dmg_reduction:0});
    const s=h.spell(form,[fx('ice'),fx('snap'),fx('fire'),fx('combust')],['chain']);
    c.spell_deliver(s,form==='strike'||form==='rune'?null:a,2,0);
    const scale=form==='beam'?0.25:1;
    for(const e of [a,b]){assert.equal(e.hp,100000-220*scale);assert.equal(e.frost_stacks,0);assert.equal(e.burn_timer,180);}
}
// Beam's widened primary lanes stay intact; its chained AoE is a local burst around each hop.
let h=makePayoffContext(),c=h.ctx,s=h.spell('beam',[fx()],['area','chain']);
Object.assign(s,{tick:0,lane:0,beam_lanes:[]});let root=h.enemy(2,0,{dmg_reduction:0});
const hop=h.enemy(2,2,{dmg_reduction:0}),splash=h.enemy(3,2,{dmg_reduction:0});
c.forms.beam.on_step(s);assert.equal(root.hp,99975);assert.equal(hop.hp,99975);assert.equal(splash.hp,99975);
assert.equal(c.manager.combat_execution.chain_links.length,1);
// Delayed location effects reselect at their own chained anchor; direct ones follow lineage.
h=makePayoffContext();c=h.ctx;root=h.enemy(2,0,{dmg_reduction:0});let victim=h.enemy(3,0,{dmg_reduction:0});
s=h.spell('strike',[fx('fire',['delay']),fx()],['chain']);c.spell_deliver(s,null,2,0);victim.x=850;
h.tick(60);assert.equal(root.hp,99900);assert.equal(victim.hp,100000);
h=makePayoffContext();c=h.ctx;root=h.enemy(2,0,{dmg_reduction:0});victim=h.enemy(3,0,{dmg_reduction:0});
s=h.spell('projectile',[fx('fire',['delay']),fx()],['chain']);c.spell_deliver(s,root,2,0);victim.x=850;
h.tick(60);assert.equal(victim.hp,99900);
// Combust scopes and overlapping chain areas still explode qualifying lineages only once.
h=makePayoffContext();c=h.ctx;root=h.enemy(2,0,{hp:50,dmg_reduction:0,burn_timer:180});
const neighbor=h.enemy(3,0,{hp:250,dmg_reduction:0,burn_timer:180}),tail=h.enemy(4,0,{dmg_reduction:0});
s=h.spell('projectile',[fx(),fx('combust')],['chain']);c.spell_deliver(s,root,2,0);
assert.ok(root.hp<=0&&neighbor.hp<=0);assert.ok(tail.hp<100000);
// Captured tuning governs a cast even if the global configuration later changes.
h=makePayoffContext();c=h.ctx;s=h.spell('projectile',[fx()],['chain','chain']);
assert.equal(s.compiled.chain_hops,4);assert.equal(s.compiled.form_modifier_penalty,0);
c.tune_params=(g,id,key,v)=>id==='chain'?0:v;root=h.enemy(2,0,{dmg_reduction:0});
const targets=[h.enemy(3,0,{dmg_reduction:0}),h.enemy(4,0,{dmg_reduction:0}),h.enemy(5,0,{dmg_reduction:0}),h.enemy(6,0,{dmg_reduction:0})];
c.spell_deliver(s,root,2,0);assert.ok(targets.every(e=>e.hp===99900));
// A new cast has fresh contact/chain state; an empty initial tile has no fabricated root.
const second=h.spell('projectile',[fx()],[]);c.spell_deliver(second,root,2,0);assert.equal(root.hp,99800);
h=makePayoffContext();c=h.ctx;s=h.spell('strike',[fx()],['chain']);victim=h.enemy(4,0,{dmg_reduction:0});
c.spell_deliver(s,null,2,0);assert.equal(victim.hp,100000);assert.equal(c.manager.combat_execution.chain_links.length,0);
for(const [key,value]of [['hops_per_stack',-1],['hops_per_stack',1.5],['range_radius_tiles',-1],['range_radius_tiles',2.5],['visual_duration',-1]]) {
    c.tune_params=(g,id,param,v)=>id==='chain'&&param===key?value:v;
    assert.throws(()=>h.spell('projectile',[fx()],['chain']));
}
// Real numeric/array JSON settings are read correctly and costs use the configured normal glyph prices.
const tuning=JSON.parse(read('datafiles/tune.json'));c.global.tuning=tuning;
load(c,'scripts/TuneScript/TuneScript.gml',['tune_setting','tune_params','tune_value']);
for(const id of ['projectile'])c.global.spell_glyphs.form[id].cost=tuning.forms[id].cost;
c.global.spell_glyphs.effect.harm.cost=tuning.effects.harm.cost;
for(const id of ['pierce','chain','area'])c.global.spell_glyphs.modifier[id].cost=tuning.modifiers[id].cost;
const priced=h.spell('projectile',[fx()],['pierce','chain','area']);
assert.equal(priced.compiled.cost,15+10+15+20+25+30);
assert.equal(priced.compiled.form_modifier_penalty,30);
const pricedLoadout={form:'projectile',form_mods:['pierce','chain','area'],effects:[fx()]};
const caster={mana:114,mana_exhausted:false,x:0,y:0};
c.instance_create_layer=(x,y,layer,obj,properties)=>properties;
assert.equal(c.cast_spell(caster,pricedLoadout,2,0).spell,null);assert.equal(caster.mana,114);
caster.mana=115;assert.notEqual(c.cast_spell(caster,pricedLoadout,2,0).spell,null);assert.equal(caster.mana,0);assert.equal(caster.mana_exhausted,true);
// Colour helper is exactly the former ordered half-blend, shared by actual casts and native tests.
const mixes=[];c.c_white=99;c.merge_colour=(a,b,t)=>{mixes.push([a,b,t]);return a+b;};
load(c,'scripts/SpellCatalogScripts/SpellCatalogScripts.gml',['spell_effect_colour']);
assert.equal(c.spell_effect_colour([]),99);
assert.equal(c.spell_effect_colour([{effect:{col:1}},{effect:{col:2}},{effect:{col:4}}]),7);
assert.deepEqual(mixes,[[1,2,0.5],[3,4,0.5]]);
assert.ok(JSON.parse(read('datafiles/level.json')).rm_level_5.unlocked_glyphs.some(g=>g.type==='modifier'&&g.id==='chain'));
console.log('Chain integration passed: all Forms, Beam AoE, delayed anchors/lineage, payoff interactions, captured tuning, empty roots, real JSON costs, colour blending and unlocks.');
