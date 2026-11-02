'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const excluded = new Set(['.git', '.idea', 'node_modules', 'dist', 'work', 'outputs', 'profile']);
function walk(dir) {
  return fs.readdirSync(path.join(root, dir), {withFileTypes: true}).flatMap(entry => {
    if (excluded.has(entry.name) || entry.name === 'SHA256SUMS.txt') return [];
    const file = path.posix.join(dir, entry.name);
    if (entry.isSymbolicLink()) throw Error(`Unexpected symbolic link: ${file}`);
    return entry.isDirectory() ? walk(file) : [file];
  });
}
const files = walk('').sort();
const lines = files.map(file => `${crypto.createHash('sha256').update(fs.readFileSync(path.join(root, file))).digest('hex')}  ${file}`);
fs.writeFileSync(path.join(root, 'SHA256SUMS.txt'), lines.join('\n') + '\n');
console.log(`Recorded checksums for ${files.length} files.`);
