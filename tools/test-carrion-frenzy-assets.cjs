const assert = require('node:assert/strict');
const fs = require('node:fs');
const crypto = require('node:crypto');
const {read} = require('./gml-test-utils.cjs');
const parse = file => JSON.parse(read(file).replace(/,\s*([}\]])/g, '$1'));
const project = parse('Spell.yyp');
const manifest = parse('tools/asset-sources/carrion-frenzy/manifest.json');
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
for (const item of manifest) {
    const entry = project.resources.filter(r => r.id.name === item.name);
    assert.equal(entry.length, 1, item.name);
    const resource = parse(entry[0].id.path);
    assert.equal(resource.name, item.name);
    if (item.name.startsWith('spr_')) {
        assert.equal(resource.frames.length, 1);
        assert.equal(resource.width, item.width); assert.equal(resource.height, item.height);
        assert.deepEqual([resource.bbox_left, resource.bbox_top, resource.bbox_right, resource.bbox_bottom], item.bounds);
        assert.deepEqual([resource.sequence.xorigin, resource.sequence.yorigin], item.origin);
        assert.ok(item.origin.every(Number.isInteger));
        const frame = resource.frames[0].name, layer = resource.layers[0].name;
        assert.equal(hash(`sprites/${item.name}/${frame}.png`), item.sha256);
        assert.equal(hash(`sprites/${item.name}/layers/${frame}/${layer}.png`), item.sha256);
        const ref = resource.sequence.tracks[0].keyframes.Keyframes[0].Channels['0'].Id;
        assert.equal(ref.name, frame); assert.equal(ref.path, entry[0].id.path);
    } else {
        assert.equal(hash(`sounds/${item.name}/${resource.soundFile}`), item.sha256);
        assert.equal(resource.sampleRate, item.sampleRate); assert.equal(resource.duration, item.duration);
        assert.equal(resource.preload, true);
    }
}
const carrion = parse('objects/obj_carrion/obj_carrion.yy');
assert.ok(carrion.eventList.some(e => e.eventType === 3 && e.eventNum === 1));
assert.ok(read('objects/obj_carrion/Step_1.gml').includes('carrion_update_frenzy(id)'));
console.log('Carrion assets passed: original PNG/MP3 hashes, frame/layer references, bounds, origins, audio metadata and Begin Step registration.');
