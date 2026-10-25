/* Brickwright website app.
   Uses BWCore (prompt, parser, part meshes — shared with the Claude version), the fengari Lua runtime
   + Roblox prelude to run scripts in the browser, and the Netlify functions under /api. */
(function(){
  'use strict';
  var C = window.BWCore;
  var $ = function(s, r){ return (r || document).querySelector(s); };
  var $$ = function(s, r){ return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  function esc(t){ return String(t == null ? '' : t).replace(/[&<>"']/g, function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; }); }
  function store(k, v){ try { if (v == null) localStorage.removeItem(k); else localStorage.setItem(k, v); } catch (e) {} }
  function load(k){ try { return localStorage.getItem(k); } catch (e) { return null; } }
  function fmtDate(iso){ try { return new Date(iso).toLocaleDateString(undefined, {month: 'short', day: 'numeric'}); } catch (e) { return ''; } }
  function ago(ms){ var s = (Date.now() - ms) / 1000; if (s < 60) return 'just now'; if (s < 3600) return Math.floor(s/60) + 'm ago'; if (s < 86400) return Math.floor(s/3600) + 'h ago'; return Math.floor(s/86400) + 'd ago'; }
  function toast(msg, isErr){
    var t = document.createElement('div'); t.className = 'toast' + (isErr ? ' err' : ''); t.textContent = msg;
    $('#toasts').appendChild(t); setTimeout(function(){ t.remove(); }, isErr ? 6000 : 3800);
  }

  // ------------------------------------------------------------------ API + session
  var SESSION = 'bw_session';
  var me = null;
  function session(){ return load(SESSION); }
  async function api(path, opts){
    opts = opts || {};
    var headers = {'content-type': 'application/json'};
    if (session()) headers.authorization = 'Bearer ' + session();
    var r;
    try {
      r = await fetch(path, {method: opts.method || 'GET', headers: headers, body: opts.body ? JSON.stringify(opts.body) : undefined, signal: opts.signal});
    } catch (e) {
      if (opts.signal && opts.signal.aborted) throw {code: 'cancelled'};
      throw {code: 'network', message: 'Couldn’t reach the server — check your connection.'};
    }
    var j = null; try { j = await r.json(); } catch (e) {}
    if (r.status === 401 && j && j.error === 'login_required') { if (session()) { store(SESSION, null); refreshMe(); } throw {code: 'login', message: 'Sign in first.'}; }
    if (!r.ok) throw {code: r.status, message: (j && j.error) || ('Request failed (' + r.status + ')'), data: j};
    return j;
  }
  async function refreshMe(){
    try { me = await api('/api/me'); } catch (e) { me = me || {signedIn: false, plans: [], costs: {quick: 10, standard: 35, detailed: 75, revise: 10}}; }
    renderAccount(); renderCost(); renderPricing();
    var pill = $('#heroPill'); if (pill && me.freeCreditsPerMonth) pill.textContent = me.freeCreditsPerMonth.toLocaleString() + ' free credits every month';
  }

  // ------------------------------------------------------------------ Lua runtime (runs scripts in the browser)
  var preludeText = null;
  var preludeReady = fetch('/vendor/prelude.lua').then(function(r){ return r.text(); }).then(function(t){ preludeText = t; });
  async function runScript(src){
    await preludeReady;
    try { return window.runLuauPreview(window.fengari, preludeText, C.BRICK_COLOR_FULL, src); }
    catch (e) { return {ok: false, error: String(e && e.message || e), parts: [], logs: []}; }
  }

  // ------------------------------------------------------------------ 3D viewer
  function Viewer(el, opts){
    opts = opts || {};
    this.el = el; this.auto = !!opts.autoRotate; this.rot = {theta: 0.75, phi: 1.05, radius: 26}; this.dirty = true; this.visible = true;
    try {
      this.renderer = new THREE.WebGLRenderer({antialias: true, alpha: true, preserveDrawingBuffer: !!opts.snapshot});
    } catch (e) { el.innerHTML = '<div class="viewer-msg">3D preview isn’t available in this browser (WebGL is off).</div>'; return; }
    var r = this.renderer;
    r.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    el.appendChild(r.domElement);
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(38, 1, 0.1, 2000);
    this.scene.add(new THREE.HemisphereLight(0xdfe8ff, 0x1a1a22, 0.95));
    var sun = new THREE.DirectionalLight(0xffffff, 0.85); sun.position.set(18, 30, 14); this.scene.add(sun);
    var fill = new THREE.DirectionalLight(0xffc49a, 0.3); fill.position.set(-14, 10, -12); this.scene.add(fill);
    this.grid = new THREE.GridHelper(80, 40, 0x39425c, 0x222a3c); this.scene.add(this.grid);
    this.group = new THREE.Group(); this.scene.add(this.group);
    if (!opts.snapshot) this._controls();
    var self = this;
    this._resize();
    if (window.ResizeObserver) new ResizeObserver(function(){ self._resize(); }).observe(el);
    if (window.IntersectionObserver) new IntersectionObserver(function(es){ self.visible = es[0].isIntersecting; if (self.visible) self.kick(); }).observe(el);
    if (!opts.snapshot) this.kick();
  }
  Viewer.prototype._resize = function(){
    if (!this.renderer) return;
    var w = this.el.clientWidth || 400, h = this.el.clientHeight || 300;
    this.renderer.setSize(w, h, false); this.camera.aspect = w / h; this.camera.updateProjectionMatrix(); this.dirty = true; this.kick();
  };
  Viewer.prototype._controls = function(){
    var self = this, c = this.renderer.domElement, pts = {}, pinch = 0;
    var list = function(){ return Object.keys(pts).map(function(k){ return pts[k]; }); };
    var dist = function(){ var l = list(); if (l.length < 2) return 0; var dx = l[0].x - l[1].x, dy = l[0].y - l[1].y; return Math.sqrt(dx*dx + dy*dy); };
    c.style.touchAction = 'none';
    c.addEventListener('pointerdown', function(e){ pts[e.pointerId] = {x: e.clientX, y: e.clientY}; try { c.setPointerCapture(e.pointerId); } catch (x) {} if (list().length === 2) pinch = dist(); self.auto = false; e.preventDefault(); });
    var up = function(e){ delete pts[e.pointerId]; pinch = list().length === 2 ? dist() : 0; };
    c.addEventListener('pointerup', up); c.addEventListener('pointercancel', up); c.addEventListener('lostpointercapture', up);
    c.addEventListener('pointermove', function(e){
      var p = pts[e.pointerId]; if (!p) return;
      var n = list().length, dx = e.clientX - p.x, dy = e.clientY - p.y;
      pts[e.pointerId] = {x: e.clientX, y: e.clientY};
      if (n === 1) { var k = e.pointerType === 'touch' ? 0.011 : 0.008; self.rot.theta -= dx * k; self.rot.phi = Math.max(0.15, Math.min(Math.PI - 0.15, self.rot.phi - dy * k)); }
      else { var d = dist(); if (pinch > 0 && d > 0) self.rot.radius = Math.max(2, Math.min(800, self.rot.radius * pinch / d)); pinch = d; }
      self.dirty = true; self.kick(); e.preventDefault();
    });
    c.addEventListener('wheel', function(e){ e.preventDefault(); self.rot.radius = Math.max(2, Math.min(800, self.rot.radius * (1 + e.deltaY * 0.001))); self.dirty = true; self.kick(); }, {passive: false});
    c.addEventListener('gesturestart', function(e){ e.preventDefault(); });
  };
  Viewer.prototype.kick = function(){
    var self = this;
    if (!this.renderer || this.raf || this.destroyed) return;
    this.raf = requestAnimationFrame(function tick(){
      self.raf = null;
      if (self.destroyed) return;
      if (self.auto) { self.rot.theta += 0.0045; self.dirty = true; }
      if (self.dirty) { self.render(); self.dirty = false; }
      if (self.auto && self.visible) self.kick();
    });
  };
  Viewer.prototype.render = function(){
    var r = this.rot, cam = this.camera;
    cam.position.set(r.radius * Math.sin(r.phi) * Math.sin(r.theta), r.radius * Math.cos(r.phi), r.radius * Math.sin(r.phi) * Math.cos(r.theta));
    cam.lookAt(0, 0, 0);
    this.renderer.render(this.scene, cam);
  };
  Viewer.prototype.setParts = function(parts){
    if (!this.renderer) return;
    var g = this.group;
    while (g.children.length) {
      var m = g.children.pop();
      if (m.geometry) m.geometry.dispose();
      [].concat(m.material || []).forEach(function(mt){ if (mt.map) mt.map.dispose(); mt.dispose(); });
    }
    g.position.set(0, 0, 0);
    (parts || []).forEach(function(p){ try { g.add(C.shapeMesh(p)); } catch (e) {} });
    g.updateMatrixWorld(true);
    var box = new THREE.Box3().setFromObject(g);
    if (box.isEmpty()) { this.dirty = true; this.kick(); return; }
    var center = box.getCenter(new THREE.Vector3()), size = box.getSize(new THREE.Vector3());
    g.position.set(-center.x, -center.y, -center.z);
    this.grid.position.y = box.min.y - center.y - 0.02;
    var span = Math.max(size.x, size.z, 8);
    var gs = Math.max(1, Math.ceil(span * 1.8 / 80)); this.grid.scale.set(gs, 1, gs);
    var fit = Math.max(size.x, size.y, size.z) || 10;
    this.rot.radius = Math.max(8, fit * 1.75);
    this.dirty = true; this.kick();
  };
  Viewer.prototype.snapshot = function(){
    this.render();
    var c = this.renderer.domElement, url = c.toDataURL('image/webp', 0.82);
    if (url.indexOf('data:image/webp') !== 0) url = c.toDataURL('image/jpeg', 0.85);
    return url;
  };
  Viewer.prototype.destroy = function(){
    this.destroyed = true;
    if (this.renderer) { this.setParts([]); this.renderer.dispose(); try { this.renderer.forceContextLoss(); } catch (e) {} this.renderer.domElement.remove(); }
  };

  var snapViewer = null;
  function snapshotOf(parts){
    if (!snapViewer) {
      var holder = document.createElement('div');
      holder.style.cssText = 'position:fixed;left:-9999px;top:0;width:480px;height:360px';
      document.body.appendChild(holder);
      snapViewer = new Viewer(holder, {snapshot: true});
      snapViewer.rot.theta = 0.75; snapViewer.rot.phi = 1.1;
    }
    if (!snapViewer.renderer) return '';
    snapViewer.setParts(parts);
    return snapViewer.snapshot();
  }

  // ------------------------------------------------------------------ modal
  var modalOnClose = null;
  function openModal(html, wide, onClose){
    if (modalOnClose) { var f = modalOnClose; modalOnClose = null; f(); }
    $('#modalBody').innerHTML = html;
    $('#modal .modal-card').classList.toggle('wide', !!wide);
    $('#modal').hidden = false;
    document.body.style.overflow = 'hidden';
    modalOnClose = onClose || null;
    return $('#modalBody');
  }
  function closeModal(){
    $('#modal').hidden = true; document.body.style.overflow = '';
    if (modalOnClose) { var f = modalOnClose; modalOnClose = null; f(); }
  }
  $('#modal .modal-x').addEventListener('click', closeModal);
  $('#modal').addEventListener('click', function(e){ if (e.target.id === 'modal') closeModal(); });
  document.addEventListener('keydown', function(e){ if (e.key === 'Escape' && !$('#modal').hidden) closeModal(); });

  // ------------------------------------------------------------------ sign in (email code + captcha)
  var loginEmail = '', captchaToken = null, captchaId = null, captchaWaiters = [], captchaWatch = null, tsPromise = null;
  // load Cloudflare's script once, as early as possible (right after the page knows the site key)
  function loadTurnstile(){
    if (!me || !me.turnstileSiteKey) return Promise.resolve(false);
    if (window.turnstile) return Promise.resolve(true);
    if (tsPromise) return tsPromise;
    tsPromise = new Promise(function(res){
      var s = document.createElement('script');
      s.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit'; s.async = true;
      s.onload = function(){ res(true); }; s.onerror = function(){ tsPromise = null; res(false); };
      document.head.appendChild(s);
    });
    return tsPromise;
  }
  function gotToken(t){
    captchaToken = t; clearTimeout(captchaWatch);
    var st = $('#lCapState'); if (st) st.textContent = '✓ Verified';
    var btn = $('#lSend'); if (btn && !btn.dataset.sending) { btn.disabled = false; btn.textContent = 'Send code'; }
    if ($('#lErr')) $('#lErr').textContent = '';
    var w = captchaWaiters; captchaWaiters = []; w.forEach(function(f){ f(t); });
  }
  function waitForToken(ms){
    if (captchaToken) return Promise.resolve(captchaToken);
    return new Promise(function(res){ captchaWaiters.push(res); setTimeout(function(){ res(null); }, ms); });
  }
  async function openLogin(){
    captchaToken = null; captchaWaiters = []; clearTimeout(captchaWatch);
    var doms = (me && me.allowedEmailDomains && me.allowedEmailDomains.length) ? me.allowedEmailDomains.map(function(d){ return '@' + d; }).join(' / ') + ' ' : '';
    var b = openModal('<h3>Sign in</h3><p>We’ll email you a 6-digit code — no password. Use your ' + esc(doms) + 'address.</p>' +
      '<div class="field"><input id="lEmail" type="email" autocomplete="email" placeholder="you@gmail.com" value="' + esc(loginEmail) + '"></div>' +
      '<div class="field"><div id="lCaptcha"></div><small class="muted" id="lCapState"></small></div><div class="err" id="lErr"></div>' +
      '<button class="btn btn-primary btn-block btn-lg" id="lSend">Send code</button>');
    $('#lSend', b).onclick = sendCode;
    $('#lEmail', b).onkeydown = function(e){ if (e.key === 'Enter') sendCode(); };
    $('#lEmail', b).focus();
    if (!me || !('turnstileSiteKey' in me)) await refreshMe();
    if (!me || !me.turnstileSiteKey) return;
    $('#lCapState').textContent = 'Checking you’re human…';
    var tries = 0;
    var arm = function(){ // if Cloudflare hasn't answered in 15s, restart the check (it sometimes stalls)
      clearTimeout(captchaWatch);
      captchaWatch = setTimeout(function(){
        if (captchaToken || !$('#lCaptcha')) return;
        tries++;
        if (tries > 3) { $('#lCapState').textContent = 'Still checking… if this takes long, turn off ad blockers/VPN for this site and reload.'; return; }
        try { window.turnstile.reset(captchaId); } catch (x) {}
        arm();
      }, 15000);
    };
    if (await loadTurnstile() && window.turnstile && $('#lCaptcha')) {
      captchaId = window.turnstile.render($('#lCaptcha'), {sitekey: me.turnstileSiteKey, theme: 'dark', size: 'flexible',
        retry: 'auto', 'retry-interval': 2000, 'refresh-expired': 'auto',
        callback: gotToken,
        'expired-callback': function(){ captchaToken = null; },
        'error-callback': function(code){
          captchaToken = null;
          var bad = String(code).indexOf('110200') === 0 ? 'this site’s address isn’t added to the Turnstile widget in Cloudflare.'
            : (String(code).indexOf('1101') === 0 || String(code).indexOf('400') === 0) ? 'the Turnstile site key looks wrong.' : '';
          if (bad && $('#lErr')) $('#lErr').textContent = 'Captcha error ' + code + ' — ' + bad;
          return true; // let Cloudflare retry by itself for the other errors
        }});
      arm();
    } else if ($('#lErr')) $('#lErr').textContent = 'The captcha couldn’t load — disable blockers for this site and reload.';
  }
  async function sendCode(){
    var err = $('#lErr'), btn = $('#lSend');
    loginEmail = $('#lEmail').value.trim();
    if (!loginEmail) { err.textContent = 'Enter your email.'; return; }
    btn.disabled = true; btn.dataset.sending = '1'; err.textContent = '';
    if (me && me.turnstileSiteKey && !captchaToken) {
      // don't make people wait for the widget by hand — just wait for it here
      btn.textContent = 'Checking you’re human…';
      await waitForToken(45000);
      if (!captchaToken) { btn.disabled = false; delete btn.dataset.sending; btn.textContent = 'Send code'; err.textContent = 'The human check didn’t finish — tick the box above if you see one, or reload the page.'; return; }
    }
    btn.textContent = 'Sending…';
    try {
      await api('/api/otp-send', {method: 'POST', body: {email: loginEmail, captcha: captchaToken}});
      var b = openModal('<h3>Check your inbox</h3><p>We sent a 6-digit code to <b>' + esc(loginEmail) + '</b>. It expires in 10 minutes — check spam too.</p>' +
        '<div class="field"><input id="lCode" class="code-input" inputmode="numeric" autocomplete="one-time-code" maxlength="6" placeholder="••••••"></div>' +
        '<div class="err" id="lErr"></div><button class="btn btn-primary btn-block btn-lg" id="lVerify">Sign in</button>' +
        '<button class="link-btn" id="lBack">Use a different email / resend</button>');
      $('#lVerify', b).onclick = verifyCode;
      $('#lCode', b).oninput = function(){ if (this.value.replace(/\D/g, '').length === 6) verifyCode(); };
      $('#lBack', b).onclick = openLogin;
      $('#lCode', b).focus();
    } catch (e) {
      err.textContent = e.message === 'captcha_failed' ? 'Captcha check failed — try it again.' : e.message;
      btn.disabled = false; delete btn.dataset.sending; btn.textContent = 'Send code';
      if (window.turnstile && captchaId != null) { try { window.turnstile.reset(captchaId); } catch (x) {} captchaToken = null; }
    }
  }
  var verifying = false;
  async function verifyCode(){
    if (verifying) return; verifying = true;
    var err = $('#lErr'), btn = $('#lVerify');
    btn.disabled = true; err.textContent = '';
    try {
      var j = await api('/api/otp-verify', {method: 'POST', body: {email: loginEmail, code: $('#lCode').value}});
      store(SESSION, j.session); closeModal(); await refreshMe(); toast('Signed in — welcome!');
    } catch (e) { err.textContent = e.message; btn.disabled = false; }
    verifying = false;
  }
  function openPromo(){
    var b = openModal('<h3>Redeem a code</h3><p>Got a promo code? Enter it to add free credits to your account.</p>' +
      '<div class="field"><input id="pCode" placeholder="CODE" autocomplete="off" style="text-transform:uppercase"></div><div class="err" id="pErr"></div>' +
      '<button class="btn btn-primary btn-block btn-lg" id="pGo">Redeem</button>');
    var go = async function(){
      var code = $('#pCode').value.trim(); if (!code) return;
      $('#pGo').disabled = true; $('#pErr').textContent = '';
      try {
        var r = await api('/api/promo', {method: 'POST', body: {code: code}});
        closeModal(); toast('+' + r.credits + ' credits added!'); refreshMe();
      } catch (e) { $('#pErr').textContent = (e.data && e.data.error) || e.message || 'Couldn’t redeem that code.'; $('#pGo').disabled = false; }
    };
    $('#pGo', b).onclick = go; $('#pCode', b).onkeydown = function(e){ if (e.key === 'Enter') go(); }; $('#pCode', b).focus();
  }
  function signOut(){ store(SESSION, null); refreshMe(); toast('Signed out.'); }

  // ------------------------------------------------------------------ account (nav)
  function renderAccount(){
    var el = $('#account');
    if (!me || !me.signedIn) { el.innerHTML = '<button class="btn btn-primary btn-sm" data-action="signin">Sign in</button>'; return; }
    var name = (me.user && me.user.name) || '';
    el.innerHTML = (me.error ? '' : '<a class="credit-pill" href="#pricing" title="Credits left"><svg viewBox="0 0 16 16"><rect x="1" y="5" width="14" height="9" rx="2"/><rect x="3.5" y="2" width="3.5" height="3.5" rx="1"/><rect x="9" y="2" width="3.5" height="3.5" rx="1"/></svg><b>' + (me.unlimited ? '∞' : Number(me.remaining).toLocaleString()) + '</b></a>') +
      '<div class="menu"><button class="avatar" id="avatarBtn" aria-label="Account">' + esc((name[0] || '?').toUpperCase()) + '</button>' +
      '<div class="menu-pop" id="menuPop" hidden><div class="who">' + esc(name) + '<small>' + esc(me.planName || 'Free') + ' plan' + (me.resetsAt ? ' · refills ' + fmtDate(me.resetsAt) : '') + '</small></div>' +
      (me.hasBilling ? '<button data-action="portal">Manage subscription</button>' : '<button data-action="pricing">Get more credits</button>') +
      '<button data-action="promo">Redeem a code</button>' +
      '<button data-action="signout">Sign out</button></div></div>';
    $('#avatarBtn').onclick = function(e){ e.stopPropagation(); $('#menuPop').hidden = !$('#menuPop').hidden; };
  }
  document.addEventListener('click', function(e){
    var pop = $('#menuPop'); if (pop && !pop.hidden && !e.target.closest('.menu')) pop.hidden = true;
    var a = e.target.closest('[data-action]'); if (!a) return;
    var act = a.getAttribute('data-action');
    if (act === 'signin') openLogin();
    else if (act === 'signout') signOut();
    else if (act === 'portal') openPortal();
    else if (act === 'pricing') location.hash = '#pricing';
    else if (act === 'promo') openPromo();
    if (pop) pop.hidden = true;
  });

  // ------------------------------------------------------------------ studio
  var detail = 'standard';
  var last = {script: C.EXAMPLE_SCRIPT, notes: 'This is a built-in example. Describe your own model and press Generate.', brief: '', detail: 'standard', parts: [], example: true};
  var studio = null, busy = false, currentJob = null;

  function renderStudioControls(){
    $('#chips').innerHTML = C.chips.map(function(c){ return '<button class="chip" type="button">' + esc(c) + '</button>'; }).join('');
    $$('#chips .chip').forEach(function(b){ b.onclick = function(){ $('#brief').value = b.textContent; $('#brief').focus(); }; });
    $('#detailPicker').innerHTML = C.details.map(function(d){
      return '<button class="seg' + (d.key === detail ? ' active' : '') + '" role="radio" aria-checked="' + (d.key === detail) + '" data-detail="' + d.key + '"><b>' + esc(d.label) + '</b><small>' + esc(d.meta) + '</small></button>';
    }).join('');
    $$('#detailPicker .seg').forEach(function(b){ b.onclick = function(){ detail = b.getAttribute('data-detail'); renderStudioControls(); renderCost(); }; });
    var sel = $('#treatment');
    if (!sel.options.length) sel.innerHTML = C.treatments.map(function(t){ return '<option value="' + esc(t.value) + '">' + esc(t.label) + '</option>'; }).join('');
  }
  function renderCost(){
    var el = $('#costLine'); if (!el || !me || !me.costs) return;
    var cost = me.costs[detail];
    if (!me.signedIn) el.innerHTML = 'Costs ' + cost + ' credits · <a href="#" data-action="signin">Sign in</a> to get ' + (me.freeCreditsPerMonth || 0).toLocaleString() + ' free credits a month';
    else if (me.error) el.textContent = 'Costs ' + cost + ' credits';
    else if (me.unlimited) el.textContent = 'Unlimited credits (admin)';
    else el.textContent = 'Costs ' + cost + ' credits · you have ' + Number(me.remaining).toLocaleString() + (me.resetsAt ? ' · refills ' + fmtDate(me.resetsAt) : '');
  }
  function setStatus(text, kind, working){
    var s = $('#status'); s.className = 'status' + (kind ? ' ' + kind : '');
    $('#statusText').textContent = text; $('#progress').hidden = !working;
  }
  function showTab(name){
    $$('.tab').forEach(function(t){ t.classList.toggle('active', t.getAttribute('data-tab') === name); });
    $$('.pane').forEach(function(p){ p.hidden = p.getAttribute('data-pane') !== name; });
    if (name === 'preview' && studio) studio._resize();
  }
  $$('.tab').forEach(function(t){ t.onclick = function(){ showTab(t.getAttribute('data-tab')); }; });

  async function showResult(){
    $('#codeOut').textContent = last.script;
    $('#notesOut').textContent = last.notes || '';
    var run = await runScript(last.script);
    last.parts = run.parts;
    if (studio) studio.setParts(run.parts);
    $('#previewInfo').textContent = run.parts.length
      ? 'Ran the script: ' + run.parts.length + ' parts' + (run.ok ? '' : ' (stopped early: ' + run.error + ')')
      : (run.ok ? 'The script ran but left no visible parts.' : 'Preview couldn’t run this script: ' + run.error);
    $('#shareBtn').disabled = !!last.example || !run.parts.length;
  }

  function stripThink(t){
    t = t.replace(/<think>[\s\S]*?<\/think>\s*/g, '');
    var open = t.indexOf('<think>');
    return open >= 0 ? t.slice(0, open) : t;
  }
  var lastJobId = null;
  async function aiCall(input, kind, onText, extra){
    var body = {prompt: input, detail: last.detail || detail, kind: kind};
    if (extra) for (var k in extra) body[k] = extra[k];
    var job = await api('/api/generate', {method: 'POST', body: body});
    currentJob = job.jobId;
    var text = '', from = 0;
    refreshMe();
    for (;;) {
      await new Promise(function(r){ setTimeout(r, 900); });
      var st = await api('/api/job?id=' + encodeURIComponent(job.jobId) + '&from=' + from);
      if (st.text) { text += st.text; from = st.length; }
      var shown = stripThink(text);
      var inlineThink = text.length - shown.length;
      onText(shown, (st.thinking || 0) + inlineThink);
      if (st.status === 'done') { currentJob = null; lastJobId = job.jobId; refreshMe(); return shown; }
      if (st.status === 'cancelled') { currentJob = null; refreshMe(); throw {code: 'cancelled', message: 'Stopped — your credits were refunded.'}; }
      if (st.status === 'error') { currentJob = null; refreshMe(); throw {code: 'failed', message: (st.error || 'The build failed.') + (st.refunded ? ' Credits refunded.' : ''), text: shown}; }
    }
  }

  // ------------------------------------------------------------------ build checker (runs on the preview result)
  function analyzeBuild(parts){
    var n = parts.length, E = 0.2, box = [], i;
    if (!n) return [];
    for (i = 0; i < n; i++) {
      var m = parts[i].m, s = parts[i].sz, h = [0, 0, 0];
      for (var r = 0; r < 3; r++) h[r] = (Math.abs(m[3 + r * 3]) * s[0] + Math.abs(m[4 + r * 3]) * s[1] + Math.abs(m[5 + r * 3]) * s[2]) / 2;
      box.push([m[0] - h[0], m[1] - h[1], m[2] - h[2], m[0] + h[0], m[1] + h[1], m[2] + h[2]]);
    }
    var groundY = Infinity; box.forEach(function(b){ if (b[1] < groundY) groundY = b[1]; });
    var par = []; for (i = 0; i < n; i++) par[i] = i;
    function f(a){ while (par[a] !== a) { par[a] = par[par[a]]; a = par[a]; } return a; }
    var order = box.map(function(b, k){ return k; }).sort(function(a, b){ return box[a][0] - box[b][0]; });
    for (var a = 0; a < n; a++) {
      var A = box[order[a]];
      for (var b = a + 1; b < n; b++) {
        var B = box[order[b]];
        if (B[0] > A[3] + E) break;
        if (B[1] <= A[4] + E && A[1] <= B[4] + E && B[2] <= A[5] + E && A[2] <= B[5] + E) par[f(order[a])] = f(order[b]);
      }
    }
    var grounded = {};
    for (i = 0; i < n; i++) if (box[i][1] <= groundY + E) grounded[f(i)] = true;
    var out = [];
    for (i = 0; i < n; i++) if (!grounded[f(i)]) out.push({name: parts[i].name || ('part #' + (i + 1)), gap: +(box[i][1] - groundY).toFixed(1)});
    return out;
  }
  function badColors(src){
    var bad = {}, re = /BrickColor\.new\(\s*["']([^"']+)["']\s*\)/g, m;
    var known = C.BRICK_COLOR_FULL || {};
    // also catch names passed through variables: "SOME_COL = "Dark brown"" style constants
    var re2 = /=\s*["']([A-Z][A-Za-z. ]{2,30})["']/g;
    while ((m = re.exec(src))) if (!known[m[1]]) bad[m[1]] = 1;
    while ((m = re2.exec(src))) if (/ (grey|gray|red|blue|green|yellow|orange|brown|white|black|pink|purple|violet)\b/i.test(m[1]) && !known[m[1]]) bad[m[1]] = 1;
    return Object.keys(bad);
  }
  function problemsOf(run, src){
    var list = [];
    if (!run.ok) list.push('The script errors: ' + run.error);
    var bc = src ? badColors(src) : [];
    if (bc.length) list.push('These BrickColor names do not exist in Roblox and turn grey: ' + bc.map(function(n){ return '"' + n + '"'; }).join(', ') +
      '. Replace each with the closest real BrickColor name (e.g. "Reddish brown", "Brown", "Dark orange", "Bright red", "Medium stone grey").');
    var fl = analyzeBuild(run.parts);
    if (fl.length) list.push(fl.length + ' part(s) float in mid-air, not touching the ground or any other part: ' +
      fl.slice(0, 25).map(function(x){ return x.name + ' (bottom ' + x.gap + ' studs above the ground)'; }).join(', ') + (fl.length > 25 ? ', …' : '') + '.');
    return {list: list, score: (run.ok ? 0 : 1000) + fl.length + bc.length * 5, floating: fl.length, colors: bc.length};
  }
  async function autoFix(b){
    if (!lastJobId || !last.script) return;
    var run = await runScript(last.script), pr = problemsOf(run, last.script);
    if (!pr.list.length) return;
    var jobId = lastJobId;
    var label = (!run.ok ? 'Script error found' : pr.floating ? pr.floating + ' floating part' + (pr.floating === 1 ? '' : 's') + ' found' : 'Wrong color names found') + ' — fixing it (free)…';
    setStatus(label, '', true); b.relabel(label);
    try {
      var text = await aiCall('fix', 'fix', function(t, th){ $('#codeOut').textContent = t; b.lines((t.match(/\n/g) || []).length, th); }, {fixOf: jobId, problems: pr.list.join('\n')});
      var p = C.parseResponse(text);
      if (!p.script) return;
      var run2 = await runScript(p.script), pr2 = problemsOf(run2, p.script);
      if (run2.parts.length && pr2.score < pr.score) { last.script = p.script; last.notes = p.notes || last.notes; }
    } catch (e) { /* keep the original build */ }
    $('#codeOut').textContent = last.script;
  }

  function startBusy(label){
    busy = true; $('#generateBtn').disabled = true; $('#reviseBtn').disabled = true; $('#stopBtn').hidden = false;
    var t0 = Date.now(), lines = 0, thinking = 0;
    setStatus(label, '', true);
    var tick = function(){
      var s = Math.round((Date.now() - t0) / 1000);
      var msg = lines > 1 ? 'Writing the script… ' + lines + ' lines · ' + s + 's'
        : thinking ? 'Thinking it through… ' + (thinking > 999 ? (thinking / 1000).toFixed(1) + 'k' : thinking) + ' chars of planning · ' + s + 's'
        : label + ' ' + s + 's' + (s > 20 ? ' — waiting for the AI to start' : '');
      setStatus(msg, '', true);
    };
    var timer = setInterval(tick, 1000);
    return {
      lines: function(n, th){ lines = n; if (th) thinking = th; },
      relabel: function(l){ label = l; lines = 0; thinking = 0; t0 = Date.now(); },
      done: function(){ clearInterval(timer); busy = false; $('#generateBtn').disabled = false; $('#reviseBtn').disabled = false; $('#stopBtn').hidden = true; }
    };
  }
  function handleError(e){
    if (e.code === 'login') { setStatus('Sign in to generate — free accounts get ' + ((me && me.freeCreditsPerMonth) || 0) + ' credits a month.', 'err'); openLogin(); return; }
    if (e.code === 402) {
      var d = e.data || {};
      setStatus('Not enough credits — this needs ' + d.cost + ', you have ' + d.remaining + '. They refill ' + fmtDate(d.resetsAt) + ', or pick a plan.', 'err');
      location.hash = '#pricing'; return;
    }
    if (e.code === 'cancelled') { setStatus(e.message || 'Stopped.', ''); return; }
    setStatus(e.message || 'Something went wrong.', 'err');
  }

  async function generate(){
    if (busy) return;
    var brief = $('#brief').value.trim();
    if (!brief) { setStatus('Describe what you want built first.', 'err'); $('#brief').focus(); return; }
    if (!session()) { handleError({code: 'login'}); return; }
    var b = startBusy('Planning the build…');
    var prev = last;
    last = {script: '', notes: '', brief: brief, detail: detail, treatment: $('#treatment').value, csg: $('#allowCsg').checked};
    $('#codeOut').textContent = '';
    try {
      var prompt = C.buildPrompt(brief, detail, last.treatment, last.csg, false);
      var text = await aiCall(prompt, 'generate', function(t, th){ $('#codeOut').textContent = t; b.lines((t.match(/\n/g) || []).length, th); });
      var p = C.parseResponse(text);
      last.script = p.script; last.notes = p.notes;
      await autoFix(b);
      await showResult(); showTab('preview');
      setStatus('Done — ' + last.parts.length + ' parts.', 'ok');
    } catch (e) {
      handleError(e);
      if (!last.script) { last = prev; $('#codeOut').textContent = last.script; }
    }
    b.done();
  }
  async function revise(){
    if (busy) return;
    var ins = $('#reviseInput').value.trim();
    if (!ins) { setStatus('Describe the change you want first.', 'err'); return; }
    if (!last.script || last.example) { setStatus('Generate (or remix) a model first, then ask for changes.', 'err'); return; }
    if (!session()) { handleError({code: 'login'}); return; }
    var b = startBusy('Working out the change…');
    try {
      var msgs = [
        {role: 'user', content: C.buildPrompt(last.brief || 'the model in the script below', last.detail || detail, last.treatment || $('#treatment').value, !!last.csg, false)},
        {role: 'assistant', content: 'SCRIPT:\n```lua\n' + last.script + '\n```\nNOTES:\n' + (last.notes || '')},
        {role: 'user', content: 'Revise the script above: ' + ins + '. Keep everything else the same. Respond in the same SCRIPT:/NOTES: format, with the complete revised script.'}
      ];
      var text = await aiCall(msgs, 'revise', function(t, th){ $('#codeOut').textContent = t; b.lines((t.match(/\n/g) || []).length, th); });
      var p = C.parseResponse(text);
      last.script = p.script; last.notes = p.notes;
      await autoFix(b);
      $('#reviseInput').value = '';
      await showResult(); showTab('preview');
      setStatus('Revision applied — ' + last.parts.length + ' parts.', 'ok');
    } catch (e) { handleError(e); $('#codeOut').textContent = last.script; }
    b.done();
  }
  $('#generateBtn').onclick = generate;
  $('#reviseBtn').onclick = revise;
  $('#reviseInput').onkeydown = function(e){ if (e.key === 'Enter') revise(); };
  $('#stopBtn').onclick = function(){ if (currentJob) api('/api/job?id=' + encodeURIComponent(currentJob), {method: 'POST', body: {cancel: true}}).catch(function(){}); setStatus('Stopping…', '', true); };
  $('#copyBtn').onclick = function(){
    if (!navigator.clipboard) { toast('Copy isn’t available here — open the Script tab and copy manually.', true); return; }
    navigator.clipboard.writeText(last.script).then(function(){ toast('Script copied.'); }, function(){ toast('Couldn’t copy.', true); });
  };
  function download(name, text){
    var a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([text], {type: 'text/plain'}));
    a.download = (name || 'brickwright').replace(/[^\w\- ]+/g, '').trim().replace(/\s+/g, '_').slice(0, 40) + '.lua';
    document.body.appendChild(a); a.click(); setTimeout(function(){ URL.revokeObjectURL(a.href); a.remove(); }, 500);
  }
  $('#downloadBtn').onclick = function(){ download(last.brief || 'brickwright', last.script); };

  // ------------------------------------------------------------------ share to Explore
  $('#shareBtn').onclick = function(){
    if (!session()) { openLogin(); return; }
    if (last.example || !last.parts.length) { toast('Generate a model first.', true); return; }
    var title = (last.brief || '').split(/[,.]/)[0].slice(0, 50);
    var name = load('bw_name') || ((me && me.user && me.user.name) || '').split('@')[0];
    var b = openModal('<h3>Share to Explore</h3><p>Your build appears publicly in Explore. People can view it, copy the script and like it.</p>' +
      '<div class="field"><span class="label">Title</span><input id="sTitle" maxlength="60" value="' + esc(title) + '"></div>' +
      '<div class="field"><span class="label">Shown as</span><input id="sName" maxlength="24" value="' + esc(name) + '"></div>' +
      '<label class="switch" style="margin:4px 0 14px"><input type="checkbox" id="sBrief" checked><span class="switch-ui"></span><span class="switch-text">Include my prompt<small>so others can see how it was made</small></span></label>' +
      '<div class="err" id="sErr"></div><button class="btn btn-primary btn-block btn-lg" id="sGo">Share</button>');
    $('#sGo', b).onclick = async function(){
      var btn = this; btn.disabled = true; $('#sErr').textContent = '';
      try {
        store('bw_name', $('#sName').value.trim());
        var thumb = snapshotOf(last.parts);
        var j = await api('/api/builds', {method: 'POST', body: {title: $('#sTitle').value, name: $('#sName').value, brief: $('#sBrief').checked ? last.brief : '',
          script: last.script, detail: last.detail, parts: last.parts.length, thumb: thumb}});
        closeModal(); toast('Shared! It’s live in Explore.');
        loadExplore(true);
        location.hash = '#explore';
        void j;
      } catch (e) { $('#sErr').textContent = e.message; btn.disabled = false; }
    };
  };

  // ------------------------------------------------------------------ explore
  var exploreSort = 'recent', exploreNext = 0;
  function cardHtml(it){
    return '<button class="card" data-build="' + esc(it.id) + '">' +
      '<div class="thumb">' + (it.hasThumb ? '<img loading="lazy" alt="" src="/api/thumb?id=' + encodeURIComponent(it.id) + '">' : '<span>no preview</span>') + '</div>' +
      '<div class="meta"><h3>' + esc(it.title) + '</h3><div class="sub"><span>by ' + esc(it.name) + ' · ' + ago(it.created) + '</span>' +
      '<span class="likes"><svg viewBox="0 0 24 24"><path d="M12 21s-7.5-4.6-10-9.3C.4 8.4 2.3 4.5 6 4.5c2.2 0 3.6 1.2 4.4 2.4h3.2C14.4 5.7 15.8 4.5 18 4.5c3.7 0 5.6 3.9 4 7.2C19.5 16.4 12 21 12 21z"/></svg>' + it.likes + '</span></div></div></button>';
  }
  async function loadExplore(reset){
    var grid = $('#exploreGrid');
    if (reset) { exploreNext = 0; grid.innerHTML = ''; }
    try {
      var j = await api('/api/builds?sort=' + exploreSort + '&offset=' + exploreNext);
      if (reset && !j.items.length) grid.innerHTML = '<div class="empty">No shared builds yet — generate something and hit <b>Share to Explore</b> to be the first.</div>';
      grid.insertAdjacentHTML('beforeend', j.items.map(cardHtml).join(''));
      exploreNext = j.next; $('#loadMore').hidden = j.next == null;
    } catch (e) {
      if (reset) grid.innerHTML = '<div class="empty">Couldn’t load Explore right now.</div>';
    }
  }
  $$('#exploreSort button').forEach(function(b){ b.onclick = function(){
    exploreSort = b.getAttribute('data-sort');
    $$('#exploreSort button').forEach(function(x){ x.classList.toggle('active', x === b); });
    loadExplore(true);
  }; });
  $('#loadMore').onclick = function(){ loadExplore(false); };
  $('#exploreGrid').addEventListener('click', function(e){ var c = e.target.closest('[data-build]'); if (c) openBuild(c.getAttribute('data-build')); });

  async function openBuild(id){
    var viewer = null;
    var b = openModal('<div class="build-view"><div class="viewer" id="bViewer"><div class="viewer-msg">Loading…</div></div><div class="build-side" id="bSide"></div></div>', true,
      function(){ if (viewer) viewer.destroy(); });
    var bd;
    try { bd = await api('/api/builds?id=' + encodeURIComponent(id)); }
    catch (e) { $('#bSide', b).innerHTML = '<p class="err">' + esc(e.message) + '</p>'; return; }
    if ($('#modal').hidden) return;
    var vEl = $('#bViewer', b); vEl.innerHTML = '';
    viewer = new Viewer(vEl, {autoRotate: true});
    runScript(bd.script).then(function(run){ if (viewer && !viewer.destroyed) viewer.setParts(run.parts); });
    var side = $('#bSide', b);
    side.innerHTML = '<h3>' + esc(bd.title) + '</h3><div class="by">by ' + esc(bd.name) + ' · ' + ago(bd.created) + (bd.parts ? ' · ' + bd.parts + ' parts' : '') + ' · <span class="badge">' + esc(bd.detail) + '</span></div>' +
      (bd.brief ? '<span class="label">Prompt</span><div class="brief">' + esc(bd.brief) + '</div>' : '') +
      '<div class="build-actions">' +
      '<button class="btn like-btn' + (bd.liked ? ' on' : '') + '" id="bLike">♥ <span>' + bd.likes + '</span></button>' +
      '<button class="btn" id="bCopy">Copy script</button><button class="btn" id="bDl">Download</button>' +
      '<button class="btn btn-primary" id="bRemix">Remix in studio</button>' +
      (bd.mine ? '<button class="btn btn-ghost" id="bDel">Delete</button>' : '') + '</div>';
    $('#bLike', side).onclick = async function(){
      if (!session()) { openLogin(); return; }
      try { var r = await api('/api/builds', {method: 'POST', body: {like: id}}); this.classList.toggle('on', r.liked); $('span', this).textContent = r.likes; }
      catch (e) { toast(e.message, true); }
    };
    $('#bCopy', side).onclick = function(){ navigator.clipboard && navigator.clipboard.writeText(bd.script).then(function(){ toast('Script copied.'); }); };
    $('#bDl', side).onclick = function(){ download(bd.title, bd.script); };
    $('#bRemix', side).onclick = async function(){
      last = {script: bd.script, notes: 'Remixed from “' + bd.title + '” by ' + bd.name + '. Ask for changes below.', brief: bd.brief || bd.title, detail: bd.detail || 'standard', parts: []};
      closeModal(); location.hash = '#create';
      await showResult(); showTab('preview'); setStatus('Remix loaded — describe a change and press Revise.', 'ok'); $('#reviseInput').focus();
    };
    if (bd.mine) $('#bDel', side).onclick = async function(){
      if (!confirm('Delete this build from Explore? This can’t be undone.')) return;
      try { await api('/api/builds?id=' + encodeURIComponent(id), {method: 'DELETE'}); closeModal(); toast('Deleted.'); loadExplore(true); }
      catch (e) { toast(e.message, true); }
    };
  }

  // ------------------------------------------------------------------ pricing
  function renderPricing(){
    if (!me) return;
    var c = me.costs || {};
    $('#pricingLede').textContent = 'Quick builds cost ' + c.quick + ' credits, Standard ' + c.standard + ', Detailed ' + c.detailed + ', a revision ' + c.revise + '. Failed builds are always free.';
    var free = '<div class="plan"><h3>Free</h3><div class="price">$0</div><ul><li>' + (me.freeCreditsPerMonth || 0).toLocaleString() + ' credits every month</li><li>Every detail level</li><li>Share to Explore</li></ul>' +
      (me.signedIn ? (me.plan === 'free' ? '<div class="current">Your plan</div>' : '') : '<button class="btn btn-block" data-action="signin">Sign up free</button>') + '</div>';
    var paid = (me.plans || []).map(function(p){
      var mine = me.signedIn && me.plan === p.id;
      var parts = p.price.split('/');
      var priceHtml = esc(parts[0].trim()) + (parts[1] ? ' <small>/ ' + esc(parts[1].trim()) + '</small>' : '');
      var btn = mine ? '<div class="current">Your plan</div>'
        : !p.available ? '<button class="btn btn-block" disabled>Coming soon</button>'
        : !me.signedIn ? '<button class="btn btn-primary btn-block" data-action="signin">Sign in to subscribe</button>'
        : '<button class="btn btn-primary btn-block" data-plan="' + p.id + '">Choose ' + esc(p.name) + '</button>';
      return '<div class="plan' + (p.id === 'monthly' ? ' featured' : '') + '">' + (p.id === 'monthly' ? '<span class="tag">Popular</span>' : '') +
        '<h3>' + esc(p.name) + '</h3><div class="price">' + priceHtml + '</div><ul><li>' + esc(p.label) + '</li><li>Every detail level</li><li>Cancel anytime</li></ul>' + btn + '</div>';
    }).join('');
    $('#plans').innerHTML = free + paid;
    $('#billingNote').innerHTML = me.hasBilling ? '<button class="btn btn-ghost btn-sm" data-action="portal">Manage or cancel your subscription</button>' : 'Payments are handled securely by Stripe.';
    $$('#plans [data-plan]').forEach(function(b){ b.onclick = async function(){
      b.disabled = true;
      try { var j = await api('/api/checkout', {method: 'POST', body: {plan: b.getAttribute('data-plan')}}); location.href = j.url; }
      catch (e) { toast(e.message, true); b.disabled = false; }
    }; });
  }
  async function openPortal(){
    try { var j = await api('/api/portal', {method: 'POST'}); location.href = j.url; } catch (e) { toast(e.message, true); }
  }

  // ------------------------------------------------------------------ FAQ
  var faqs = [
    ['What do I actually get?', 'One Luau script. Paste it into Roblox Studio’s command bar and it builds the model out of ordinary Parts, WedgeParts and cylinders, with named parts and classic BrickColors, then puts it in Workspace.'],
    ['Is the preview accurate?', 'The preview runs the real script in your browser against a small re-creation of Roblox, so shapes, positions, rotations, colors and studs match what Studio builds. Two exceptions: random scatter lands slightly differently, and anything loaded from the asset library won’t show.'],
    ['How do credits work?', 'Each generation costs credits by detail level, and each revision costs a little. Free accounts get a monthly allowance; paid plans refill every billing period. If a build fails, you get the credits back automatically.'],
    ['Can I use the models in games I sell?', 'Yes. Scripts you generate are yours to use, remix or sell, including in paid experiences.'],
    ['What happens when I share to Explore?', 'Your build’s script, title, the name you choose and (if you leave it on) your prompt become public. Anyone can view, copy and remix it. You can delete your own builds anytime.'],
    ['Why only Gmail sign-in?', 'Every account gets free credits, so we keep sign-up to one verified inbox per person to stop people farming accounts.'],
  ];
  $('#faqList').innerHTML = faqs.map(function(f){ return '<details><summary>' + esc(f[0]) + '</summary><p>' + esc(f[1]) + '</p></details>'; }).join('');
  $('#year').textContent = new Date().getFullYear();

  // ------------------------------------------------------------------ boot
  (async function(){
    renderStudioControls();
    var hero = new Viewer($('#heroViewer'), {autoRotate: true});
    studio = new Viewer($('#studioViewer'));
    fetch('/showcase.lua').then(function(r){ return r.ok ? r.text() : C.EXAMPLE_SCRIPT; }).catch(function(){ return C.EXAMPLE_SCRIPT; })
      .then(runScript).then(function(ex){ hero.setParts(ex.parts); });
    await showResult();
    var q = new URLSearchParams(location.search);
    if (q.get('checkout')) {
      history.replaceState(null, '', location.pathname + '#pricing');
      if (q.get('checkout') === 'success') { toast('Payment received — your plan activates in a few seconds.'); setTimeout(refreshMe, 4000); setTimeout(refreshMe, 10000); }
    }
    await refreshMe();
    loadTurnstile(); // warm up the captcha so the sign-in box is ready instantly
    loadExplore(true);
  })();
})();
