const assert=require('node:assert/strict');
const {makeExecutionContext}=require('./execution-test-context.cjs');
const {load}=require('./gml-test-utils.cjs');

for(const form of ['strike','projectile']) {
    for(const badCache of [undefined,()=>{},{}]) {
        const h=makeExecutionContext(), c=h.ctx;
        c.grid_to_world_center=(col,row)=>({x:(col+0.5)*c.TILE_W,y:(row+0.5)*c.TILE_H});
        // Model the accessor being visible in the global namespace too.
        c.global.combat_status_definitions=c.combat_status_definitions;
        if(badCache!==undefined)c.global.combat_status_registry=badCache;
        const definitions=c.combat_status_definitions();
        assert.ok(Array.isArray(definitions));
        assert.equal(definitions.length,4);
        assert.equal(c.global.combat_status_definitions,c.combat_status_definitions);
        assert.equal(c.combat_status_definitions(),definitions); // stable valid cache
        const e=h.enemy(), s=h.spell(form,[{effect:'fire',mods:[]},{effect:'ice',mods:[]}]);
        if(form==='projectile')c.forms.projectile.on_hit(s,e);
        else {
            c.forms.strike.on_cast(s);
            for(let i=0;i<20&&!s.landed;i++)c.forms.strike.on_step(s);
            assert.equal(s.landed,true);
        }
        assert.equal(e.burn_timer,180); assert.equal(e.burn_dmg,40);
        assert.equal(e.slow_timer,180); assert.equal(e.slow_amt,0.2);
        assert.equal(c.combat_status_active(e,'burn'),true);
        assert.equal(c.combat_status_active(e,'frost'),true);
        assert.equal(c.combat_status_count(e),2); // same predicates used by enemy Draw
        load(c,'scripts/EnemyHelper/EnemyHelper.gml',['enemy_update_movement']);
        c.enemy_update_movement(e); assert.equal(e.path_speed,0.8);
        const initialHp=e.hp;
        for(let frame=1;frame<=180;frame++) {
            c.combat_status_advance(e,1);
            c.enemy_update_movement(e);
            assert.equal(e.hp,initialHp-Math.floor(frame/60)*40);
            assert.equal(e.path_speed,frame<180?0.8:1);
        }
        assert.equal(e.slow_amt,0);
        assert.equal(c.combat_status_active(e,'burn'),false);
        assert.equal(c.combat_status_active(e,'frost'),false);
        assert.equal(c.combat_status_count(e),0);
        c.combat_status_advance(e,60); assert.equal(e.hp,initialHp-120);
    }
}
console.log('Fire/Ice checks passed: global accessor collision, invalid cache recovery, Strike/Projectile delivery, status visibility predicates, burn ticks, slowdown and expiry.');
