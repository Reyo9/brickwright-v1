// Admin dashboard (only works for ADMIN_EMAILS accounts — the server checks).
(function(){
  'use strict';
  var esc = function(s){ return String(s == null ? '' : s).replace(/[&<>"']/g, function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; }); };
  var sum = function(a){ return a.reduce(function(x, y){ return x + y; }, 0); };
  var last = function(a){ return a[a.length - 1] || 0; };
  var pct = function(a, b){ return b ? Math.round(a / b * 100) + '%' : '—'; };
  var ago = function(t){ var s = Math.round((Date.now() - t) / 1000); return s < 60 ? s + 's ago' : s < 3600 ? Math.round(s / 60) + 'm ago' : s < 86400 ? Math.round(s / 3600) + 'h ago' : Math.round(s / 86400) + 'd ago'; };

  function kpi(label, today, week, cls){
    return '<div class="kpi ' + (cls || '') + '"><span>' + label + '</span><b>' + Number(today).toLocaleString() + '</b><small>' + Number(week).toLocaleString() + ' in 7 days</small></div>';
  }
  function chart(d){
    var s = d.series, max = 1;
    d.days.forEach(function(_, i){ max = Math.max(max, s.builds_done[i] + s.builds_failed[i] + s.busy[i]); });
    var bars = d.days.map(function(day, i){
      var ok = s.builds_done[i], fail = Math.max(0, s.builds_failed[i] - s.busy[i]), busy = s.busy[i], tot = ok + fail + busy;
      var h = function(n){ return (n / max * 150) + 'px'; };
      return '<div class="bar" style="height:' + h(tot) + '" data-tip="' + day.slice(5) + ': ' + ok + ' ok, ' + fail + ' failed, ' + busy + ' busy">' +
        '<i class="ok" style="height:' + h(ok) + '"></i><i class="fail" style="height:' + h(fail) + '"></i><i class="busy" style="height:' + h(busy) + '"></i></div>';
    }).join('');
    var labels = d.days.map(function(day, i){ return '<span>' + (i % 2 ? '' : day.slice(8)) + '</span>'; }).join('');
    return '<div class="chart">' + bars + '</div><div class="xl">' + labels + '</div>' +
      '<div class="legend"><span><i style="background:var(--good)"></i>Finished</span><span><i style="background:#ff6b6b"></i>Failed</span><span><i style="background:#ffb547"></i>Busy (429)</span></div>';
  }
  function users(list){
    if (!list.length) return '<p class="muted small">No builds yet.</p>';
    return '<table class="tbl"><tr><th>Account</th><th style="text-align:right">Jobs</th></tr>' +
      list.map(function(u){ return '<tr><td>' + esc(u.acct) + '</td><td class="num">' + u.builds + '</td></tr>'; }).join('') + '</table>';
  }
  function failures(list){
    if (!list.length) return '<p class="muted small">No failures logged. 🎉</p>';
    return '<table class="tbl"><tr><th>When</th><th>Type</th><th>Error</th></tr>' +
      list.slice(0, 25).map(function(f){
        return '<tr><td style="white-space:nowrap">' + ago(f.t) + '</td><td>' + esc(f.task) + (f.status ? ' · ' + f.status : '') + (f.model ? '<br><small class="muted">' + esc(f.model) + '</small>' : '') + '</td><td class="err-msg">' + esc(f.error) + '</td></tr>';
      }).join('') + '</table>';
  }
  function render(d){
    var s = d.series, w = function(k){ return sum(s[k].slice(-7)); }, t = function(k){ return last(s[k]); };
    var doneW = w('builds_done'), failW = w('builds_failed');
    document.getElementById('admSub').textContent = 'Today (UTC) vs the last 7 days · AI model ' + (d.model || 'default') + (d.fallbacks ? ' → ' + d.fallbacks : '');
    document.getElementById('admBody').innerHTML =
      '<div class="kpis">' +
        kpi('Builds started', t('builds_started'), w('builds_started')) +
        kpi('Finished', t('builds_done'), doneW, 'good') +
        kpi('Failed', t('builds_failed'), failW, t('builds_failed') ? 'bad' : '') +
        kpi('Busy / 429', t('busy'), w('busy'), t('busy') ? 'bad' : '') +
        kpi('New sign-ups', t('signups'), w('signups')) +
        kpi('Logins', t('logins'), w('logins')) +
        kpi('Credits spent', t('credits'), w('credits')) +
        kpi('Auto-fixes', t('fixes'), w('fixes')) +
        kpi('Rig / Animate', t('task_rig') + t('task_animate'), w('task_rig') + w('task_animate')) +
        kpi('Enhance', t('task_enhance'), w('task_enhance')) +
        kpi('GUIs', t('task_gui'), w('task_gui')) +
        '<div class="kpi"><span>Success rate (7d)</span><b>' + pct(doneW, doneW + failW) + '</b><small>finished ÷ (finished + failed)</small></div>' +
        '<div class="kpi"><span>Shared to Explore</span><b>' + Number(d.sharedBuilds).toLocaleString() + '</b><small>all time</small></div>' +
      '</div>' +
      '<div class="adm-grid">' +
        '<div class="panel"><h3>Builds per day (14 days)</h3>' + chart(d) + '</div>' +
        '<div class="panel"><h3>Detail levels (7 days)</h3><table class="tbl">' +
          ['quick', 'standard', 'detailed', 'ultra'].map(function(k){ return '<tr><td>' + k[0].toUpperCase() + k.slice(1) + '</td><td class="num">' + w('detail_' + k) + '</td></tr>'; }).join('') +
        '</table></div>' +
        '<div class="panel"><h3>Top users today</h3>' + users(d.topToday) + '</div>' +
        '<div class="panel"><h3>Top users yesterday</h3>' + users(d.topYesterday) + '</div>' +
      '</div>' +
      '<div class="panel" style="margin-top:16px"><h3>Recent failures</h3>' + failures(d.failures) + '</div>';
  }
  async function load(){
    var me = window.BW.getMe();
    if (!me || !me.signedIn) { document.getElementById('admSub').innerHTML = 'Sign in with an admin account to see the dashboard. <a href="#" data-action="signin">Sign in</a>'; return; }
    try { render(await window.BW.api('/api/admin')); }
    catch (e) { document.getElementById('admSub').textContent = e.message === 'Admins only.' ? 'This account isn’t an admin (add its email to ADMIN_EMAILS in Netlify).' : 'Couldn’t load: ' + e.message; }
  }
  document.addEventListener('bw:ready', load);
  document.addEventListener('bw:me', function(){ if (document.getElementById('admBody') && !document.getElementById('admBody').innerHTML) load(); });
})();
