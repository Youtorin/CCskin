'use strict';
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const source=fs.readFileSync(path.join(__dirname,'../engine.cjs'),'utf8');
async function scenario(imageReady,fresh=false){
 const root=path.resolve(__dirname,'fixture-state'),stateFile=path.join(root,'session.json');
 const readyFile=path.join(root,'startup-'+ 'a'.repeat(32),'theme-ready');
 const session={port:19435,browserSocket:'ws://127.0.0.1:19435/devtools/browser/test'};
 const writes=[],errors=[];let finish;
 const finished=new Promise(resolve=>{finish=resolve});
 const c={socket:{addEventListener(){}},close(){},async call(method,params){
  assert.equal(method,'Runtime.evaluate');
  if(params.expression==='window.__ccMoonlight?.status()')return {result:{value:fresh?undefined:{installed:true,main:true,editor:true}}};
  if(params.expression.startsWith('Boolean(document.body'))return {result:{value:true}};
  if(params.expression.startsWith('(function installMoonlight')){
   assert.ok(params.expression.includes('"video":null'),'Defer video transfer until after installation');
   return {result:{value:{installed:true,main:true,editor:true}}};
  }
  if(params.expression.includes('localStorage.getItem'))return {result:{value:{intro:true,reducedMotion:false}}};
  if(params.expression.includes('i.decode()'))return {result:{value:imageReady}};
  throw Error('Unexpected evaluation');
 }};
 const lib={json:async()=>({webSocketDebuggerUrl:session.browserSocket}),appPages:async()=>[{webSocketDebuggerUrl:'ws://127.0.0.1:19435/devtools/page/test'}],connect:async url=>url===session.browserSocket?{...c,close:finish}:c};
 const fakeFs={readFileSync(file){if(file===stateFile)return JSON.stringify(session);if(file.endsWith('install.js'))return '(function installMoonlight(){})';if(file.endsWith('theme.css'))return '';if(file.endsWith('startup.mp4'))throw Error('Video must not be read on the critical startup path');return Buffer.from('image')},writeFileSync(file,data){writes.push({file,data})}};
 const sandbox={require(name){return name==='fs'?fakeFs:name==='path'?path:lib},__dirname:path.resolve(__dirname,'..'),console:{log(){}},setTimeout,clearTimeout,process:{argv:['node','engine','--session',stateFile,'--once','--ready-file',readyFile,'--no-intro'],on(){},set exitCode(value){errors.push(value);finish()}}};
 vm.runInNewContext(source,sandbox);
 const timer=setTimeout(()=>finish(),1000);
 await finished;clearTimeout(timer);
 assert.equal(errors.length,0,'Engine must complete without fatal error');
 assert.equal(writes.filter(w=>w.file===readyFile).length,imageReady?1:0,'Only acknowledge fully decoded themed images');
 assert.equal(writes.filter(w=>w.file===path.join(root,'launch-preferences.json')).length,1,'Persist intro/reduced-motion preference');
}
(async()=>{await scenario(false);await scenario(true);await scenario(true,true);console.log('Startup readiness checks passed, including same-cycle fresh installation without video transfer.');})().catch(error=>{console.error(error);process.exitCode=1});
