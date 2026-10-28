const vm = require('node:vm');
const {read, extract, load} = require('./gml-test-utils.cjs');
function makeContext(limit = 8) {
    const glyphs = {form: {}, effect: {}, modifier: {}};
    for (const id of ['projectile','strike','beam','rune']) glyphs.form[id] = {cost: 5};
    for (const id of ['harm','fire','ice','lightning','hex','pull','none']) glyphs.effect[id] = {cost: 10};
    const effectSource = read('scripts/EffectGlyphs/EffectGlyphs.gml');
    for (const [id,name] of Object.entries({harm:'Harm',fire:'Fire',ice:'Ice',lightning:'Lightning',hex:'Hex',pull:'Pull'})) {
        const start = effectSource.indexOf(`function Elem_${name}(`);
        const next = effectSource.indexOf('\nfunction ',start+1);
        const body = effectSource.slice(start,next<0?undefined:next);
        const match = body.match(/allowed_forms = (\[[^\]]*\])/);
        if (match) glyphs.effect[id].allowed_forms=JSON.parse(match[1]);
        const delivery=body.match(/delivery_kind = "(\w+)"/);
        glyphs.effect[id].delivery_kind=delivery?delivery[1]:'target';
    }
    const modifiers = read('scripts/ModifierGlyphs/ModifierGlyphs.gml');
    for (const [id, name] of Object.entries({area:'Area',pierce:'Pierce',amplify:'Amplify',extend_time:'Extend_Time',delay:'Delay'})) {
        const start = modifiers.indexOf(`function Mod_${name}(`);
        const next = modifiers.indexOf('\nfunction ', start + 1);
        const body = modifiers.slice(start, next < 0 ? undefined : next);
        const m = {cost: 5, scope:'spell',is_stacks:false,allowed_forms:undefined,allowed_effects:undefined};
        const scope = body.match(/scope = "(\w+)"/); if (scope) m.scope=scope[1];
        m.is_stacks = body.includes('is_stacks = true');
        for (const field of ['allowed_forms','allowed_effects']) {
            const match = body.match(new RegExp(`${field} = (\\[[^\\]]*\\])`));
            if (match) m[field] = JSON.parse(match[1]);
        }
        glyphs.modifier[id] = m;
    }
    const ctx = vm.createContext({
        room:'rm_test', room_get_name: x => x,
        global:{spell_glyphs:glyphs,level_config:{rm_test:{max_glyphs:limit}},spellbook:[]},
        array_length:a=>a.length,array_contains:(a,v)=>a.includes(v),array_push:(a,v)=>a.push(v),array_delete:(a,i,n)=>a.splice(i,n),
        is_struct:x=>!!x && typeof x==='object', variable_struct_exists:(s,k)=>Object.hasOwn(s,k),
        variable_global_exists:k=>Object.hasOwn(ctx.global,k),
        string:String,clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),
        is_glyph_available:()=>true, is_instanceof:()=>false, Mod_Amplify:function(){},
        enemy_ward_active:()=>false,
        tune_params:(_,__,___,v)=>v,tune_value:(_,__,v)=>v,AMPLIFY_ADD_MULT:1,PIERCE_AMT:2,EXTEND_TIME_ADD:5,DELAY_AMT:1,
    });
    const helper = 'scripts/SpellbookHelperScripts/SpellbookHelperScripts.gml';
    for (const [id,name] of Object.entries({area:'Area',pierce:'Pierce',amplify:'Amplify',extend_time:'Extend_Time',delay:'Delay'})) {
        const body=extract(modifiers,`Mod_${name}`);
        const part=body.slice(body.indexOf('on_cast = function')).replace('function(','function callback(');
        glyphs.modifier[id].on_cast=vm.runInContext(`(${extract(part,'callback')})`,ctx);
    }
    load(ctx,'scripts/SpellCatalogScripts/SpellCatalogScripts.gml',['compile_effect_parameters','compile_spell','combat_next_id','spell_new_delivery']);
    load(ctx,helper,['spell_max_glyphs','spell_glyph_count','spell_catalog_entry','mod_valid_for_form','mod_valid_for_effect','effect_valid_for_form','spell_sequence_valid','spell_can_append_effect','spell_validation_message','spell_addition_message','spell_add_glyph','spell_cost','spell_mana_preview','spellbook_expensive_slots','spellbook_start_message']);
    load(ctx,'scripts/GlyphAccessScripts/GlyphAccessScripts.gml',['is_spell_usable','sanitize_owned']);
    return ctx;
}
module.exports={makeContext};
