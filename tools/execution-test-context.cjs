const vm=require('node:vm');
const {read,extract,load,loadStatuses}=require('./gml-test-utils.cjs');
const {makeContext}=require('./construction-test-context.cjs');
function callback(ctx,file,name,event) {
    const body=extract(read(file),name);
    const part=body.slice(body.indexOf(`${event} = function`)).replace('function(','function callback(');
    return vm.runInContext(`(${extract(part,'callback').replace(/([\w.]+) div (\w+)/g,'Math.floor($1 / $2)').replace(/\bexit;/g,'return;')})`,ctx);
}
function makeExecutionContext() {
    const ctx=makeContext(30);loadStatuses(ctx);
    const enemies=[],spells=[],log=[];
    ctx.enemy_apply_mutations=(e,keys)=>{e.mutation_keys=keys;e.mutation=undefined;};
    ctx.mutation_description=()=>undefined;
    ctx.enemy_initialize_mole_marker=()=>{};
    Object.assign(ctx,{
        variable_instance_exists:(o,k)=>Object.hasOwn(o,k),array_sort:(a,f)=>a.sort(f),
        noone:null,obj_enemy_parent:'enemy',obj_gameplay_manager:'manager',obj_spells:'spell',
        obj_swarmer:'swarmer',
        GRID_X0:0,GRID_COLS:20,TILE_W:100,LANE_H:100,LANE_COUNT:3,ROWS_PER_LANE:1,TILE_H:50,
        BASE_DAMAGE:100,FIRE_MULT:0.4,FIRE_DURATION:3,FROST_DURATION:3,FROST_SLOW:0.2,LIGHTNING_DURATION:1,HEX_DURATION:5,
        max:Math.max,min:Math.min,floor:Math.floor,round:Math.round,
        tune_value:(_,__,fallback)=>fallback,show_debug_message(){},random:()=>0,
        lengthdir_x:(r,a)=>r*Math.cos(a*Math.PI/180),lengthdir_y:(r,a)=>-r*Math.sin(a*Math.PI/180),
        pull_sec:0.4,hold_sec:0.2,
        enemy_lane:e=>e.lane,
        instance_exists:o=>!!o&&!o.destroyed,
        instance_number:type=>(type==='spell'?spells:enemies).filter(o=>!o.destroyed).length,
        instance_find:(type,i)=>type==='manager'?ctx.manager:(type==='spell'?spells:enemies).filter(o=>!o.destroyed)[i],
        instance_destroy:o=>{o.destroyed=true;if(o.combat_lineage&&!o.combat_lineage.gap){o.combat_lineage.alive=false;o.combat_lineage.target=null;}},
        enemies_in_region_list:(a,b,c,d)=>enemies.filter(e=>!e.destroyed&&Math.floor(e.x/100)>=a&&Math.floor(e.x/100)<=b&&e.lane>=c&&e.lane<=d),
        enemy_begin_pull:(e,x,y,lane,frames,hold)=>{if(!e.pull)e.pull={tx:x,ty:y,lane,frames,hold};},
        json_stringify:JSON.stringify,Form_Beam:function(){},
        deal_damage:(e,amount)=>{e.hp-=amount;},
        spr_vfx_rune_complete:1,PROJECTILE_SPD:15,
    });
    ctx.global.lane_top=[0,100,200];
    load(ctx,'scripts/EnemyHelper/EnemyHelper.gml',['enemy_get_lineage','enemy_bind_lineage']);
    load(ctx,'scripts/SpellCatalogScripts/SpellCatalogScripts.gml',['apply_effect_group','spell_snapshot','cast_spell','rune_trim_to_limit']);
    const execution=read('scripts/SpellExecution/SpellExecution.gml');
    const names=[...execution.matchAll(/function (\w+)\(/g)].map(m=>m[1]);
    load(ctx,'scripts/SpellExecution/SpellExecution.gml',names);
    ctx.manager={combat_execution:ctx.combat_execution_create()};
    ctx.forms={};
    for(const [id,name] of Object.entries({projectile:'Projectile',beam:'Beam',strike:'Strike',rune:'Rune'})) {
        const form=ctx.global.spell_glyphs.form[id];form.name=name;form.is_channel=id==='beam';
        for(const event of ['on_cast','on_step','on_hit']) {
            const body=extract(read('scripts/FormGlyphs/FormGlyphs.gml'),`Form_${name}`);
            if(body.includes(`${event} = function`))form[event]=callback(ctx,'scripts/FormGlyphs/FormGlyphs.gml',`Form_${name}`,event);
        }
        ctx.forms[id]=form;
    }
    for(const [id,name]of Object.entries({harm:'Harm',fire:'Fire',ice:'Ice',lightning:'Lightning',hex:'Hex',pull:'Pull'})) {
        const fx=ctx.global.spell_glyphs.effect[id];fx.on_cast=()=>{};
        fx.on_hit=(spell,e,group)=>{log.push(id);if(id!=='pull')callback(ctx,'scripts/EffectGlyphs/EffectGlyphs.gml',`Elem_${name}`,'on_hit')(spell,e,group);};
        fx.on_impact=(spell,group,col,lane)=>{log.push(id);if(id==='pull')callback(ctx,'scripts/EffectGlyphs/EffectGlyphs.gml','Elem_Pull','on_impact')(spell,group,col,lane);};
    }
    function enemy(col=2,lane=0,extra={}) {
        const e={x:col*100+50,y:lane*100,lane,hp:100000,base_speed:1,my_speed:1,is_targetable:true,
            burn_timer:0,burn_dmg:0,slow_timer:0,slow_amt:0,stun_timer:0,stun_immune_timer:0,hex_timer:0,pull:undefined,...extra};
        enemies.push(e);ctx.enemy_get_lineage(e);return e;
    }
    function spell(form,effects,mods=[]) {
        const compiled=ctx.compile_spell({form,form_mods:mods,effects});
        const s={compiled,form:compiled.form,effects:compiled.effects,form_mods:compiled.form_mods,
            area:compiled.area,pierce:compiled.pierce,cast_id:ctx.combat_next_id(),delivery_index:0,
            hit_state:{contacts:[],applications:{},epoch:0},x:0,y:0,col:0,target_col:2,target_row:0,caster:{}};
        spells.push(s);return s;
    }
    function tick(n=1,paused=false){for(let i=0;i<n;i++)if(!paused){ctx.manager.combat_execution.clock++;ctx.combat_execution_flush(ctx.manager.combat_execution);}}
    function finishPull(e){if(e.pull){Object.assign(e,{x:e.pull.tx,y:e.pull.ty,lane:e.pull.lane,pull:undefined});}}
    return {ctx,enemies,spells,log,enemy,spell,tick,finishPull};
}
module.exports={makeExecutionContext,callback};
