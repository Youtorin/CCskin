(function installMoonlight(payload) {
  'use strict';
  const VERSION='1.0.0', KEY='cc-moonlight-prefs-v1';
  if(window.__ccMoonlight?.version===VERSION&&window.__ccMoonlight.status().installed)return window.__ccMoonlight.status();
  window.__ccMoonlight?.destroy();
  const root=document.documentElement, reduced=matchMedia('(prefers-reduced-motion: reduce)'), dark=matchMedia('(prefers-color-scheme: dark)');
  const defaults={theme:'light',effects:'luxe',transparency:82,pet:true,art:true,focus:false,intro:true};
  let prefs={...defaults};try{prefs={...defaults,...JSON.parse(localStorage.getItem(KEY)||'{}')};}catch{}
  let paused=false,main=null,frame=0,last=0,rect={left:0,top:0,width:0,height:0},particles=[],bursts=[],destroyed=false,scanTimer=0,petTimer=0,moveStamp=0,currentView='home';
  const cleanups=[],codeNodes=new Set(),style=document.createElement('style');
  const wallpaper=document.createElement('div'),wallpaperImage=document.createElement('img');wallpaper.id='cc-wallpaper';wallpaper.setAttribute('aria-hidden','true');wallpaperImage.alt='';wallpaper.append(wallpaperImage);
  style.id='cc-moonlight-style';style.textContent=payload.css;document.head.append(style);
  const host=document.createElement('div');host.id='cc-moonlight-extension';document.body.append(host);
  host.style.cssText='position:fixed;inset:0;pointer-events:none;z-index:80;';
  const shadow=host.attachShadow({mode:'open'});
  shadow.innerHTML=`<style>
  :host{font-family:'Segoe UI','Microsoft YaHei',sans-serif;color:var(--cc-ink,#302c40);font-size:13px}*{box-sizing:border-box}[hidden]{display:none!important}button,input{font:inherit}button{cursor:pointer;border:1px solid var(--cc-line,#bba7cf55);color:inherit;background:rgba(var(--cc-panel,255,255,255),.93);border-radius:10px;padding:8px 12px}button:hover{box-shadow:0 0 20px #b494d435}button:focus-visible,input:focus-visible{outline:2px solid #a583ce;outline-offset:3px}
  #atmosphere{position:fixed;pointer-events:none;overflow:hidden;contain:strict}#stars{width:100%;height:100%;position:absolute;inset:0}.aurora{position:absolute;width:85%;height:65%;right:-20%;top:-10%;border-radius:50%;background:conic-gradient(from 30deg,transparent,#b395e23d,#b6dbe942,transparent,#ddc4f538,transparent);filter:blur(60px);animation:aurora 18s ease-in-out infinite alternate}.seal{position:absolute;width:min(45vw,620px);aspect-ratio:1;right:4%;top:10%;border:1px solid #b198d64d;border-radius:50%;animation:orbit 70s linear infinite}.seal:before{content:'';position:absolute;inset:7%;border:1px dashed #b198d64d;border-radius:50%}.seal:after{content:'✧';position:absolute;inset:19%;border:1px solid #b198d63d;transform:rotate(45deg);color:#b198d6;font-size:24px}.pointer{position:absolute;width:200px;height:200px;border-radius:50%;background:radial-gradient(#c1a4e32b,transparent 65%);transform:translate(-50%,-50%);opacity:0}
  #toolbar{position:fixed;left:360px;top:60px;bottom:auto;display:flex;gap:5px;pointer-events:auto}#toolbar button{box-shadow:0 4px 20px #3e28561a;font-size:12px}#open{letter-spacing:.04em}
  dialog{pointer-events:auto;position:fixed;margin:0;left:auto;right:20px;top:60px;max-height:calc(100dvh - 85px);width:340px;max-width:calc(100vw - 32px);overflow:auto;border:1px solid var(--cc-line,#bba7cf55);border-radius:20px;padding:22px;background:var(--cc-bg,#faf9fd);color:inherit;box-shadow:0 20px 80px #21132d40}dialog::backdrop{background:#251c3c29;backdrop-filter:blur(3px)}header{display:flex;align-items:center;justify-content:space-between;gap:8px}h2{font-size:17px;font-weight:600;margin:0}small{color:var(--cc-muted,#827b92);line-height:1.6}label{display:flex;justify-content:space-between;align-items:center;gap:12px;margin-top:20px}input[type=range]{width:100%;accent-color:#9673bd;margin-top:12px}input[type=checkbox]{accent-color:#9673bd;width:17px;height:17px}.choices{display:flex;gap:6px;margin-top:12px}.choices button{flex:1}.choices button[aria-pressed=true]{background:#a383cc24;border-color:#a383cc}.actions{display:flex;gap:8px;margin-top:22px;flex-wrap:wrap}.note{display:block;margin-top:15px}#pet{position:fixed;width:84px;height:100px;padding:0;border:0;background:none;pointer-events:auto;filter:drop-shadow(0 5px 10px #6c4d8c26);animation:breathe 5s ease-in-out infinite}#pet img{width:100%;height:100%;object-fit:contain}#pet-tip{position:fixed;max-width:190px;padding:10px 14px;border:1px solid var(--cc-line);background:var(--cc-bg,#faf9fd);color:inherit;border-radius:12px;font-size:12px;pointer-events:none}
  #intro{position:fixed;inset:0;background:#17121df5;pointer-events:auto;display:grid;place-items:center;z-index:4}video{width:min(100vw,1500px);max-height:100vh;object-fit:contain}#skip{position:absolute;right:30px;bottom:30px}#intro-note{position:absolute;top:25px;left:30px;color:#f3eafa;font-size:12px}#intro-error{position:absolute;color:white;text-align:center;top:45%;left:20%;right:20%}
  @keyframes aurora{to{transform:translate(-12%,18%) rotate(40deg) scale(1.1)}}@keyframes orbit{to{transform:rotate(360deg)}}@keyframes breathe{50%{transform:translateY(-4px)}}
  :host([data-view=chat]) #atmosphere{opacity:.55}:host([data-effects=soft]) .seal,:host([data-effects=soft]) .pointer{display:none}:host([data-effects=soft]) .aurora{opacity:.3}:host([data-motion=false]) #atmosphere{display:none}:host([data-motion=false]) #pet{animation:none}
  @media(max-width:750px){#pet{display:none}#toolbar button{padding:6px 9px;font-size:11px}}
  @media(prefers-reduced-motion:reduce){*{animation:none!important}#atmosphere{display:none}}
  </style>
  <div id="atmosphere" aria-hidden="true"><div class="aurora"></div><div class="seal"></div><div class="pointer"></div><canvas id="stars"></canvas></div>
  <div id="toolbar"><button id="open" title="月白龙语外观设置">✧ 月白龙语</button><button id="focus" aria-label="切换专注模式" aria-pressed="false">专注</button></div>
  <button id="pet" aria-label="小龙互动"><span id="pet-sprite" role="img" aria-label="ChatGPT 银白龙裔动画"></span></button><div id="pet-tip" role="status" hidden></div>
  <dialog id="settings" aria-label="月白龙语外观设置"><header><h2>月白龙语 · 星辉</h2><button id="close" aria-label="关闭设置">×</button></header><small>原生界面主题扩展 · 1.0.0</small>
  <label>配色</label><div class="choices" id="themes"><button data-theme="light">月白</button><button data-theme="night">暮紫</button><button data-theme="system">系统</button></div>
  <label>氛围动效</label><div class="choices" id="effects"><button data-effect="off">静谧</button><button data-effect="soft">轻盈</button><button data-effect="luxe">华丽</button></div>
  <label for="alpha">面板透明度 <output id="alpha-value"></output></label><input id="alpha" type="range" min="0" max="100" value="82">
  <label for="art">显示背景立绘<input id="art" type="checkbox"></label><label for="pet-enabled">显示小龙<input id="pet-enabled" type="checkbox"></label><label for="intro-enabled">启动时播放片头<input id="intro-enabled" type="checkbox"></label>
  <div class="actions"><button id="replay">播放片头</button><button id="reset">恢复默认</button><button id="pause">暂停主题</button></div><small class="note">专注模式暂停氛围动效。设置只保存在此主题实例中。恢复官方外观并关闭调试端口，请使用随附的恢复脚本。</small></dialog>
  <div id="intro" hidden role="dialog" aria-modal="true" aria-label="龙娘启动片头"><span id="intro-note">CC / MOONLIGHT · 8s</span><video muted playsinline preload="none"></video><div id="intro-error" hidden>视频暂未播放。<button id="retry-video">点击播放</button></div><button id="skip">跳过片头 →</button></div>`;
  const $=id=>shadow.getElementById(id),canvas=$('stars'),ctx=canvas.getContext('2d'),video=shadow.querySelector('video'),dialog=$('settings');
  const sprite=$('pet-sprite');sprite.style.cssText=`display:block;width:96px;height:104px;background-image:url("${payload.assets.pet}");background-size:768px 1144px;background-repeat:no-repeat;`;
  $('pet').style.width='96px';$('pet').style.height='104px';
  let spriteTimer=0,spriteFrame=0,spriteRow=0,spriteUntil=0;
  function spriteTick(){
    clearTimeout(spriteTimer);if(destroyed)return;
    const animate=!paused&&!prefs.focus&&prefs.pet&&prefs.effects!=='off'&&!reduced.matches&&!document.hidden&&$('intro').hidden;
    if(performance.now()>spriteUntil)spriteRow=0;
    const frames=spriteRow===4?5:spriteRow===3?4:6;
    spriteFrame=animate?(spriteFrame+1)%frames:0;
    sprite.style.backgroundPosition=`${-spriteFrame*96}px ${-spriteRow*104}px`;
    const idleTiming=[280,110,110,140,140,320];
    spriteTimer=setTimeout(spriteTick,animate?(spriteRow?160:idleTiming[spriteFrame]*6):1000);
  }
  function petAction(row){if(reduced.matches||prefs.effects==='off'||paused)return;spriteRow=row;spriteUntil=performance.now()+1600;spriteFrame=0;spriteTick();}
  function on(target,event,fn,options){target.addEventListener(event,fn,options);cleanups.push(()=>target.removeEventListener(event,fn,options));}
  function save(){try{localStorage.setItem(KEY,JSON.stringify(prefs));}catch{}}
  function effectiveTheme(){return prefs.theme==='system'?(dark.matches?'night':'light'):prefs.theme;}
  function moving(){return !!main&&!paused&&!destroyed&&!document.hidden&&!reduced.matches&&!prefs.focus&&prefs.effects!=='off'&&$('intro').hidden;}
  function apply(){
    prefs.theme=['light','night','system'].includes(prefs.theme)?prefs.theme:'light';prefs.effects=['off','soft','luxe'].includes(prefs.effects)?prefs.effects:'luxe';prefs.transparency=Number.isFinite(+prefs.transparency)?Math.max(0,Math.min(100,+prefs.transparency)):82;
    root.dataset.ccTheme=effectiveTheme();root.dataset.ccFocus=String(!!prefs.focus);root.dataset.ccArt=String(!!prefs.art);root.style.setProperty('--cc-panel-alpha',1-prefs.transparency/100);root.style.setProperty('--cc-home-image',`url("${payload.assets.home}")`);root.style.setProperty('--cc-chat-image',`url("${payload.assets.chat}")`);
    host.dataset.effects=prefs.effects;host.dataset.motion=String(moving());$('alpha').value=prefs.transparency;$('alpha-value').value=prefs.transparency+'%';$('art').checked=!!prefs.art;$('pet-enabled').checked=!!prefs.pet;$('intro-enabled').checked=!!prefs.intro;$('pet').hidden=!prefs.pet||prefs.focus||!main;$('focus').setAttribute('aria-pressed',String(!!prefs.focus));$('focus').textContent=prefs.focus?'退出专注':'专注';
    shadow.querySelectorAll('[data-theme]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.theme===prefs.theme)));shadow.querySelectorAll('[data-effect]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.effect===prefs.effects)));if(paused){root.removeAttribute('data-cc-theme');$('atmosphere').hidden=true;$('pet').hidden=true;}save();syncAnimation();
  }
  function measure(){
    if(!main)return;const r=main.getBoundingClientRect();rect={left:r.left,top:r.top,width:r.width,height:r.height};
    Object.assign($('atmosphere').style,{left:r.left+'px',top:r.top+'px',width:r.width+'px',height:r.height+'px'});
    Object.assign($('toolbar').style,{left:(r.left+18)+'px',top:(r.top+52)+'px',bottom:'auto'});
    const dpr=Math.min(devicePixelRatio||1,1.5);canvas.width=Math.round(r.width*dpr);canvas.height=Math.round(r.height*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);
    particles=Array.from({length:Math.min(60,Math.max(20,Math.floor(r.width*r.height/24000)))},()=>({x:Math.random()*r.width,y:Math.random()*r.height,r:.7+Math.random()*1.7,v:5+Math.random()*12,p:Math.random()*6.28}));
    const left=Math.max(r.left,r.right-105),top=Math.max(r.top+60,r.bottom-170);Object.assign($('pet').style,{left:left+'px',top:top+'px'});Object.assign($('pet-tip').style,{right:Math.max(16,innerWidth-r.right+24)+'px',top:Math.max(r.top,top-52)+'px'});
  }
  const resize=new ResizeObserver(measure);
  function scan(){
    scanTimer=0;if(destroyed)return;
    const surfaces=[...document.querySelectorAll('main[class*="_MainContentSurface_"]')].filter(el=>{const r=el.getBoundingClientRect();return r.width>200&&r.height>100;});
    const next=surfaces.find(el=>el.querySelector('[contenteditable="true"]'))||surfaces.at(-1)||null;
    if(next!==main){if(main){main.removeAttribute('data-cc-surface');resize.unobserve(main);}main=next;if(main){main.dataset.ccSurface='true';main.append(wallpaper);resize.observe(main);measure();}}
    currentView=[...main?.querySelectorAll('[data-composer-placement="home"],[data-testid="home-icon"]')||[]].some(el=>el.getBoundingClientRect().width>0)?'home':'chat';root.dataset.ccView=currentView;host.dataset.view=currentView;
    const artSource=currentView==='home'?payload.assets.home:payload.assets.chat;if(wallpaperImage.getAttribute('src')!==artSource)wallpaperImage.src=artSource;
    for(const pre of main?.querySelectorAll('pre')||[]){const block=pre.parentElement;if(block&&!codeNodes.has(block)){block.dataset.ccCode='true';codeNodes.add(block);}}
    for(const node of codeNodes)if(!node.isConnected)codeNodes.delete(node);
    $('pet').hidden=paused||!prefs.pet||prefs.focus||!main;const wasMoving=host.dataset.motion==='true';host.dataset.motion=String(moving());if(wasMoving!==moving())syncAnimation();
  }
  const observer=new MutationObserver(records=>{if(records.some(r=>!host.contains(r.target)&&r.target!==style)&&!scanTimer)scanTimer=setTimeout(scan,180);});observer.observe(document.body,{childList:true,subtree:true});
  const layoutPoll=setInterval(scan,1500);
  function star(x,y,r,a){ctx.globalAlpha=Math.max(0,a);ctx.beginPath();ctx.moveTo(x,y-r*2.5);ctx.lineTo(x+r*.6,y-r*.6);ctx.lineTo(x+r*2.5,y);ctx.lineTo(x+r*.6,y+r*.6);ctx.lineTo(x,y+r*2.5);ctx.lineTo(x-r*.6,y+r*.6);ctx.lineTo(x-r*2.5,y);ctx.lineTo(x-r*.6,y-r*.6);ctx.closePath();ctx.fill();}
  function draw(time){frame=0;if(!moving())return;if(time-last<32){frame=requestAnimationFrame(draw);return;}const dt=Math.min((time-last)/1000,.06);last=time;ctx.clearRect(0,0,rect.width,rect.height);ctx.fillStyle=effectiveTheme()==='night'?'#dfc9ff':'#9e7ec3';const count=prefs.effects==='soft'?Math.ceil(particles.length/3):particles.length;for(let i=0;i<count;i++){const p=particles[i];p.y-=p.v*dt;if(p.y< -8){p.y=rect.height+8;p.x=Math.random()*rect.width;}star(p.x,p.y,p.r,.15+.3*(.5+.5*Math.sin(time/1700+p.p)));}bursts=bursts.filter(b=>b.life>0);for(const b of bursts){b.life-=dt;b.x+=b.vx*dt;b.y+=b.vy*dt;b.vy+=15*dt;star(b.x,b.y,b.r,b.life/b.max);}ctx.globalAlpha=1;frame=requestAnimationFrame(draw);}
  function syncAnimation(){cancelAnimationFrame(frame);frame=0;if(moving()){last=performance.now();frame=requestAnimationFrame(draw);}else{bursts=[];ctx.clearRect(0,0,rect.width,rect.height);}}
  function emit(x,y,count,speed){if(!moving()||prefs.effects!=='luxe')return;for(let i=0;i<count;i++){const a=Math.random()*Math.PI*2,life=.45+Math.random()*.65;bursts.push({x,y,vx:Math.cos(a)*speed,vy:Math.sin(a)*speed,r:1+Math.random()*1.5,life,max:life});}if(bursts.length>100)bursts.splice(0,bursts.length-100);}
  on(document,'pointermove',e=>{if(!main||!moving()||prefs.effects!=='luxe')return;const x=e.clientX-rect.left,y=e.clientY-rect.top;if(x<0||y<0||x>rect.width||y>rect.height)return;Object.assign(shadow.querySelector('.pointer').style,{left:x+'px',top:y+'px',opacity:'1'});if(performance.now()-moveStamp>65){emit(x,y,1,8);moveStamp=performance.now();}},{passive:true});
  on(document,'click',e=>{if(e.composedPath().includes(host))return;emit(e.clientX-rect.left,e.clientY-rect.top,16,55);},{passive:true});
  function suspend(){paused=true;dialog.close();$('open').textContent='✧ 恢复月白';apply();}
  function resume(){paused=false;$('open').textContent='✧ 月白龙语';$('atmosphere').hidden=false;apply();}
  on($('open'),'click',()=>{if(paused)resume();dialog.showModal();});on($('close'),'click',()=>dialog.close());on($('focus'),'click',()=>{prefs.focus=!prefs.focus;apply();});
  for(const b of shadow.querySelectorAll('[data-theme]'))on(b,'click',()=>{prefs.theme=b.dataset.theme;apply();});for(const b of shadow.querySelectorAll('[data-effect]'))on(b,'click',()=>{prefs.effects=b.dataset.effect;apply();});
  on($('alpha'),'input',()=>{prefs.transparency=+$('alpha').value;apply();});for(const [id,key]of[['art','art'],['pet-enabled','pet'],['intro-enabled','intro']])on($(id),'change',()=>{prefs[key]=$(id).checked;apply();});on($('reset'),'click',()=>{prefs={...defaults};apply();});
  on($('pet'),'pointerenter',()=>petAction(3));
  on($('pet'),'click',e=>{petAction(4);emit(e.clientX-rect.left,e.clientY-rect.top,32,70);$('pet-tip').textContent='小龙陪伴已就绪';$('pet-tip').hidden=false;clearTimeout(petTimer);petTimer=setTimeout(()=>$('pet-tip').hidden=true,2400);});
  let pendingIntro=false,introTimer=0,previousFocus=null,inertElements=[];
  function finishIntro(){clearTimeout(introTimer);video.pause();$('intro').hidden=true;for(const [el,old]of inertElements)if(el.isConnected)el.inert=old;inertElements=[];previousFocus?.focus?.();apply();}
  function playIntro(){if(reduced.matches)return;if(document.hidden){pendingIntro=true;return;}pendingIntro=false;dialog.close();previousFocus=document.activeElement;inertElements=[...document.body.children].filter(e=>e!==host&&e.tagName!=='SCRIPT'&&e.tagName!=='STYLE').map(e=>[e,e.inert]);for(const [el]of inertElements)el.inert=true;$('intro').hidden=false;$('intro-error').hidden=true;video.src=payload.assets.video;video.currentTime=0;$('skip').focus();apply();video.muted=true;video.play().catch(error=>{video.dataset.playError=error.message;$('intro-error').hidden=false;});introTimer=setTimeout(finishIntro,15000);}
  on($('retry-video'),'click',()=>{video.play().then(()=>$('intro-error').hidden=true).catch(()=>{});});on($('skip'),'click',finishIntro);on(video,'ended',finishIntro);on(video,'error',()=>$('intro-error').hidden=false);on($('replay'),'click',playIntro);on(shadow,'keydown',e=>{if(!$('intro').hidden){if(e.key==='Escape'||e.key==='Enter'||e.key===' '){e.preventDefault();finishIntro();}else if(e.key==='Tab'){e.preventDefault();$('skip').focus();}}});
  on(document,'visibilitychange',()=>{if(pendingIntro&&!document.hidden)playIntro();host.dataset.motion=String(moving());syncAnimation();});on(reduced,'change',apply);on(dark,'change',apply);on(window,'resize',measure);
  function destroy(){if(destroyed)return;if(!$('intro').hidden)finishIntro();destroyed=true;clearTimeout(spriteTimer);clearInterval(layoutPoll);cancelAnimationFrame(frame);clearTimeout(scanTimer);clearTimeout(petTimer);clearTimeout(introTimer);observer.disconnect();resize.disconnect();cleanups.forEach(fn=>fn());main?.removeAttribute('data-cc-surface');for(const node of codeNodes)node.removeAttribute('data-cc-code');for(const key of ['ccTheme','ccFocus','ccArt','ccView'])delete root.dataset[key];for(const key of ['--cc-panel-alpha','--cc-home-image','--cc-chat-image'])root.style.removeProperty(key);wallpaper.remove();style.remove();host.remove();delete window.__ccMoonlight;}
  function status(){return {version:VERSION,installed:host.isConnected&&style.isConnected,paused,view:currentView,main:!!main,editor:!!main?.querySelector('[contenteditable="true"]'),effects:prefs.effects,theme:effectiveTheme(),intro:!$('intro').hidden};}
  window.__ccMoonlight={version:VERSION,status,destroy,suspend,resume,configure(values){for(const key of Object.keys(defaults))if(Object.hasOwn(values,key))prefs[key]=values[key];apply();return status();},playIntro,finishIntro};
  on($('pause'),'click',suspend);
  scan();apply();spriteTick();
  if(payload.playIntro&&prefs.intro&&!reduced.matches)setTimeout(()=>{if(!destroyed)playIntro();},400);
  return status();
})
