const assert=require('node:assert/strict');
const {makeContext}=require('./construction-test-context.cjs');
const ctx=makeContext(12);
const s={form:'projectile',form_mods:['area','pierce'],effects:[{effect:'fire',mods:['amplify','extend_time','delay']},{effect:'harm',mods:['amplify','amplify']}]};
const before=JSON.stringify(s);
const a=ctx.compile_spell(s),b=ctx.compile_spell(s);
assert.equal(a.cost,ctx.spell_cost(s));assert.equal(a.area,true);assert.equal(a.pierce,2);
assert.equal(a.effects[0].duration,15);assert.equal(a.effects[0].effect_multiplier,2); // 3s base * fallback increase of 5.
assert.equal(a.effects[1].delay,1);assert.equal(a.effects[1].effect_multiplier,3);
assert.equal(a.effects[0].target_policy,'area');
assert.notEqual(a,b);assert.notEqual(a.effects[0],b.effects[0]);
assert.equal(JSON.stringify(s),before);
assert.equal(ctx.global.spell_glyphs.modifier.amplify.effect_multiplier,undefined);
// Each Extend adds a fraction of the base duration; multiple Extends do not compound.
const extendCtx=makeContext(12);
extendCtx.tune_params=(group,id,key,fallback)=>group==='modifiers'&&id==='extend_time'&&key==='duration_increase'?0.5:fallback;
for(const [effect,base] of [['fire',3],['lightning',1],['hex',5]]) {
    for(const stacks of [0,1,2,3]) {
        const plan=extendCtx.compile_spell({form:'projectile',form_mods:[],effects:[{effect,mods:Array(stacks).fill('extend_time')}]});
        assert.equal(plan.effects[0].params.duration,base);
        assert.equal(plan.effects[0].duration,base*0.5*stacks);
        assert.equal(base+plan.effects[0].duration,base*(1+0.5*stacks));
    }
}
const direct=ctx.compile_spell({form:'projectile',form_mods:[],effects:[{effect:'harm',mods:[]},{effect:'pull',mods:[]}]});
assert.equal(direct.effects[0].target_policy,'entity');assert.equal(direct.effects[1].target_policy,'location');
console.log('Spell compilation checks passed: shared cost, modifier values, independent plans and target policies.');
const params=a.effects[0].params;
ctx.tune_value=()=>999;ctx.tune_params=(_,__,___,v)=>typeof v==='number'?v*2:v;
assert.equal(a.effects[0].params,params);assert.equal(params.base_damage,100);
assert.equal(ctx.compile_spell(s).effects[0].params.base_damage,999);
