'use strict';
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const crypto = require('node:crypto');
const {execFileSync} = require('node:child_process');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
for (const file of ['engine.cjs', 'lib/cdp.cjs', 'runtime/install.js', 'tests/endpoints.cjs', 'tests/startup.cjs', 'tests/sidebar.cjs', 'scripts/check.cjs', 'scripts/checksums.cjs']) {
  execFileSync(process.execPath, ['--check', path.join(root, file)], {stdio: 'inherit'});
}
const html = fs.readFileSync(path.join(root, 'demo/index.html'), 'utf8');
for (const match of html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)) new vm.Script(match[1]);
for (const match of html.matchAll(/(?:src|poster)=["']([^"']+)["']/g)) {
  const source = match[1];
  if (/^(?:data:|https?:|#)/.test(source)) continue;
  assert.ok(fs.existsSync(path.resolve(root, 'demo', source)), `Missing demo media: ${source}`);
}
for (const file of ['manifest.json', 'VALIDATION.json', 'assets/pet.json']) JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'));
let count = 0;
for (const line of fs.readFileSync(path.join(root, 'SHA256SUMS.txt'), 'utf8').trim().split(/\r?\n/)) {
  const match = /^([a-f0-9]{64})  (.+)$/.exec(line);
  assert.ok(match, 'Invalid checksum record');
  const file = path.resolve(root, match[2]);
  assert.ok(file.startsWith(root + path.sep), 'Checksum path escapes repository');
  assert.equal(crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex'), match[1], `Checksum mismatch: ${match[2]}`);
  count++;
}
console.log(`Syntax, demo resources, JSON and ${count} file checksums passed.`);
