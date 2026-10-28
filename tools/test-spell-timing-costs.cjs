const assert=require('node:assert/strict');
const vm=require('node:vm');
const {read,extract,load,loadStatuses}=require('./gml-test-utils.cjs');
const {makeContext}=require('./construction-test-context.cjs');
const ctx=makeContext();
const tuning=JSON.parse(read('datafiles/tune.json'));
loadStatuses(ctx);
Object.assign(ctx,{
    TARGET_ROOM_SPEED:60,BASE_DAMAGE:100,FIRE_MULT:0.4,FIRE_DURATION:3,FROST_DURATION:3,FROST_SLOW:0.2,
    LIGHTNING_DURATION:1,HEX_DURATION:5,max:Math.max,min:Math.min,floor:Math.floor,round:Math.round,
    tune_params:(group,name,key,fallback)=>tuning[group]?.[name]?.[key]??fallback,
    tune_value:(group,key,fallback)=>tuning[group]?.[key]??fallback,
});
function callback(file,name,event,params){
    const body=extract(read(file),name);
    const part=body.slice(body.indexOf(`${event} = function`)).replace('function(','function callback(');
    return vm.runInContext(`(${extract(part,'callback')})`,ctx);
}
const effectFile='scripts/EffectGlyphs/EffectGlyphs.gml';
for(const [name,key,field] of [['Fire','fire','burn_timer'],['Ice','ice','slow_timer'],['Lightning','lightning','stun_timer'],['Hex','hex','hex_timer']]) {
    const hit=callback(effectFile,`Elem_${name}`,'on_hit');
    for(const bonus of [0,5,10]) {
        const target={slow_amt:0,stun_timer:0,stun_immune_timer:0};
        hit({},target,{duration:bonus,effect_multiplier:1,params:ctx.compile_effect_parameters(key)});
        assert.equal(target[field],60*(tuning.effects[key].duration+bonus));
    }
}
// Execute actual creation-time modifier application and cumulative Delay resolution.
ctx.global.spell_glyphs.form.projectile={name:'Projectile',cost:15,on_cast(){}};
ctx.global.spell_glyphs.effect.harm={cost:10,on_cast(){}};
ctx.global.spell_glyphs.effect.fire={cost:10,on_cast(){}};
ctx.global.spell_glyphs.modifier.amplify.cost=15;
ctx.global.spell_glyphs.modifier.amplify.on_cast=callback('scripts/ModifierGlyphs/ModifierGlyphs.gml','Mod_Amplify','on_cast');
ctx.global.spell_glyphs.modifier.extend_time.on_cast=callback('scripts/ModifierGlyphs/ModifierGlyphs.gml','Mod_Extend_Time','on_cast');
ctx.global.spell_glyphs.modifier.delay.on_cast=callback('scripts/ModifierGlyphs/ModifierGlyphs.gml','Mod_Delay','on_cast');
Object.assign(ctx,{Form_Beam:function(){},noone:null,obj_spells:1,ROWS_PER_LANE:1,AMPLIFY_ADD_MULT:1,EXTEND_TIME_ADD:5,DELAY_AMT:1,
    instance_number:()=>0,
    is_instanceof:(m,ctor)=>m===ctx.global.spell_glyphs.modifier.amplify,
});
const creation=read('objects/obj_spells/Create_0.gml');
const init=creation.slice(creation.indexOf('form.on_cast(self);'),creation.indexOf('col = c_white;',creation.indexOf('form.on_cast(self);')));
ctx.instance_create_layer=(x,y,layer,type,data)=>{
    Object.assign(ctx,{self:data,form:data.form,form_mods:data.form_mods,effects:data.effects});
    vm.runInContext(init,ctx);return data;
};
vm.runInContext(extract(read('scripts/SpellCatalogScripts/SpellCatalogScripts.gml'),'cast_spell').replace('_row div ROWS_PER_LANE','Math.floor(_row / ROWS_PER_LANE)'),ctx);
let s={form:'projectile',form_mods:[],effects:[{effect:'harm',mods:['amplify','amplify','amplify']}]};
let payer={x:0,y:0,mana:1000,mana_exhausted:false};
let result=ctx.cast_spell(payer,s,0,0);
assert.equal(result.cost,85);assert.equal(ctx.spell_cost(s),85);assert.equal(payer.mana,915);
assert.equal(result.spell.effects[0].duration,0);assert.equal(result.spell.effects[0].effect_multiplier,4);
s={form:'projectile',form_mods:[],effects:[{effect:'harm',mods:['amplify','amplify']},{effect:'fire',mods:['amplify']}]};
assert.equal(ctx.cast_spell(payer,s,0,0).cost,ctx.spell_cost(s));
s={form:'projectile',form_mods:[],effects:[{effect:'fire',mods:['extend_time','delay']},{effect:'harm',mods:[]}]};
result=ctx.cast_spell(payer,s,0,0);
assert.equal(result.spell.effects[0].duration,5);assert.equal(result.spell.effects[1].duration,0);
assert.equal(result.spell.effects[1].delay,1);
// Pull's hold is configured directly, not multiplied by the extra-duration accumulator.
const pull=callback(effectFile,'Elem_Pull','on_impact');let hold;
Object.assign(ctx,{GRID_X0:0,TILE_W:100,LANE_H:100,pull_sec:0.4,hold_sec:0.2,
    show_debug_message(){},random:()=>0,point_distance:()=>0,lengthdir_x:()=>0,lengthdir_y:()=>0,
    enemies_in_region_list:()=>[{}],enemy_begin_pull:(e,x,y,lane,frames,value)=>{hold=value;}});
ctx.global.lane_top=[0];pull({},{duration:0,params:{pull_sec:0.4,hold_sec:0.2}},0,0);assert.equal(hold,12);
// A three-second burn delivers three ticks, none on the first frame.
let ticks=0;ctx.deal_damage=()=>ticks++;
const burning={burn_timer:180,burn_dmg:40,slow_timer:0,slow_amt:0,stun_timer:0,stun_immune_timer:0,hex_timer:0};
ctx.combat_status_advance(burning,1);assert.equal(ticks,0);
for(let i=1;i<180;i++)ctx.combat_status_advance(burning,1);
assert.equal(ticks,3);assert.equal(burning.burn_timer,0);
ctx.combat_status_advance(burning,1);assert.equal(ticks,3);
console.log('Timing/cost checks passed: configured durations, Extend/Delay, Amplify surcharge, Pull hold and final burn tick.');
