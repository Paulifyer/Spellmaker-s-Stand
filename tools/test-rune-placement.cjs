const assert=require('node:assert/strict');
const vm=require('node:vm');
const {read,extract,load}=require('./gml-test-utils.cjs');
const {makeContext}=require('./construction-test-context.cjs');
const ctx=makeContext();
let limit=2;
const runes=[];
Object.assign(ctx,{
    obj_spells:1,Form_Beam:function(){},noone:null,ROWS_PER_LANE:1,
    max:Math.max,floor:Math.floor,json_stringify:JSON.stringify,
    array_sort:(a,f)=>a.sort(f),
    tune_params:(_,__,key,v)=>key==='max_placed'?limit:v,
    variable_global_exists:k=>Object.hasOwn(ctx.global,k),
    instance_number:()=>runes.filter(r=>!r.destroyed).length,
    instance_find:(_,i)=>runes.filter(r=>!r.destroyed)[i],
    instance_destroy:r=>{r.destroyed=true;},
    instance_create_layer:(x,y,layer,type,data)=>{
        const r={...data,lane:Math.floor(data.target_row),armed:false};runes.push(r);return r;
    },
});
ctx.global.spell_glyphs.form.rune.name='Rune';
load(ctx,'scripts/SpellCatalogScripts/SpellCatalogScripts.gml',['rune_trim_to_limit']);
const cast=extract(read('scripts/SpellCatalogScripts/SpellCatalogScripts.gml'),'cast_spell')
    .replace('_row div ROWS_PER_LANE','Math.floor(_row / ROWS_PER_LANE)');
vm.runInContext(cast,ctx);
const payer={x:0,y:0,mana:10000,mana_exhausted:false};
const spell=effect=>({name:'ignored',form:'rune',form_mods:[],effects:[{effect,mods:[]}]});
const harm=spell('harm'),fire=spell('fire');
const a=ctx.cast_spell(payer,harm,1,0).spell;a.armed=true;
const b=ctx.cast_spell(payer,harm,2,0).spell;
const f=ctx.cast_spell(payer,fire,3,0).spell;
const before=payer.mana;
const c=ctx.cast_spell(payer,harm,4,0).spell;
assert.equal(payer.mana,before-15);
assert.equal(a.destroyed,true);assert.equal(b.destroyed,undefined);assert.equal(f.destroyed,undefined);
assert.equal(c.destroyed,undefined); // new cast survives
// Names and slots do not split identical configurations into separate budgets.
const renamed={...harm,name:'renamed'};
ctx.cast_spell(payer,renamed,5,0);assert.equal(b.destroyed,true);
// Refused casts cannot remove any Rune or spend mana.
const alive=()=>runes.filter(r=>!r.destroyed).length;
let count=alive(),mana=payer.mana;
assert.equal(ctx.cast_spell(payer,harm,4,0).spell,null);assert.equal(payer.mana,mana);assert.equal(alive(),count);
const poor={...payer,mana:1};
assert.equal(ctx.cast_spell(poor,harm,8,0).spell,null);assert.equal(poor.mana,1);assert.equal(alive(),count);
// Configurable cap includes arming Runes and trims an existing surplus after a successful cast.
limit=1;const newest=ctx.cast_spell(payer,harm,6,0).spell;
assert.equal(runes.filter(r=>!r.destroyed&&r.rune_spell_key===newest.rune_spell_key).length,1);
assert.equal(f.destroyed,undefined);
limit=0;mana=payer.mana;assert.equal(ctx.cast_spell(payer,harm,7,0).spell,null);assert.equal(payer.mana,mana);
console.log('Rune placement checks passed: per-configuration cap, oldest replacement, arming/armed Runes, tile/affordability rejection and adjustable limits.');
