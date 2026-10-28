const assert = require('node:assert/strict');
const {load} = require('./gml-test-utils.cjs');
const {makeExecutionContext} = require('./execution-test-context.cjs');

const h = makeExecutionContext(), c = h.ctx;
load(c, 'scripts/GridHelperScripts/GridHelperScripts.gml', ['enemy_col_range', 'enemy_overlaps_region']);
// Use the real grid overlap check instead of the execution fixture's simplified check.
c.enemies_in_region_list = (a,b,l1,l2) => h.enemies.filter(e =>
    !e.destroyed && c.enemy_overlaps_region(e,Math.max(0,a),Math.min(c.GRID_COLS-1,b),l1,l2));
for (const lane of [0,1,2]) {
    const e = h.enemy(0,lane,{x:c.GRID_X0,hit_x:0,hit_w:0,path_position:1});
    assert.equal(c.enemy_overlaps_region(e,0,0,lane,lane),true);
    assert.equal(c.enemy_overlaps_region(e,1,1,lane,lane),false);
    const s = h.spell('strike',[{effect:'harm',mods:[]}]);
    s.target_col=0;s.target_row=lane;
    c.forms.strike.on_cast(s);
    for(let i=0;i<s.compiled.strike_cast_frames;i++) c.forms.strike.on_step(s);
    assert.equal(e.hp,99900,'Strike hits a point-sized enemy attacking the tower');
}
// Preserve finite-width overlap and exclusive right edges at tile boundaries.
const wide = h.enemy(0,0,{x:50,hit_x:0,hit_w:100});
assert.equal(c.enemy_overlaps_region(wide,0,0,0,0),true);
assert.equal(c.enemy_overlaps_region(wide,1,1,0,0),false);
const point = h.enemy(1,0,{x:100,hit_x:0,hit_w:0});
assert.equal(c.enemy_overlaps_region(point,1,1,0,0),true);
assert.equal(c.enemy_overlaps_region(point,0,0,0,0),false);
console.log('Tower targeting checks passed: Strike at the tower, lanes, point targets and finite-width boundaries.');
