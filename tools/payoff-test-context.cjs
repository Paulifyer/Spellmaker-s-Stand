const {makeExecutionContext,callback}=require('./execution-test-context.cjs');
const {load,read}=require('./gml-test-utils.cjs');
function makePayoffContext() {
    const h=makeExecutionContext(),c=h.ctx;
    for(const name of ['Snap','Combust','Discharge']) {
        if(!read('scripts/EffectGlyphs/EffectGlyphs.gml').includes(`function Elem_${name}(`))continue;
        c.global.spell_glyphs.effect[name.toLowerCase()]={cost:name==='Discharge'?20:15,delivery_kind:'target',
            on_hit:callback(c,'scripts/EffectGlyphs/EffectGlyphs.gml',`Elem_${name}`,'on_hit')};
    }
    Object.assign(c,{obj_mook:'mook',obj_brute:'brute',HEX_DAMAGE_PER_STATUS:0.1,audio_play_sound(){},
        enemy_overlaps_region:(e,a,b,l1,l2)=>Math.floor(e.x/100)>=a&&Math.floor(e.x/100)<=b&&e.lane>=l1&&e.lane<=l2,
        world_to_grid:(x,y)=>({col:Math.floor(x/100),lane:Math.floor(y/100)})});
    load(c,'scripts/GameplayScripts/GameplayScripts.gml',['deal_damage']);
    load(c,'scripts/EnemyHelper/EnemyHelper.gml',['enemy_update_movement']);
    return h;
}
module.exports={makePayoffContext};
