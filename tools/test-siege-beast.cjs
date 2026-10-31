const assert=require('node:assert/strict');
const {load}=require('./gml-test-utils.cjs');
const {makeEnemyContext}=require('./enemy-test-context.cjs');
const h=makeEnemyContext(),ctx=h.ctx;let damage=0;
Object.assign(ctx,{tune_enemy:(_,__,v)=>v,reduce_village_hp:n=>damage+=n});
load(ctx,'scripts/EnemyHelper/EnemyHelper.gml',['enemy_update_movement','enemy_siege_attack']);
const beast=()=>h.enemy(2,0,{hp:750,path_position:1,charge_active:true,normal_speed:0.6,base_speed:4,damage_dealt:5,attack_delay:4,siege_attack_timer:-1});
let e=beast();ctx.enemy_siege_attack(e);assert.equal(damage,10);assert.equal(e.charge_active,false);
for(let i=0;i<239;i++)ctx.enemy_siege_attack(e);assert.equal(damage,10);ctx.enemy_siege_attack(e);assert.equal(damage,15);
e=beast();damage=0;ctx.combat_status_apply(e,'lightning',60);assert.equal(e.charge_active,false);assert.equal(e.base_speed,0.6);
ctx.enemy_siege_attack(e);assert.equal(damage,0);e.stun_timer=0;
ctx.enemy_siege_attack(e);assert.equal(e.siege_attack_timer,240);
for(let i=0;i<100;i++)ctx.enemy_siege_attack(e);e.stun_timer=30;
for(let i=0;i<30;i++)ctx.enemy_siege_attack(e);assert.equal(e.siege_attack_timer,140);
e.stun_timer=0;for(let i=0;i<140;i++)ctx.enemy_siege_attack(e);assert.equal(damage,5);
e=beast();ctx.enemy_interrupt_charge(e,'barricade');assert.equal(e.charge_active,false);assert.equal(e.charge_interrupt_reason,'barricade');
console.log('Siege checks passed: single doubled impact, normal windup, spell-before-impact stun, paused windup and barricade hook.');

// Exercise the shared damage resolver, including live charge transitions and burn.
load(ctx,'scripts/MutationScripts/MutationScripts.gml',['enemy_ward_key','enemy_ward_active']);
Object.assign(ctx,{HEX_DAMAGE_PER_STATUS:0.1,obj_mook:'mook',obj_brute:'brute'});
load(ctx,'scripts/GameplayScripts/GameplayScripts.gml',['deal_damage']);
const protectedBeast=()=>Object.assign(beast(),{object_index:'siege',charge_dmg_taken_mult:0.5,dmg_reduction:0,mutation_keys:[]});
e=protectedBeast();ctx.deal_damage(e,100);assert.equal(e.hp,700);
e.charge_dmg_taken_mult=0.25;ctx.deal_damage(e,100);assert.equal(e.hp,675);
for(const reason of ['stun','blocked','impact']){
 e=protectedBeast();
 if(reason==='stun')ctx.combat_status_apply(e,'lightning',60);
 else if(reason==='impact')ctx.enemy_siege_attack(e);
 else ctx.enemy_interrupt_charge(e,reason);
 ctx.deal_damage(e,100);assert.equal(e.hp,650,reason);
}
e=protectedBeast();e.dmg_reduction=0.2;e.mutation_keys=['fire-warded'];
ctx.combat_status_apply(e,'hex',60);ctx.deal_damage(e,100);
assert.equal(e.hp,728); // 100 * 1.1 Hex * 0.8 mutation * 0.5 ward * 0.5 charge.
e=protectedBeast();ctx.combat_status_apply(e,'burn',60,100);
ctx.combat_status_advance(e,60);assert.equal(e.hp,700);
e=h.enemy(2,0,{object_index:'other',hp:750,dmg_reduction:0,mutation_keys:[]});
ctx.deal_damage(e,100);assert.equal(e.hp,650);
console.log('Charge damage checks passed: configured multiplier, interruption, stacking, burn and ordinary enemies.');
