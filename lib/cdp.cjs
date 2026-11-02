'use strict';
function checkedSocket(value, port) {
  const url = new URL(value);
  if (url.protocol !== 'ws:' || url.hostname !== '127.0.0.1' || Number(url.port) !== port || url.username || url.password || url.search || url.hash || !/^\/devtools\/(browser|page)\/[\w-]+$/.test(url.pathname)) throw Error('Untrusted debugging endpoint');
  return url.href;
}
async function json(port, route, timeoutMs=4000) {
  const response = await fetch(`http://127.0.0.1:${port}${route}`, {signal: AbortSignal.timeout(timeoutMs), redirect:'error'});
  if (!response.ok) throw Error(`CDP HTTP ${response.status}`);
  return response.json();
}
async function connect(url,port,timeoutMs=5000) {
  const socket=new WebSocket(checkedSocket(url,port)), pending=new Map();let serial=0;
  await new Promise((resolve,reject)=>{const timer=setTimeout(()=>{socket.close();reject(Error('CDP connection timed out'));},timeoutMs);socket.addEventListener('open',()=>{clearTimeout(timer);resolve();},{once:true});socket.addEventListener('error',()=>{clearTimeout(timer);reject(Error('CDP connection failed'));},{once:true});});
  socket.addEventListener('message',event=>{let m;try{m=JSON.parse(event.data);}catch{return;}const p=pending.get(m.id);if(!p)return;pending.delete(m.id);clearTimeout(p.timer);m.error?p.reject(Error(m.error.message)):p.resolve(m.result);});
  socket.addEventListener('close',()=>{for(const p of pending.values()){clearTimeout(p.timer);p.reject(Error('CDP closed'));}pending.clear();});
  return {socket,call(method,params={},timeoutMs=15000){return new Promise((resolve,reject)=>{if(socket.readyState!==WebSocket.OPEN){reject(Error('CDP closed'));return;}const id=++serial;const timer=setTimeout(()=>{pending.delete(id);reject(Error(`CDP timeout: ${method}`));},timeoutMs);pending.set(id,{resolve,reject,timer});socket.send(JSON.stringify({id,method,params}));});},close(){socket.close();}};
}
async function appPages(port) {
  return (await json(port,'/json/list')).filter(t=>t.type==='page' && /^app:\/\/-\/index\.html(?:[?#]|$)/.test(t.url) && t.webSocketDebuggerUrl);
}
module.exports={checkedSocket,json,connect,appPages};
