const assert=require('node:assert/strict');
const {makeContext}=require('./construction-test-context.cjs');
const {load,read}=require('./gml-test-utils.cjs');
const c=makeContext();
for(const [ids,expected]of [[[],0],[['pierce','pierce','pierce'],0],[['pierce','chain'],10],[['pierce','chain','area'],30],[['pierce','pierce','chain'],20],[['pierce','pierce','chain','chain'],40],[['pierce','unlisted'],0]]) {
    assert.equal(c.spell_form_modifier_penalty(ids),expected);
    assert.equal(c.spell_form_modifier_penalty([...ids].reverse()),expected);
}
const loadout={form:'projectile',form_mods:['pierce','area'],effects:[{effect:'combust',mods:['area','amplify','amplify']}]};
const plan=c.compile_spell(loadout);
assert.equal(plan.form_modifier_penalty,10);
const normal=5+5+5+10+5+5+10; // fixture costs, including Amplify's existing second-stack surcharge
assert.equal(plan.cost,normal+10);
assert.equal(c.spell_mana_preview(loadout,plan.cost-1).too_expensive,true);
c.global.spellbook=[loadout];assert.match(c.spellbook_start_message(plan.cost-1),/expensive/);
c.tune_params=(group,id,key,value)=>id==='interaction_penalty'?({cost_per_pair:7,penalized_modifiers:['pierce','future']}[key]??value):value;
assert.equal(c.spell_form_modifier_penalty(['pierce','area','chain']),0);
assert.equal(c.spell_form_modifier_penalty(['pierce','future','future']),14);
for(const [key,value]of [['cost_per_pair',-1],['cost_per_pair','10'],['penalized_modifiers',{}],['penalized_modifiers',['pierce','pierce']],['penalized_modifiers',[5]]]) {
    c.tune_params=(group,id,param,fallback)=>id==='interaction_penalty'&&param===key?value:fallback;
    assert.throws(()=>c.spell_form_modifier_penalty(['pierce','area']));
}
c.global.tuning={modifiers:{interaction_penalty:{cost_per_pair:3,penalized_modifiers:['pierce','chain']}}};
load(c,'scripts/TuneScript/TuneScript.gml',['tune_setting']);
assert.equal(c.spell_form_modifier_penalty(['pierce','chain','area']),3);
c.global.tuning.modifiers.interaction_penalty.penalized_modifiers=[];
assert.equal(c.spell_form_modifier_penalty(['pierce','chain']),0);

c.global.tuning=JSON.parse(read('datafiles/tune.json'));
load(c,'scripts/TuneScript/TuneScript.gml',['tune_params']);
const stacked={
    form:'projectile',
    form_mods:['chain','pierce','chain','pierce','chain'],
    effects:[
        {effect:'fire',mods:['extend_time','extend_time','delay','delay']},
        {effect:'ice',mods:['extend_time','delay']},
    ],
};
const base=c.compile_spell(stacked);
const increases={chain:6,pierce:4,extend_time:3,delay:2};
for(const [id,increase] of Object.entries(increases)) {
    c.global.tuning.modifiers[id].cost_increase_per_stack=increase;
}
const tuned=c.compile_spell(stacked);
assert.equal(tuned.cost-base.cost,6+12+4+3+2);
assert.equal(tuned.form_modifier_penalty,base.form_modifier_penalty);
assert.equal(c.spell_mana_preview(stacked,tuned.cost).cost,tuned.cost);
console.log('Form interaction cost checks passed: explicit JSON list, cross-type stack pairs, order independence, Effect exclusion, shared cost/Start/preview and tunable validation.');
