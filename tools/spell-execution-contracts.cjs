// Approved contracts. The integrated engine harness runs these after the migration.
const assert = require('node:assert/strict');
module.exports = function runContracts(api) {
    assert.deepEqual(api.strikePullHarm(false), {immediate:0,later:0,order:['pull','harm']});
    assert.deepEqual(api.strikePullHarm(true), {immediate:0,later:1,order:['pull','harm']});
    assert.equal(api.areaReselect('rune'), true);
    assert.equal(api.areaReselect('projectile'), true);
    assert.equal(api.directFollowsLineage(), true);
    assert.equal(api.beamTicksRemainIndependent(), true);
    assert.equal(api.pauseAndRoomReset(), true);
    assert.equal(api.equalTimeOrder(), true);
};
