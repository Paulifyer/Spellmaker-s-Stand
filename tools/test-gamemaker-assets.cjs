const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {read}=require('./gml-test-utils.cjs');
const parse=p=>JSON.parse(read(p).replace(/,\s*([}\]])/g,'$1'));
const project=parse('Spell.yyp');
assert.doesNotMatch(read('scripts/SpellExecution/SpellExecution.gml'),/\b\d+(?:\.\d+)?[eE][+-]?\d+\b/,'Use GameMaker-compatible numeric literals');
assert.equal(project.RoomOrderNodes[0].roomId.name,'rm_menu');
for(const name of ['SpellExecution','obj_spell_test_driver','obj_spell_test_enemy','rm_spell_interaction_test']) {
    const entry=project.resources.find(r=>r.id.name===name);assert.ok(entry,name);
    assert.ok(fs.existsSync(path.join(__dirname,'..',entry.id.path)));parse(entry.id.path);
}
const manager=parse('objects/obj_gameplay_manager/obj_gameplay_manager.yy');
for(const num of [1,2])assert.ok(manager.eventList.some(e=>e.eventType===3&&e.eventNum===num));
assert.ok(manager.eventList.some(e=>e.eventType===8&&e.eventNum===73));
assert.match(read('objects/obj_gameplay_manager/Draw_73.gml'),/spell_chain_draw_links/);
for(const name of ['obj_spell_test_driver','obj_spell_test_enemy']) {
    const obj=parse(`objects/${name}/${name}.yy`);
    for(const event of obj.eventList) {
        const prefix={0:'Create',3:'Step',8:'Draw'}[event.eventType];
        assert.ok(fs.existsSync(path.join(__dirname,'..',`objects/${name}/${prefix}_${event.eventNum}.gml`)));
    }
}
const room=parse('rooms/rm_spell_interaction_test/rm_spell_interaction_test.yy');
assert.equal(room.layers[0].instances[0].objectId.name,'obj_spell_test_driver');
assert.equal(room.creationCodeFile,'');assert.equal(room.name.startsWith('rm_level_'),false);
const functions=new Map();
function walk(dir){for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
    const file=path.join(dir,entry.name);if(entry.isDirectory())walk(file);
    else if(file.endsWith('.gml')){
        const code=fs.readFileSync(file,'utf8');
        assert.equal(/\b(pending_effects|pending_spell_impacts|schedule_effect|spell_hit_area|spell_impact)\b/.test(code),false,file);
        for(const m of code.matchAll(/function (\w+)\(/g)) {
            assert.equal(functions.has(m[1]),false,`Duplicate function ${m[1]}`);functions.set(m[1],file);
        }
    }
}}
walk(path.join(__dirname,'..','scripts'));walk(path.join(__dirname,'..','objects'));
console.log('GameMaker asset checks passed: registered scripts/test room, event files, default starting room and obsolete-path removal.');
