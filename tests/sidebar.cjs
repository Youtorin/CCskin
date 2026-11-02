'use strict';
// Live, reversible layout check. Supply the themed session; no navigation or text entry occurs.
const fs=require('node:fs'),assert=require('node:assert/strict'),{json,appPages,connect}=require('../lib/cdp.cjs');
(async()=>{
 const state=JSON.parse(fs.readFileSync(process.argv[2],'utf8').replace(/^\uFEFF/,''));
 assert.equal((await json(state.port,'/json/version')).webSocketDebuggerUrl,state.browserSocket);
 let checked=0;
 for(const page of await appPages(state.port)){
  const c=await connect(page.webSocketDebuggerUrl,state.port);
  try{
   const result=await c.call('Runtime.evaluate',{awaitPromise:true,returnByValue:true,expression:`(async()=>{
    const footer=document.querySelector('#cc-account-footer');if(!footer)return null;
    const area=footer.parentElement,fr=footer.getBoundingClientRect();
    const scroller=[...area.querySelectorAll('*')].find(e=>/auto|scroll/.test(getComputedStyle(e).overflowY)&&e.scrollHeight>e.clientHeight);
    if(!scroller)throw Error('Expected overflowing sidebar for this regression test');
    const oldTop=scroller.scrollTop;let bottomHit=false;
    try{
     scroller.scrollTop=scroller.scrollHeight;
     const sr=scroller.getBoundingClientRect();
     const targets=[...scroller.querySelectorAll('a,button,[role=button]')].filter(e=>{const r=e.getBoundingClientRect();return r.width>0&&r.top>=sr.top&&r.bottom<=sr.bottom+1});
     const last=targets.at(-1),lr=last?.getBoundingClientRect();
     bottomHit=!!last&&last.contains(document.elementFromPoint(lr.x+lr.width/2,lr.y+lr.height/2));
     return {reserved:sr.bottom<=fr.top+1,bottomHit,atEnd:Math.abs(scroller.scrollHeight-scroller.clientHeight-scroller.scrollTop)<=1,footerHeight:fr.height,shadowLabel:!!document.querySelector('#cc-moonlight-extension')?.shadowRoot?.querySelector('#account-label')};
    }finally{scroller.scrollTop=oldTop;}
   })()`});
   if(!result.result?.value){if(result.exceptionDetails)throw Error(result.exceptionDetails.text);continue;}
   const r=result.result.value;
   assert.equal(r.reserved,true,'The scroll viewport must end above the footer');
   assert.equal(r.bottomHit,true,'Last visible sidebar entry must receive pointer input');
   assert.equal(r.atEnd,true,'Sidebar must reach its real scroll end');
   assert.equal(r.shadowLabel,false,'No global overlay label may cover native menus');
   assert.equal(r.footerHeight,52);checked++;
   console.log(JSON.stringify(r));
  }finally{c.close();}
 }
 assert.ok(checked,'No themed sidebar found');console.log('Live sidebar scrolling and hit-testing passed.');
})().catch(e=>{console.error(e);process.exitCode=1;});
