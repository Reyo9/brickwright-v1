/* Brickwright — Animate page: AI auto-rig + AI animation, live 3D playback, export to a Roblox rig.
   Uses the shared helpers app.js puts on window.BW. */
(function(){
  'use strict';
  var $ = function(s, r){ return (r || document).querySelector(s); };
  var B = null, viewer = null;
  var state = {title: '', script: '', parts: [], rig: null, anims: [], current: -1};
  var nodes = {};         // group name -> THREE.Group
  var jointMarkers = [];
  var playing = false, t0 = 0, speed = 1, busy = false, currentJob = null;

  var PRESETS = [
    ['Idle', 'A calm idle loop: gentle breathing, slight head movement, small tail/ear sway if it has them.'],
    ['Walk', 'A walk cycle in place: legs swing in alternating pairs, body bobs slightly, head and tail counter-sway.'],
    ['Fly', 'Flying in place: big slow wing flaps, the body rises a little on each down-stroke, the tail streams and sways.'],
    ['Tail wag', 'A happy tail wag, fast side-to-side, with a slight head tilt.'],
    ['Look around', 'The head and neck turn slowly left, then right, then back to centre.'],
    ['Attack', 'One attack: wind up, then a fast strike forward with the head/arm/weapon, then recover. Not looping.'],
    ['Spin', 'The whole model spins slowly around its vertical axis, a full 360 degrees per loop.'],
    ['Hover', 'Hovering: the whole model bobs up and down gently and tilts a few degrees.'],
    ['Swim', 'Swimming in place: an S-wave runs down the body to the tail fin, side fins paddle, the body drifts up and down slightly.'],
    ['Wave hello', 'A friendly wave: one arm rises overhead and the forearm/hand swings side to side, the head tilts, the other arm stays relaxed.'],
    ['Dance', 'A fun looping dance: the body bounces to a beat, arms or wings pump up and down, the head bobs side to side.'],
    ['Tentacle wave', 'Every tentacle ripples in a slow rolling wave, each arm a little out of phase with its neighbours, the tips curling up; the body bobs gently.'],
    ['Breathe fire', 'A dragon fire breath: rear the head and neck back, open the jaw, then thrust the head forward and hold with the jaw open, wings half-raised. Not looping.'],
    ['Wheels / rotors', 'Every wheel, propeller, rotor or fan spins continuously around its own axle.'],
  ];

  function setStatus(text, kind, working){
    $('#status').className = 'status' + (kind ? ' ' + kind : '');
    $('#statusText').textContent = text; $('#progress').hidden = !working;
  }
  function save(){ try { sessionStorage.setItem('bw_anim_state', JSON.stringify(state)); } catch (e) {} }
  function costs(){ var me = B.getMe(); return (me && me.costs) || {rig: 10, animate: 10}; }
  function renderCost(){
    var me = B.getMe(), c = costs();
    $('#animCost').textContent = 'Rigging costs ' + (c.rig || 30) + ' credits, each animation ' + (c.animate || 45) + '. Only models you generated can be animated.' +
      (me && me.unlimited ? ' Unlimited credits (admin).' : me && me.signedIn ? ' You have ' + Number(me.remaining).toLocaleString() + '.' : '');
  }
  function refreshButtons(){
    $('#rigBtn').disabled = busy || !state.parts.length;
    $('#rigBtn').textContent = state.rig ? 'Re-rig' : 'Auto-rig';
    $('#animBtn').disabled = busy || !state.rig;
    var exp = !!(state.rig && state.anims.length);
    $('#exportCopy').disabled = $('#exportDl').disabled = !exp;
    $('#playBtn').disabled = state.current < 0;
    $('#stopBtn').hidden = !busy;
    $('#jointsToggleWrap').hidden = !state.rig;
  }

  // ------------------------------------------------------------ model loading
  async function loadModel(script, title, histId){
    state = {title: title || 'Untitled build', script: script, parts: [], rig: null, anims: [], current: -1, histId: histId};
    $('#animTitle').textContent = state.title;
    setStatus('Running the script…', '', true);
    var run = await B.runScript(script);
    state.parts = run.parts || [];
    if (!state.parts.length) { setStatus('That script didn’t produce any parts' + (run.error ? ': ' + run.error : '.'), 'err'); refreshButtons(); return; }
    rebuildScene();
    $('#modelPick').innerHTML = '<b>' + B.esc(state.title) + '</b><span class="muted small">' + state.parts.length + ' parts</span>';
    $('#previewInfo').textContent = state.parts.length + ' parts';
    setStatus('Model loaded — press Auto-rig.', 'ok');
    renderRig(); renderAnims(); refreshButtons(); save();
  }
  function rebuildScene(){
    stop();
    var msg = $('#animViewer .viewer-msg'); if (msg) msg.remove();
    viewer.setParts(state.parts);
    nodes = {}; jointMarkers.forEach(function(m){ m.parent && m.parent.remove(m); }); jointMarkers = [];
    if (state.rig) applyRig();
  }

  // ------------------------------------------------------------ rig
  function partLines(){
    return state.parts.map(function(p, i){
      var r = function(v){ return Math.round(v * 10) / 10; };
      return i + '|' + (p.name || 'Part') + '|' + p.sz.map(r).join(',') + '|' + p.p.map(r).join(',');
    }).join('\n');
  }
  function extractJSON(text){
    var m = /```(?:json)?\s*([\s\S]*?)```/i.exec(text);
    var body = m ? m[1] : text.slice(text.indexOf('{'), text.lastIndexOf('}') + 1);
    return JSON.parse(body);
  }
  function cleanName(n, i){ n = String(n || '').replace(/[^A-Za-z0-9_]/g, ''); return n || ('Group' + i); }
  function validateRig(r){
    var n = state.parts.length, seen = {}, names = {}, groups = [];
    (r.groups || []).forEach(function(g, gi){
      var name = cleanName(g.name, gi); while (names[name]) name += '2';
      names[name] = true;
      var piv = (g.pivot || []).map(Number);
      groups.push({name: name, parent: g.parent ? cleanName(g.parent) : null, pivot: piv.length === 3 && piv.every(isFinite) ? piv : null, parts: []});
      (g.parts || []).forEach(function(i){ i = Math.floor(Number(i)); if (i >= 0 && i < n && !seen[i]) { seen[i] = 1; groups[groups.length - 1].parts.push(i); } });
    });
    if (!groups.length) throw new Error('The AI didn’t return any rig groups.');
    var root = groups.filter(function(g){ return !g.parent || !names[g.parent]; })[0] || groups[0];
    groups.forEach(function(g){ if (g !== root && (!g.parent || !names[g.parent] || g.parent === g.name)) g.parent = root.name; });
    root.parent = null;
    for (var i = 0; i < n; i++) if (!seen[i]) root.parts.push(i);
    groups.forEach(function(g){ if (!g.pivot) g.pivot = centerOf(g.parts); });
    // parents before children; break cycles by re-parenting to root
    var ordered = [], placed = {};
    for (var guard = 0; guard < 50 && ordered.length < groups.length; guard++) {
      groups.forEach(function(g){ if (!placed[g.name] && (g.parent === null || placed[g.parent])) { ordered.push(g); placed[g.name] = 1; } });
    }
    groups.forEach(function(g){ if (!placed[g.name]) { g.parent = root.name; ordered.push(g); } });
    return {kind: String(r.kind || 'creature'), front: String(r.front || '-Z'), root: root.name, groups: ordered};
  }
  function centerOf(idx){
    if (!idx.length) return [0, 0, 0];
    var c = [0, 0, 0]; idx.forEach(function(i){ var p = state.parts[i].p; c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; });
    return c.map(function(v){ return Math.round(v / idx.length * 100) / 100; });
  }
  var COLORS = [0xff6b35, 0x3fd197, 0x4ea8ff, 0xffb547, 0xc77dff, 0xff5d8f, 0x5de0e6, 0xa3e635, 0xf472b6, 0xfbbf24];
  function applyRig(){
    var g = viewer.group, rig = state.rig;
    g.updateMatrixWorld(true);
    var meshes = {}; g.children.slice().forEach(function(m){ if (m.userData && m.userData.idx != null) meshes[m.userData.idx] = m; });
    nodes = {};
    rig.groups.forEach(function(gr, gi){
      var node = new THREE.Group(); node.name = gr.name;
      var parent = gr.parent ? nodes[gr.parent] : g;
      var pp = gr.parent ? rig.groups.filter(function(x){ return x.name === gr.parent; })[0].pivot : [0, 0, 0];
      node.position.set(gr.pivot[0] - pp[0], gr.pivot[1] - pp[1], gr.pivot[2] - pp[2]);
      node.userData.rest = node.position.clone();
      parent.add(node); node.updateMatrixWorld(true);
      nodes[gr.name] = node;
      gr.parts.forEach(function(i){ if (meshes[i]) node.attach(meshes[i]); });
      var mk = new THREE.Mesh(new THREE.SphereGeometry(0.35, 12, 10), new THREE.MeshBasicMaterial({color: COLORS[gi % COLORS.length], depthTest: false}));
      mk.renderOrder = 999; node.add(mk); jointMarkers.push(mk);
      mk.visible = $('#jointsToggle').checked;
    });
    viewer.dirty = true; viewer.kick();
  }
  function renderRig(){
    var el = $('#rigGroups');
    if (!state.rig) { el.innerHTML = ''; $('#rigInfo').textContent = 'The AI splits the model into movable parts and places the joints.'; return; }
    $('#rigInfo').textContent = state.rig.groups.length + ' joints · ' + state.rig.kind + ' · faces ' + state.rig.front;
    el.innerHTML = state.rig.groups.map(function(g, gi){
      return '<span class="chip rig-chip"><i style="background:#' + COLORS[gi % COLORS.length].toString(16).padStart(6, '0') + '"></i>' + B.esc(g.name) + ' <small>' + g.parts.length + '</small></span>';
    }).join('');
  }

  // ------------------------------------------------------------ AI jobs
  async function aiTask(kind, text){
    var job = await B.api('/api/generate', {method: 'POST', body: {prompt: [{role: 'user', content: text}], kind: kind, histId: state.histId}});
    currentJob = job.jobId; B.refreshMe().then(renderCost);
    var all = '', from = 0, t = Date.now();
    for (;;) {
      await new Promise(function(r){ setTimeout(r, 900); });
      var st = await B.api('/api/job?id=' + encodeURIComponent(job.jobId) + '&from=' + from);
      if (st.text) { all += st.text; from = st.length; }
      var s = Math.round((Date.now() - t) / 1000);
      setStatus((kind === 'rig' ? 'Rigging… ' : 'Animating… ') + s + 's' + (st.thinking ? ' · thinking' : ''), '', true);
      if (st.status === 'done') { currentJob = null; B.refreshMe().then(renderCost); return B.stripThink(all); }
      if (st.status === 'cancelled') { currentJob = null; B.refreshMe().then(renderCost); throw {message: 'Stopped — your credits were refunded.'}; }
      if (st.status === 'error') { currentJob = null; B.refreshMe().then(renderCost); throw {message: (st.error || 'Failed.') + (st.refunded ? ' Credits refunded.' : '')}; }
    }
  }
  function needLogin(){ if (!B.session()) { setStatus('Sign in to rig and animate.', 'err'); B.openLogin(); return true; } return false; }
  async function doRig(){
    if (busy || !state.parts.length || needLogin()) return;
    busy = true; refreshButtons();
    try {
      var text = await aiTask('rig', 'Model: "' + state.title + '" (' + state.parts.length + ' parts)\nParts:\n' + partLines());
      state.rig = validateRig(extractJSON(text));
      state.anims = []; state.current = -1;
      rebuildScene(); renderRig(); renderAnims();
      setStatus('Rigged into ' + state.rig.groups.length + ' joints. Now pick or describe an animation.', 'ok');
      save();
    } catch (e) { setStatus(e.message || 'Rigging failed — try again.', 'err'); }
    busy = false; refreshButtons();
  }
  function rigSummary(){
    return state.rig.groups.map(function(g){
      var bb = [Infinity, Infinity, Infinity, -Infinity, -Infinity, -Infinity];
      g.parts.forEach(function(i){ var p = state.parts[i]; for (var k = 0; k < 3; k++) { bb[k] = Math.min(bb[k], p.p[k] - p.sz[k] / 2); bb[k + 3] = Math.max(bb[k + 3], p.p[k] + p.sz[k] / 2); } });
      var size = g.parts.length ? [0, 1, 2].map(function(k){ return Math.round((bb[k + 3] - bb[k]) * 10) / 10; }) : [0, 0, 0];
      return g.name + ' | parent ' + (g.parent || 'none') + ' | pivot ' + g.pivot.map(function(v){ return Math.round(v * 10) / 10; }).join(',') + ' | size ' + size.join(',') + ' | ' + g.parts.length + ' parts';
    }).join('\n');
  }
  function validateAnim(a){
    var names = {}; state.rig.groups.forEach(function(g){ names[g.name] = 1; });
    var keys = {}, maxT = 0;
    Object.keys(a.keys || {}).forEach(function(gname){
      var n = cleanName(gname); if (!names[n]) return;
      var ks = (a.keys[gname] || []).map(function(k){ k = (k || []).map(Number); while (k.length < 7) k.push(0); return k.slice(0, 7).map(function(v){ return isFinite(v) ? v : 0; }); })
        .sort(function(x, y){ return x[0] - y[0]; });
      if (ks.length) { keys[n] = ks; maxT = Math.max(maxT, ks[ks.length - 1][0]); }
    });
    if (!Object.keys(keys).length) throw new Error('The animation didn’t move any part of the rig — try describing it differently.');
    var len = Math.max(0.2, Number(a.length) || maxT || 1, maxT);
    var name = String(a.name || 'Animation').replace(/[^A-Za-z0-9 _-]/g, '').slice(0, 24) || 'Animation';
    return {name: name, length: Math.round(len * 1000) / 1000, loop: a.loop !== false, keys: keys};
  }
  async function doAnim(){
    if (busy || !state.rig || needLogin()) return;
    var req = $('#animPrompt').value.trim();
    if (!req) { setStatus('Pick a preset or describe the motion first.', 'err'); $('#animPrompt').focus(); return; }
    busy = true; refreshButtons();
    try {
      var text = await aiTask('animate', 'Model: "' + state.title + '" · kind ' + state.rig.kind + ' · faces ' + state.rig.front +
        '\nGroups (name | parent | pivot | size | parts):\n' + rigSummary() + '\n\nAnimation request: ' + req);
      var a = validateAnim(extractJSON(text));
      var base = a.name, k = 2; while (state.anims.some(function(x){ return x.name === a.name; })) a.name = base + ' ' + (k++);
      state.anims.push(a); state.current = state.anims.length - 1;
      renderAnims(); play();
      setStatus('“' + a.name + '” is playing. Make more, or export.', 'ok');
      save();
    } catch (e) { setStatus(e.message || 'Animation failed — try again.', 'err'); }
    busy = false; refreshButtons();
  }
  function renderAnims(){
    var el = $('#animList');
    el.innerHTML = state.anims.map(function(a, i){
      return '<div class="anim-item' + (i === state.current ? ' on' : '') + '" data-i="' + i + '"><button class="anim-play" data-play="' + i + '">' + B.esc(a.name) + '<small>' + a.length + 's' + (a.loop ? ' · loop' : '') + '</small></button>' +
        '<button class="anim-del" data-del="' + i + '" aria-label="Delete animation">×</button></div>';
    }).join('');
  }

  // ------------------------------------------------------------ playback
  function ease(x){ return x * x * (3 - 2 * x); }
  function sample(keys, t){
    if (t <= keys[0][0]) return keys[0];
    for (var i = 0; i < keys.length - 1; i++) {
      var a = keys[i], b = keys[i + 1];
      if (t <= b[0]) { var f = ease((t - a[0]) / Math.max(1e-6, b[0] - a[0])), r = [t]; for (var k = 1; k < 7; k++) r.push(a[k] + (b[k] - a[k]) * f); return r; }
    }
    return keys[keys.length - 1];
  }
  var D = Math.PI / 180;
  function pose(t){
    var a = state.anims[state.current]; if (!a) return;
    var tt = a.loop ? t % a.length : Math.min(t, a.length);
    Object.keys(nodes).forEach(function(n){
      var node = nodes[n], keys = a.keys[n];
      if (!keys) { node.rotation.set(0, 0, 0); node.position.copy(node.userData.rest); return; }
      var k = sample(keys, tt);
      node.rotation.set(k[1] * D, k[2] * D, k[3] * D, 'XYZ');
      node.position.set(node.userData.rest.x + k[4], node.userData.rest.y + k[5], node.userData.rest.z + k[6]);
    });
  }
  function play(){
    if (state.current < 0) return;
    playing = true; t0 = performance.now();
    viewer.onFrame = function(){ pose((performance.now() - t0) / 1000 * speed); };
    viewer.kick(); $('#playBtn').classList.add('on');
    $('#playBtn').innerHTML = '<svg viewBox="0 0 24 24"><path d="M7 5h4v14H7zM13 5h4v14h-4z"/></svg>';
  }
  function stop(){
    playing = false; if (viewer) viewer.onFrame = null;
    Object.keys(nodes).forEach(function(n){ nodes[n].rotation.set(0, 0, 0); nodes[n].position.copy(nodes[n].userData.rest); });
    if (viewer) { viewer.dirty = true; viewer.kick(); }
    $('#playBtn').classList.remove('on');
    $('#playBtn').innerHTML = '<svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>';
  }

  // ------------------------------------------------------------ export to Roblox
  function lua(v){
    if (Array.isArray(v)) return '{' + v.map(lua).join(',') + '}';
    if (v && typeof v === 'object') return '{' + Object.keys(v).map(function(k){ return '[' + JSON.stringify(String(k)) + ']=' + lua(v[k]); }).join(',') + '}';
    if (typeof v === 'number') return String(Math.round(v * 1000) / 1000);
    if (typeof v === 'boolean') return v ? 'true' : 'false';
    return JSON.stringify(String(v)).replace(/\\u[0-9a-fA-F]{4}/g, '?');
  }
  function exportScript(){
    var rigData = {groups: state.rig.groups.map(function(g){
      return {name: g.name, parent: g.parent || false, pivot: g.pivot, parts: g.parts.map(function(i){ var p = state.parts[i]; return [p.name || '', p.p[0], p.p[1], p.p[2]]; })};
    })};
    var anims = {}; state.anims.forEach(function(a){ anims[a.name] = {length: a.length, loop: a.loop, keys: a.keys}; });
    var first = state.anims[state.current >= 0 ? state.current : 0].name;
    var animator = [
      'local model = script.Parent',
      'local RunService = game:GetService("RunService")',
      'local ANIMS = ' + lua(anims),
      'local motors = {}',
      'for _, d in ipairs(model:GetDescendants()) do',
      '\tif d:IsA("Motor6D") and d.Name:sub(1, 3) == "BW_" then motors[d.Name:sub(4)] = d end',
      'end',
      'local function ease(x) return x * x * (3 - 2 * x) end',
      'local function sample(keys, t)',
      '\tif t <= keys[1][1] then return keys[1] end',
      '\tfor i = 1, #keys - 1 do',
      '\t\tlocal a, b = keys[i], keys[i + 1]',
      '\t\tif t <= b[1] then',
      '\t\t\tlocal f = ease((t - a[1]) / math.max(1e-6, b[1] - a[1]))',
      '\t\t\tlocal r = { t }',
      '\t\t\tfor k = 2, 7 do r[k] = a[k] + (b[k] - a[k]) * f end',
      '\t\t\treturn r',
      '\t\tend',
      '\tend',
      '\treturn keys[#keys]',
      'end',
      'local current, t0 = nil, os.clock()',
      'RunService.Heartbeat:Connect(function()',
      '\tlocal name = model:GetAttribute("Animation")',
      '\tif name ~= current then',
      '\t\tcurrent, t0 = name, os.clock()',
      '\t\tfor _, m in pairs(motors) do m.Transform = CFrame.new() end',
      '\tend',
      '\tlocal a = ANIMS[name or ""]',
      '\tif not a then return end',
      '\tlocal t = (os.clock() - t0) * (model:GetAttribute("Speed") or 1)',
      '\tif a.loop then t = t % a.length else t = math.min(t, a.length) end',
      '\tfor g, keys in pairs(a.keys) do',
      '\t\tlocal m = motors[g]',
      '\t\tif m then',
      '\t\t\tlocal k = sample(keys, t)',
      '\t\t\tm.Transform = CFrame.new(k[5], k[6], k[7]) * CFrame.Angles(math.rad(k[2]), math.rad(k[3]), math.rad(k[4]))',
      '\t\tend',
      '\tend',
      'end)',
    ].join('\n');
    var lvl = '='; while (animator.indexOf(']' + lvl + ']') >= 0) lvl += '=';
    return [
      '--[[ Brickwright rig + animations for "' + state.title.replace(/\]\]/g, '') + '"',
      '     Paste into the Studio command bar and press Enter. It builds the model, adds Motor6D joints',
      '     and a BrickwrightAnimator script. Press Play/Run to see it move.',
      '     Animations: ' + state.anims.map(function(a){ return a.name; }).join(', '),
      '     Switch with the model\'s "Animation" attribute; "Speed" scales playback. ]]',
      '',
      'local __before = {}',
      'for _, c in ipairs(workspace:GetChildren()) do __before[c] = true end',
      'local function __build()',
      state.script,
      'end',
      '__build()',
      'local model, best = nil, 0',
      'for _, c in ipairs(workspace:GetChildren()) do',
      '\tif not __before[c] and c:IsA("Model") then',
      '\t\tlocal n = 0',
      '\t\tfor _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end',
      '\t\tif n > best then model, best = c, n end',
      '\tend',
      'end',
      'assert(model, "Brickwright: the build script did not create a model in workspace")',
      '',
      'local RIG = ' + lua(rigData),
      'local parts, used = {}, {}',
      'for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) end end',
      'local function find(name, x, y, z)',
      '\tlocal pick, bestD = nil, 2',
      '\tlocal at = Vector3.new(x, y, z)',
      '\tfor _, p in ipairs(parts) do',
      '\t\tif not used[p] and p.Name == name then',
      '\t\t\tlocal d = (p.Position - at).Magnitude',
      '\t\t\tif d < bestD then pick, bestD = p, d end',
      '\t\tend',
      '\tend',
      '\tif pick then used[pick] = true end',
      '\treturn pick',
      'end',
      'local rootPivot = RIG.groups[1].pivot',
      'local rigRoot = Instance.new("Part")',
      'rigRoot.Name = "RigRoot"; rigRoot.Size = Vector3.new(1, 1, 1); rigRoot.Transparency = 1',
      'rigRoot.CanCollide = false; rigRoot.Anchored = true',
      'rigRoot.CFrame = CFrame.new(rootPivot[1], rootPivot[2], rootPivot[3]); rigRoot.Parent = model',
      'local joints = {}',
      'for _, g in ipairs(RIG.groups) do',
      '\tlocal jp = Instance.new("Part")',
      '\tjp.Name = "Joint_" .. g.name; jp.Size = Vector3.new(0.2, 0.2, 0.2); jp.Transparency = 1',
      '\tjp.CanCollide = false; jp.Massless = true; jp.Anchored = false',
      '\tjp.CFrame = CFrame.new(g.pivot[1], g.pivot[2], g.pivot[3]); jp.Parent = model',
      '\tlocal p0 = (g.parent and joints[g.parent]) or rigRoot',
      '\tlocal m = Instance.new("Motor6D")',
      '\tm.Name = "BW_" .. g.name; m.Part0 = p0; m.Part1 = jp',
      '\tm.C0 = p0.CFrame:Inverse() * jp.CFrame; m.C1 = CFrame.new(); m.Parent = jp',
      '\tjoints[g.name] = jp',
      '\tfor _, ps in ipairs(g.parts) do',
      '\t\tlocal bp = find(ps[1], ps[2], ps[3], ps[4])',
      '\t\tif bp then',
      '\t\t\tbp.Anchored = false',
      '\t\t\tlocal w = Instance.new("WeldConstraint"); w.Part0 = jp; w.Part1 = bp; w.Parent = bp',
      '\t\tend',
      '\tend',
      'end',
      'model.PrimaryPart = rigRoot',
      'model:SetAttribute("Animation", ' + lua(first) + ')',
      'model:SetAttribute("Speed", 1)',
      'local animator = Instance.new("Script")',
      'animator.Name = "BrickwrightAnimator"',
      'animator.Source = [' + lvl + '[',
      animator,
      ']' + lvl + ']',
      'animator.Parent = model',
      'print("Brickwright: rigged " .. model.Name .. " with " .. #RIG.groups .. " joints. Press Play to see it move.")',
    ].join('\n');
  }

  // ------------------------------------------------------------ pickers
  async function pickHistory(){
    if (needLogin()) return;
    var b = B.openModal('<h3>Your builds</h3><p>Pick a model to rig and animate.</p><div class="grid pick-grid" id="pkGrid"><div class="skeleton"></div><div class="skeleton"></div><div class="skeleton"></div></div>', true);
    try {
      var j = await B.api('/api/history?offset=0');
      var g = $('#pkGrid', b);
      if (!j.items.length) { g.innerHTML = '<div class="empty">No builds yet — make one in the <a href="/studio">Studio</a> first.</div>'; return; }
      g.innerHTML = j.items.map(function(it){
        return '<button class="card" data-pick="' + B.esc(it.id) + '"><div class="thumb">' + (it.thumb ? '<img alt="" src="' + B.esc(it.thumb) + '">' : '<span>no preview</span>') + '</div>' +
          '<div class="meta"><h3>' + B.esc(it.brief || 'Untitled build') + '</h3><div class="sub"><span>' + B.ago(it.created) + ' · ' + it.parts + ' parts</span></div></div></button>';
      }).join('');
      g.onclick = async function(e){
        var c = e.target.closest('[data-pick]'); if (!c) return;
        var hid = c.getAttribute('data-pick');
        try { var it = await B.api('/api/history?id=' + encodeURIComponent(hid)); B.closeModal(); loadModel(it.script, it.brief || 'My build', hid); }
        catch (x) { B.toast(x.message, true); }
      };
    } catch (e) { $('#pkGrid', b).innerHTML = '<div class="empty">' + B.esc(e.message) + '</div>'; }
  }
  // ------------------------------------------------------------ boot
  function boot(){
    B = window.BW;
    viewer = new B.Viewer($('#animViewer'));
    $('#animPresets').innerHTML = PRESETS.map(function(p, i){ return '<button class="chip" data-preset="' + i + '">' + B.esc(p[0]) + '</button>'; }).join('');
    $('#animPresets').onclick = function(e){ var c = e.target.closest('[data-preset]'); if (c) { $('#animPrompt').value = PRESETS[+c.getAttribute('data-preset')][1]; $('#animPrompt').focus(); } };
    $('#pickHistory').onclick = pickHistory;
    $('#rigBtn').onclick = doRig;
    $('#animBtn').onclick = doAnim;
    $('#stopBtn').onclick = function(){ if (currentJob) B.api('/api/job?id=' + encodeURIComponent(currentJob), {method: 'POST', body: {cancel: true}}).catch(function(){}); setStatus('Stopping…', '', true); };
    $('#playBtn').onclick = function(){ if (playing) stop(); else play(); };
    $('#speed').oninput = function(){ var v = +this.value; t0 = performance.now() - (performance.now() - t0) * speed / v; speed = v; $('#speedVal').textContent = v + '×'; };
    $('#jointsToggle').onchange = function(){ var v = this.checked; jointMarkers.forEach(function(m){ m.visible = v; }); viewer.dirty = true; viewer.kick(); };
    $('#animList').onclick = function(e){
      var d = e.target.closest('[data-del]');
      if (d) { var i = +d.getAttribute('data-del'); state.anims.splice(i, 1); if (state.current >= state.anims.length) state.current = state.anims.length - 1; stop(); renderAnims(); refreshButtons(); save(); if (state.current >= 0) play(); return; }
      var p = e.target.closest('[data-play]'); if (p) { state.current = +p.getAttribute('data-play'); renderAnims(); play(); refreshButtons(); }
    };
    $('#exportCopy').onclick = function(){ navigator.clipboard && navigator.clipboard.writeText(exportScript()).then(function(){ B.toast('Rig script copied — paste it into the Studio command bar.'); }); };
    $('#exportDl').onclick = function(){ B.download(state.title + ' rigged', exportScript()); };
    renderCost(); refreshButtons();
    // incoming model from the Studio / Explore, or a session restore
    var inc = null; try { inc = JSON.parse(sessionStorage.getItem('bw_anim') || 'null'); sessionStorage.removeItem('bw_anim'); } catch (e) {}
    var saved = null; try { saved = JSON.parse(sessionStorage.getItem('bw_anim_state') || 'null'); } catch (e) {}
    if (inc && inc.histId) {
      var openInc = function(){ B.api('/api/history?id=' + encodeURIComponent(inc.histId)).then(function(it){ loadModel(it.script, it.brief || 'My build', inc.histId); })
        .catch(function(e){ setStatus(e.code === 'login' ? 'Sign in to animate your builds.' : e.message, 'err'); }); };
      if (B.session()) openInc(); else { setStatus('Sign in to animate your builds.', 'err'); }
    }
    else if (saved && saved.script && saved.histId) {
      loadModel(saved.script, saved.title, saved.histId).then(function(){
        if (saved.rig) { state.rig = saved.rig; state.anims = saved.anims || []; state.current = saved.current; rebuildScene(); renderRig(); renderAnims(); refreshButtons(); if (state.current >= 0) play(); setStatus('Restored your last session.', 'ok'); }
      });
    }
  }
  document.addEventListener('bw:ready', function(){ renderCost(); });
  if (window.BW) boot(); else document.addEventListener('DOMContentLoaded', function(){ boot(); });
  window.__bwAnim = {get state(){ return state; }, exportScript: function(){ return exportScript(); }};
})();
