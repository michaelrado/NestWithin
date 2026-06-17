// The /nirvana admin console — a self-contained, dependency-free HTML page.
// It talks to /api/admin/* with a Bearer admin token kept in localStorage.
// (Client JS deliberately avoids template literals/backticks so it nests
// safely inside this server-side template string.)

export const ADMIN_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>Nirvana · The Nest Admin</title>
<style>
  :root{--blue:#4A72B0;--deep:#34527F;--cream:#F7F3EB;--creamD:#EFE7D8;
        --ink:#2B3A52;--soft:#5C6B82;--sand:#E7DCC8;--clay:#D79A77;--sage:#8FA98C;}
  *{box-sizing:border-box}
  body{margin:0;font-family:-apple-system,Segoe UI,Roboto,sans-serif;background:var(--cream);color:var(--ink)}
  header{background:linear-gradient(180deg,var(--deep),var(--blue));color:#fff;padding:18px 24px;display:flex;align-items:center;gap:12px}
  header h1{font-size:18px;margin:0;font-weight:700;letter-spacing:.3px}
  header .sp{flex:1}
  header button{background:rgba(255,255,255,.18);color:#fff;border:0;padding:8px 14px;border-radius:18px;cursor:pointer;font-weight:600}
  main{max-width:1040px;margin:0 auto;padding:24px}
  .card{background:#fff;border-radius:18px;padding:18px 20px;box-shadow:0 1px 3px rgba(0,0,0,.05)}
  .login{max-width:380px;margin:64px auto;text-align:center}
  .login input{width:100%;padding:12px 14px;border:1px solid var(--sand);border-radius:12px;margin:12px 0;font-size:16px}
  .btn{background:var(--blue);color:#fff;border:0;padding:12px 20px;border-radius:24px;cursor:pointer;font-weight:700;font-size:15px}
  .btn.sm{padding:7px 14px;font-size:13px;border-radius:16px}
  .btn.warn{background:var(--clay)}
  .btn.ghost{background:var(--creamD);color:var(--deep)}
  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:14px;margin-bottom:20px}
  .stat{background:#fff;border-radius:18px;padding:18px;box-shadow:0 1px 3px rgba(0,0,0,.05)}
  .stat .n{font-size:30px;font-weight:800;color:var(--deep)}
  .stat .l{color:var(--soft);font-size:13px;margin-top:2px}
  h2{font-size:16px;color:var(--deep);margin:24px 0 10px}
  .two{display:grid;grid-template-columns:1fr 1fr;gap:16px}
  @media(max-width:760px){.two{grid-template-columns:1fr}}
  ul.rows{list-style:none;margin:0;padding:0}
  ul.rows li{display:flex;align-items:center;gap:10px;padding:9px 0;border-bottom:1px solid var(--cream)}
  ul.rows li:last-child{border-bottom:0}
  .rank{width:22px;color:var(--clay);font-weight:800;text-align:center}
  .muted{color:var(--soft);font-size:13px}
  .bar{height:8px;border-radius:6px;background:var(--creamD);overflow:hidden;flex:1;margin:0 8px}
  .bar>i{display:block;height:100%;background:var(--blue)}
  table{width:100%;border-collapse:collapse;font-size:14px}
  th,td{text-align:left;padding:10px 8px;border-bottom:1px solid var(--cream)}
  th{color:var(--soft);font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.4px}
  .tag{display:inline-block;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:700}
  .tag.on{background:#e7f0e6;color:#3c6b3a}
  .tag.off{background:#f6ddd2;color:#a84e2a}
  .tag.demo{background:var(--creamD);color:var(--soft)}
  .tag.adm{background:var(--blue);color:#fff}
  .tag.unv{background:#f3ecd6;color:#9a7d2e}
  .err{color:#a84e2a;margin-top:8px;min-height:18px}
  .hidden{display:none}
</style>
</head>
<body>
<header>
  <span style="font-size:22px">🌿</span>
  <h1>Nirvana · The Nest Admin</h1>
  <span class="sp"></span>
  <button id="logout" class="hidden" onclick="logout()">Sign out</button>
</header>
<main>
  <div id="loginView" class="login card">
    <h2 style="margin-top:0">Admin sign in</h2>
    <p class="muted">Sign in with your admin email and password.</p>
    <input id="adminEmail" type="email" placeholder="Admin email" autocomplete="username">
    <input id="pw" type="password" placeholder="Password" autocomplete="current-password" onkeydown="if(event.key==='Enter')login()">
    <button class="btn" onclick="login()">Enter</button>
    <div id="loginErr" class="err"></div>
  </div>

  <div id="dash" class="hidden">
    <div id="stats" class="grid"></div>
    <div class="two">
      <div class="card">
        <h2 style="margin-top:0">Most active users</h2>
        <ul id="topUsers" class="rows"></ul>
      </div>
      <div class="card">
        <h2 style="margin-top:0">Most popular activities</h2>
        <ul id="popular" class="rows"></ul>
      </div>
    </div>
    <h2>Users</h2>
    <div class="card" style="margin-bottom:14px">
      <b>Add an admin</b>
      <div style="display:flex;gap:8px;margin-top:10px;flex-wrap:wrap">
        <input id="adName" placeholder="Name" style="flex:1;min-width:120px;padding:10px 12px;border:1px solid var(--sand);border-radius:10px">
        <input id="adEmail" type="email" placeholder="Email" style="flex:2;min-width:160px;padding:10px 12px;border:1px solid var(--sand);border-radius:10px">
        <button class="btn sm" onclick="addAdmin()">Add admin &amp; email them</button>
      </div>
      <div id="adMsg" class="muted" style="margin-top:8px;min-height:16px"></div>
    </div>
    <div class="card" style="overflow-x:auto">
      <table>
        <thead><tr><th>Name</th><th>Email</th><th>Joined</th><th>Sessions</th><th>Status</th><th></th></tr></thead>
        <tbody id="userRows"></tbody>
      </table>
    </div>
  </div>
</main>

<script>
var PN = {
  'grounding':'5-4-3-2-1 Grounding','box-breath':'Box Breath','sigh':'Physiological Sigh',
  'four78':'4-7-8 for Sleep','coherent':'Coherent Breathing','bodyscan':'Gentle Body Scan',
  'soundbath':'Sound Healing Bath','lovingkindness':'Loving-Kindness','shake':'Shake It Off',
  'gratitude':'Three Good Things','restore':'Legs Up the Wall','intention':'Set an Intention',
  'holdme':'Hold Me For Five Minutes'
};
function pname(id){return PN[id]||id;}
function esc(s){return String(s==null?'':s).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];});}
function token(){return localStorage.getItem('nirvana_token');}
function setToken(t){localStorage.setItem('nirvana_token',t);}
function clearToken(){localStorage.removeItem('nirvana_token');}

function show(authed){
  document.getElementById('loginView').classList.toggle('hidden',authed);
  document.getElementById('dash').classList.toggle('hidden',!authed);
  document.getElementById('logout').classList.toggle('hidden',!authed);
}

async function api(path,opts){
  opts = opts||{};
  opts.headers = Object.assign({'Content-Type':'application/json','Authorization':'Bearer '+token()},opts.headers||{});
  var r = await fetch('/api/admin'+path,opts);
  if(r.status===401||r.status===403){ clearToken(); show(false); throw new Error('unauthorized'); }
  return r.json();
}

async function login(){
  var pw = document.getElementById('pw').value;
  var email = document.getElementById('adminEmail').value.trim();
  var err = document.getElementById('loginErr');
  err.textContent='';
  var body = email ? {email:email, password:pw} : {password:pw};
  try{
    var r = await fetch('/api/admin/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
    var j = await r.json();
    if(!r.ok){
      err.textContent = j.error==='admin_not_configured' ? 'Admin is not configured on the server.'
        : (j.error==='account_disabled' ? 'This admin account is disabled.' : 'Incorrect email or password.');
      return;
    }
    setToken(j.token); document.getElementById('pw').value=''; show(true); loadAll();
  }catch(e){ err.textContent='Could not reach the server.'; }
}

async function addAdmin(){
  var name = document.getElementById('adName').value.trim();
  var email = document.getElementById('adEmail').value.trim();
  var msg = document.getElementById('adMsg');
  if(!email){ msg.textContent='Enter an email address.'; return; }
  msg.textContent='Adding…';
  try{
    var r = await api('/admins',{method:'POST',body:JSON.stringify({name:name,email:email})});
    msg.textContent = r.emailed
      ? ('Done — '+(r.created?'created':'promoted')+' '+email+' and sent a welcome email.')
      : ('Saved '+email+', but the email failed: '+(r.mailError||'unknown'));
    document.getElementById('adName').value=''; document.getElementById('adEmail').value='';
    loadAll();
  }catch(e){ msg.textContent='Could not add admin.'; }
}
function logout(){ clearToken(); show(false); }

async function loadAll(){ await loadStats(); await loadUsers(); }

async function loadStats(){
  var s = await api('/stats');
  var cards = [
    ['Total signups', s.signupsTotal],
    ['New (7 days)', s.signups7d],
    ['New today', s.signupsToday],
    ['Disabled', s.disabledCount],
    ['Sessions logged', s.totalSessions]
  ];
  document.getElementById('stats').innerHTML = cards.map(function(c){
    return '<div class="stat"><div class="n">'+c[1]+'</div><div class="l">'+c[0]+'</div></div>';
  }).join('');

  var maxU = (s.topUsers[0]&&s.topUsers[0].sessions)||1;
  document.getElementById('topUsers').innerHTML = s.topUsers.length? s.topUsers.map(function(u,i){
    var nm = u.anonymous?'Anonymous':esc(u.name);
    return '<li><span class="rank">'+(i+1)+'</span><div style="min-width:120px">'+nm+(u.is_demo?' <span class="tag demo">demo</span>':'')+'</div>'+
      '<div class="bar"><i style="width:'+Math.round(u.sessions/maxU*100)+'%"></i></div><b>'+u.sessions+'</b></li>';
  }).join('') : '<li class="muted">No activity yet.</li>';

  var maxP = (s.popular[0]&&s.popular[0].count)||1;
  document.getElementById('popular').innerHTML = s.popular.length? s.popular.map(function(p,i){
    return '<li><span class="rank">'+(i+1)+'</span><div style="min-width:140px">'+esc(pname(p.practiceId))+'</div>'+
      '<div class="bar"><i style="width:'+Math.round(p.count/maxP*100)+'%"></i></div><b>'+p.count+'</b></li>';
  }).join('') : '<li class="muted">No activity yet.</li>';
}

async function loadUsers(){
  var data = await api('/users');
  document.getElementById('userRows').innerHTML = data.users.map(function(u){
    var status = u.disabled? '<span class="tag off">disabled</span>'
      : (u.email_verified? '<span class="tag on">active</span>' : '<span class="tag unv">unverified</span>');
    if(u.is_admin) status += ' <span class="tag adm">admin</span>';
    if(u.is_demo) status += ' <span class="tag demo">demo</span>';
    var btn = u.is_demo ? '' :
      '<button class="btn sm '+(u.disabled?'ghost':'warn')+'" onclick="toggleDisable('+u.id+','+(u.disabled?0:1)+')">'+(u.disabled?'Enable':'Disable')+'</button>';
    return '<tr><td>'+esc(u.name)+(u.anonymous?' <span class="muted">(anon)</span>':'')+'</td>'+
      '<td class="muted">'+esc(u.email)+'</td>'+
      '<td class="muted">'+esc((u.created_at||'').slice(0,10))+'</td>'+
      '<td>'+u.sessions+'</td><td>'+status+'</td><td style="text-align:right">'+btn+'</td></tr>';
  }).join('');
}

async function toggleDisable(id,disabled){
  await api('/users/'+id+'/disable',{method:'POST',body:JSON.stringify({disabled:!!disabled})});
  loadAll();
}

if(token()){ show(true); loadAll().catch(function(){}); } else { show(false); }
</script>
</body>
</html>`;
