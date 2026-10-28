const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const files = fs.readdirSync(__dirname).filter(name => /^test-.*\.cjs$/.test(name)).sort();
const failed = [];
for (const file of files) {
    const result = spawnSync(process.execPath, [path.join(__dirname, file)], {stdio: 'inherit'});
    if (result.error || result.status !== 0) failed.push(file);
}
console.log(`${files.length - failed.length}/${files.length} regression scripts passed.`);
if (failed.length) { console.error('Failed: ' + failed.join(', ')); process.exitCode = 1; }
