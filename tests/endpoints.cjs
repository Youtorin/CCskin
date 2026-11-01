const assert=require('node:assert/strict'),{checkedSocket}=require('../lib/cdp.cjs');
assert.equal(checkedSocket('ws://127.0.0.1:19435/devtools/browser/abc-123',19435),'ws://127.0.0.1:19435/devtools/browser/abc-123');
for(const bad of ['ws://localhost:19435/devtools/browser/abc','ws://192.168.1.1:19435/devtools/browser/abc','ws://127.0.0.1:9333/devtools/browser/abc','ws://user@127.0.0.1:19435/devtools/browser/abc','ws://127.0.0.1:19435/devtools/browser/abc?redirect=1','http://127.0.0.1:19435/devtools/browser/abc','ws://127.0.0.1:19435/arbitrary'])assert.throws(()=>checkedSocket(bad,19435));
console.log('Endpoint identity checks passed (1 accepted, 7 rejected).');
