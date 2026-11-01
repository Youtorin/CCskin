'use strict';
const fs=require('fs'),path=require('path'),{json,connect,appPages}=require('./lib/cdp.cjs');
const args=process.argv.slice(2),value=name=>args[args.indexOf(name)+1];
const statePath=value('--session');
if(!args.includes('--session')||!path.isAbsolute(statePath))throw Error('An absolute --session path is required');
const session=JSON.parse(fs.readFileSync(statePath,'utf8').replace(/^\uFEFF/,'')),port=Number(session.port);
if(!Number.isInteger(port)||port<1024||port>65535)throw Error('Invalid port');
const log=event=>console.log(JSON.stringify({time:new Date().toISOString(),...event}));
const readyFile=args.includes('--ready-file')?value('--ready-file'):null;
if(readyFile && (!path.isAbsolute(readyFile) || path.dirname(path.dirname(readyFile))!==path.dirname(statePath) || !/^startup-[a-f0-9]{32}$/.test(path.basename(path.dirname(readyFile))) || path.basename(readyFile)!=='theme-ready'))throw Error('Invalid startup handshake path');
let readyReported=false,launchPreferences=null;
let anchor,stopped=false,payload;
function bundle(){
 if(payload)return payload;
 const data=(name,mime)=>`data:${mime};base64,${fs.readFileSync(path.join(__dirname,'assets',name)).toString('base64')}`;
 payload={css:fs.readFileSync(path.join(__dirname,'runtime/theme.css'),'utf8'),assets:{home:data('home.webp','image/webp'),chat:data('chat.png','image/png'),pet:data('spritesheet.webp','image/webp'),video:data('startup.mp4','video/mp4')},playIntro:!args.includes('--no-intro')};return payload;
}
async function install(target){
 const c=await connect(target.webSocketDebuggerUrl,port);
 try{
  if(args.includes('--restore')){await c.call('Runtime.evaluate',{expression:'window.__ccMoonlight?.destroy()',returnByValue:true});return;}
  const status=await c.call('Runtime.evaluate',{expression:'window.__ccMoonlight?.status()',returnByValue:true});
  if(status.result?.value?.installed){
   const preferences=await c.call('Runtime.evaluate',{expression:'(()=>{let p={};try{p=JSON.parse(localStorage.getItem("cc-moonlight-prefs-v1")||"{}")}catch{}return {intro:p.intro!==false,reducedMotion:matchMedia("(prefers-reduced-motion: reduce)").matches}})()',returnByValue:true});
   const serialized=JSON.stringify(preferences.result?.value);
   if(serialized&&serialized!==launchPreferences){fs.writeFileSync(path.join(path.dirname(statePath),'launch-preferences.json'),serialized);launchPreferences=serialized;}
   if(readyFile&&!readyReported){
    const ready=await c.call('Runtime.evaluate',{expression:'(async()=>{const s=window.__ccMoonlight?.status();const images=[...document.querySelectorAll("#cc-wallpaper img")];if(!s?.main||!s?.editor||images.length<2||images.some(i=>!i.complete||!i.naturalWidth))return false;await Promise.all(images.map(i=>i.decode()));return true})()',awaitPromise:true,returnByValue:true});
    if(ready.result?.value===true){fs.writeFileSync(readyFile,'ready');readyReported=true;log({event:'startup-theme-ready'});}
   }
   return status.result.value;
  }
  const ready=await c.call('Runtime.evaluate',{expression:'Boolean(document.body && document.querySelector("main") && document.querySelector(".app-shell-left-panel,[data-codex-composer]"))',returnByValue:true});
  if(!ready.result?.value)return {waiting:true};
  const expression=fs.readFileSync(path.join(__dirname,'runtime/install.js'),'utf8')+'('+JSON.stringify(bundle())+')';
  const result=await c.call('Runtime.evaluate',{expression,returnByValue:true});
  if(result.exceptionDetails)throw Error(result.exceptionDetails.exception?.description||result.exceptionDetails.text);
  const installed=result.result?.value;if(!installed?.installed)throw Error('Theme did not report successful installation');
  bundle().playIntro=false;log({event:'installed',...installed});return installed;
 }finally{c.close();}
}
async function main(){
 const version=await json(port,'/json/version');
 if(version.webSocketDebuggerUrl!==session.browserSocket)throw Error('Debugging session identity changed');
 anchor=await connect(session.browserSocket,port);anchor.socket.addEventListener('close',()=>{stopped=true;});
 if(args.includes('--restore')){for(const t of await appPages(port))await install(t);if(args.includes('--close'))await anchor.call('Browser.close').catch(()=>{});anchor.close();log({event:'restored'});return;}
 let failures=0,reported=false;
 do {
  try{const pages=await appPages(port);let installed=false;for(const t of pages){if(stopped)break;const s=await install(t);installed=installed||!!s?.installed;}if(!installed&&!reported){log({event:'waiting-for-native-shell'});reported=true;}failures=0;if(args.includes('--once'))break;}
  catch(e){log({event:'error',message:e.message});if(++failures>=5||args.includes('--once'))throw e;}
  if(!stopped)await new Promise(r=>setTimeout(r,2000));
 }while(!stopped);
 anchor.close();
}
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>{stopped=true;anchor?.close();});
main().catch(e=>{log({event:'fatal',message:e.message});anchor?.close();process.exitCode=1;});
