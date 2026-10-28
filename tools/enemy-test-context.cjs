const {makeExecutionContext}=require('./execution-test-context.cjs');
const {load}=require('./gml-test-utils.cjs');
function makeEnemyContext(){
 const h=makeExecutionContext(),ctx=h.ctx;
 Object.assign(ctx,{is_array:Array.isArray,is_string:x=>typeof x==='string',string_pos:(needle,s)=>s.indexOf(needle)+1,c_white:0xffffff,c_gray:0x888888});
 ctx.global.mutations={skeletal:{cost:1},banneret:{cost:3},'fire-warded':{cost:1},'frost-warded':{cost:1},'lightning-warded':{cost:1}};
 for(const [key,m]of Object.entries(ctx.global.mutations))Object.assign(m,{name:key,on_spawn(){},on_step(){},on_death(){}});
 load(ctx,'scripts/MutationScripts/MutationScripts.gml',['normalize_mutation_keys','mutation_total_cost','enemy_has_mutation','enemy_apply_mutations']);
 // Engine constructor binding is represented here; normalization/cost/hook calls are actual GML.
 ctx.EnemyMutationSet=function(keys){this.keys=Array.from(keys);this.tint=this.keys.includes('skeletal')?ctx.c_gray:ctx.c_white;
  this.on_spawn=e=>{for(const k of this.keys)ctx.global.mutations[k].on_spawn(e);};};
 return h;
}
module.exports={makeEnemyContext};
