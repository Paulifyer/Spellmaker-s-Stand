const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const read = p => fs.readFileSync(path.join(__dirname, '..', p), 'utf8');
function extract(source, name) {
    const start = source.indexOf(`function ${name}(`);
    assert.ok(start >= 0, name);
    let end = source.indexOf('{', start) + 1, depth = 1;
    while (depth) {
        if (source[end] === '{') depth++;
        if (source[end] === '}') depth--;
        end++;
        assert.ok(end <= source.length, `Unclosed function ${name}`);
    }
    return source.slice(start, end).replace(/\[\$\s*([^\]]+)\]/g, '[$1]').replace(/\bmod\b/g,'%').replace(/([\w.]+) div (\w+)/g,'Math.floor($1 / $2)');
}
function load(ctx, file, names) {
    for (const name of names) vm.runInContext(extract(read(file), name), ctx);
}
function loadStatuses(ctx) {
    if (!ctx.global) ctx.global={};
    const defaults={is_struct:x=>!!x&&typeof x==='object',variable_global_exists:k=>Object.hasOwn(ctx.global,k),
        array_length:a=>a.length,clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),max:Math.max,min:Math.min,round:Math.round,
        c_red:1,c_teal:2,c_yellow:3,c_fuchsia:4,TARGET_ROOM_SPEED:60,tune_params:(_,__,___,v)=>v};
    for(const [k,v] of Object.entries(defaults))if(ctx[k]===undefined)ctx[k]=v;
    load(ctx,'scripts/EnemyHelper/EnemyHelper.gml',['combat_status_definitions','combat_status_get','combat_status_set','combat_status_active','combat_status_count','combat_status_apply','combat_status_capture','combat_status_restore','combat_status_advance','enemy_advance_lightning']);
}
module.exports = {read, extract, load, loadStatuses};
