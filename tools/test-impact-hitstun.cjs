const assert = require('node:assert/strict');
const {makeExecutionContext} = require('./execution-test-context.cjs');
const fx = effect => ({effect, mods: []});

// Projectile applies on contact, including non-damaging payloads and blast victims.
for (const mods of [[], ['pierce'], ['area', 'pierce']]) {
    const h = makeExecutionContext();
    const a = h.enemy(2), b = h.enemy(3), outside = h.enemy(6);
    const hidden = h.enemy(2, 0, {is_targetable: false});
    const s = h.spell('projectile', [fx('fire'), fx('ice')], mods);
    h.ctx.forms.projectile.on_hit(s, a);
    assert.equal(a.hitstun_timer, 10);
    assert.equal(b.hitstun_timer, mods.includes('area') ? 10 : 0);
    assert.equal(outside.hitstun_timer, 0);
    assert.equal(hidden.hitstun_timer, 0);
    a.hitstun_timer = 1;
    h.ctx.forms.projectile.on_hit(s, a);
    assert.equal(a.hitstun_timer, 1, 'Repeated overlap must not refresh');
    if (mods.includes('pierce') && !mods.includes('area')) {
        h.ctx.forms.projectile.on_hit(s, b);
        assert.equal(b.hitstun_timer, 10);
    }
}

// Beam selects targets per lane/pierce, refreshing only when a new tick hits.
for (const mods of [[], ['pierce'], ['area'], ['area', 'pierce']]) {
    const h = makeExecutionContext();
    const a = h.enemy(2), b = h.enemy(3), adjacent = h.enemy(2, 1);
    const s = h.spell('beam', [fx('harm')], mods);
    Object.assign(s, {tick: 0, lane: 0, beam_lanes: []});
    h.ctx.forms.beam.on_step(s);
    assert.equal(a.hitstun_timer, 5);
    assert.equal(b.hitstun_timer, mods.includes('pierce') ? 5 : 0);
    assert.equal(adjacent.hitstun_timer, mods.includes('area') ? 5 : 0);
    a.hitstun_timer = 1;
    h.ctx.forms.beam.on_step(s);
    assert.equal(a.hitstun_timer, 1, 'Between-tick frames must not refresh');
    s.tick = 14;
    h.ctx.forms.beam.on_step(s);
    assert.equal(a.hitstun_timer, 5, 'Next tick must refresh');
}
console.log('Impact hitstun checks passed: Projectile/Beam, area, pierce, eligibility and repeat timing.');
