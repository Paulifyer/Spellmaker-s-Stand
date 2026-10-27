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
    return source.slice(start, end).replace(/\[\$\s*([^\]]+)\]/g, '[$1]');
}
function load(ctx, file, names) {
    for (const name of names) vm.runInContext(extract(read(file), name), ctx);
}
module.exports = {read, extract, load};
