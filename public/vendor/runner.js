// Brickwright preview runner: translates Luau-only syntax to Lua 5.3, runs it under fengari with the
// fake Roblox prelude, and returns the parts actually left in workspace.
// Rewrites Luau compound assignments (a += b, t[i] ..= "x", n //= 2) anywhere in a line, including
// after `then` / `do` / `else` / `;`, into plain Lua: a = a + (b).
var COMPOUND_RE = /(\+|-|\*|\/\/|\/|%|\^|\.\.)=(?!=)/g;
function scanCode(line){
  // mask[i] = 1 inside a string literal; codeEnd = start of a trailing -- comment
  var inStr = null, mask = new Array(line.length).fill(0), codeEnd = line.length;
  for (var i = 0; i < line.length; i++) {
    var ch = line[i];
    if (inStr) { mask[i] = 1; if (ch === '\\') { if (i + 1 < line.length) mask[i+1] = 1; i++; continue; } if (ch === inStr) inStr = null; continue; }
    if (ch === '"' || ch === "'" || ch === '`') { inStr = ch; mask[i] = 1; continue; }
    if (ch === '-' && line[i+1] === '-') { codeEnd = i; break; }
  }
  return {mask: mask, codeEnd: codeEnd};
}
function translateCompoundLine(line){
  var sc = scanCode(line), mask = sc.mask, codeEnd = sc.codeEnd;
  var guard = 0;
  while (guard++ < 20) {
    var found = null;
    COMPOUND_RE.lastIndex = 0;
    var m;
    while ((m = COMPOUND_RE.exec(line))) {
      var at = m.index;
      if (at >= codeEnd || mask[at]) continue;
      var prev = line[at - 1];
      if (m[1] === '-' && prev === '-') continue;            // part of a comment marker
      if (m[1] === '.' ) continue;
      if (prev === '=' || prev === '~' || prev === '<' || prev === '>') continue;
      found = m; break;
    }
    if (!found) break;
    var opAt = found.index, op = found[1], afterOp = opAt + found[0].length;
    // lvalue: walk back over spaces then an identifier/index chain
    var j = opAt - 1;
    while (j >= 0 && line[j] === ' ') j--;
    var lvEnd = j + 1, depth = 0;
    while (j >= 0) {
      var c = line[j];
      if (c === ']') { depth++; j--; continue; }
      if (c === '[') { depth--; j--; continue; }
      if (depth > 0 || /[\w\.:]/.test(c)) { j--; continue; }
      break;
    }
    var lvStart = j + 1;
    var lv = line.slice(lvStart, lvEnd);
    if (!/^[A-Za-z_]/.test(lv)) break;
    // expression: up to `;`, a block keyword (end/else/elseif/until) at depth 0, a comment, or end of line
    var k = afterOp, d = 0, q = null, stop = codeEnd;
    for (; k < codeEnd; k++) {
      var c2 = line[k];
      if (q) { if (c2 === '\\') { k++; continue; } if (c2 === q) q = null; continue; }
      if (c2 === '"' || c2 === "'") { q = c2; continue; }
      if (c2 === '(' || c2 === '{' || c2 === '[') d++;
      else if (c2 === ')' || c2 === '}' || c2 === ']') d--;
      else if (d === 0 && c2 === ';') { stop = k; break; }
      else if (d === 0 && /\s/.test(c2)) {
        var rest = line.slice(k + 1);
        if (/^(end|else|elseif|until)\b/.test(rest)) { stop = k; break; }
      }
    }
    var expr = line.slice(afterOp, stop).trim();
    if (!expr) break;
    var replacement = lv + ' = ' + lv + ' ' + op + ' (' + expr + ')';
    line = line.slice(0, lvStart) + replacement + (stop < line.length && line[stop] === '-' ? ' ' : '') + line.slice(stop);
    sc = scanCode(line); mask = sc.mask; codeEnd = sc.codeEnd;
  }
  return line;
}
function luauToLua(src){
  var out = [];
  var lines = src.replace(/\r\n?/g, '\n').split('\n');
  var inLong = false;
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    // leave long strings / block comments alone
    if (inLong) { if (/\]=*\]/.test(line)) inLong = false; out.push(line); continue; }
    if (/(--)?\[=*\[/.test(line) && !/\]=*\]/.test(line.slice(line.search(/\[=*\[/) + 2))) { inLong = true; out.push(line); continue; }
    out.push(translateCompoundLine(line));
  }
  var s = out.join('\n');
  // `continue` inside loops -> goto __continue (label inserted before each loop's closing `end` is hard;
  // handled by rewriting simple `if cond then continue end` into a guarded block is not general, so we
  // map `continue` to a goto and add a label at the end of every for/while body that uses it)
  if (/\bcontinue\b/.test(s)) s = rewriteContinue(s);
  // Luau type annotations on locals / params (simple forms only)
  s = s.replace(/(\blocal\s+[A-Za-z_]\w*)\s*:\s*[A-Za-z_][\w\.]*(\?)?(\s*[=\n])/g, '$1$3');
  s = s.replace(/\bfunction(\s*[\w\.:]*)\s*\(([^)]*)\)\s*:\s*[A-Za-z_][\w\.]*\??/g, function(all, name, params){
    return 'function' + name + '(' + stripParamTypes(params) + ')';
  });
  s = s.replace(/\bfunction(\s*[\w\.:]*)\s*\(([^)]*:[^)]*)\)/g, function(all, name, params){
    return 'function' + name + '(' + stripParamTypes(params) + ')';
  });
  // `if a then b else c` expressions (single line, simple)
  s = s.replace(/=\s*if\s+(.+?)\s+then\s+(.+?)\s+else\s+([^\n]+)/g, function(all, c, a, b){
    return '= ((function() if ' + c + ' then return ' + a + ' else return ' + b + ' end end)())';
  });
  return s;
}
function stripParamTypes(p){
  return p.split(',').map(function(x){ return x.replace(/:\s*[^,]+$/, '').replace(/\s+$/, ''); }).join(',');
}
function rewriteContinue(s){
  // Replace each `continue` with `goto __cont_N`, and put `::__cont_N::` just before the `end`
  // that closes the innermost enclosing loop. Uses a light keyword tokenizer (skips strings/comments).
  var toks = [], re = /--\[(=*)\[[\s\S]*?\]\1\]|--[^\n]*|\[(=*)\[[\s\S]*?\]\2\]|"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|\b(?:function|do|then|repeat|end|until|for|while|if|continue)\b/g, m;
  var stack = [], edits = [], n = 0;
  while ((m = re.exec(s))) {
    var w = m[0];
    if (w[0] === '-' || w[0] === '"' || w[0] === "'" || w[0] === '[') continue;
    if (w === 'for' || w === 'while') { stack.push({kind: 'loopHead'}); continue; }
    if (w === 'do') {
      var top = stack[stack.length - 1];
      if (top && top.kind === 'loopHead' && !top.opened) { top.opened = true; top.kind = 'loop'; }
      else stack.push({kind: 'block'});
      continue;
    }
    if (w === 'function') { stack.push({kind: 'func'}); continue; }
    if (w === 'if') { stack.push({kind: 'if'}); continue; }
    if (w === 'then') continue;
    if (w === 'repeat') { stack.push({kind: 'repeat'}); continue; }
    if (w === 'continue') {
      for (var j = stack.length - 1; j >= 0; j--) {
        if (stack[j].kind === 'loop' || stack[j].kind === 'repeat') {
          if (!stack[j].label) stack[j].label = '__cont_' + (++n);
          edits.push({at: m.index, len: 8, text: 'goto ' + stack[j].label});
          break;
        }
        if (stack[j].kind === 'func') break;
      }
      continue;
    }
    if (w === 'end' || w === 'until') {
      // `elseif ... then` pushes an extra 'if'; collapse consecutive ifs is unnecessary since `end` closes once
      var b = stack.pop();
      if (b && b.label) edits.push({at: m.index, len: 0, text: '::' + b.label + ':: '});
    }
  }
  edits.sort(function(a, b){ return b.at - a.at; });
  edits.forEach(function(e){ s = s.slice(0, e.at) + e.text + s.slice(e.at + e.len); });
  return s;
}

function withLine(msg, source){
  var m = /script:(\d+):/.exec(msg);
  if (!m) return msg;
  var ln = (source.replace(/\r\n?/g, '\n').split('\n')[+m[1] - 1] || '').trim();
  if (ln.length > 90) ln = ln.slice(0, 87) + '...';
  return msg + (ln ? '  — line ' + m[1] + ': ' + ln : '');
}
function runLuauPreview(fengari, prelude, brickHexTable, source){
  var lua = fengari.lua, lauxlib = fengari.lauxlib, lualib = fengari.lualib, to_luastring = fengari.to_luastring;
  var L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  function fail(msg){ return {ok: false, error: msg, parts: [], logs: []}; }
  // brick color table
  var hexLua = '__BRICK_HEX = {' + Object.keys(brickHexTable).map(function(k){
    return '[' + JSON.stringify(k) + ']=' + JSON.stringify(brickHexTable[k].replace('#', ''));
  }).join(',') + '}\n';
  if (lauxlib.luaL_loadstring(L, to_luastring(hexLua + prelude)) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK)
    return fail('preview runtime failed to load: ' + lua.lua_tojsstring(L, -1));
  var code = luauToLua(source);
  lua.lua_pushstring(L, to_luastring(code));
  lua.lua_setglobal(L, to_luastring('__SRC'));
  var runner =
    'local f, e = load(__SRC, "=script")\n' +
    'if not f then return "SYNTAX " .. tostring(e) .. "\\n\\n" end\n' +
    'local n = 0\n' +
    'debug.sethook(function() n = n + 1 if n > 400 then debug.sethook() error("script ran too long for the preview", 0) end end, "", 100000)\n' +
    'local ok, err = pcall(f)\n' +
    'debug.sethook()\n' +
    'return __export(ok, err)\n';
  if (lauxlib.luaL_loadstring(L, to_luastring(runner)) !== lua.LUA_OK) return fail(lua.lua_tojsstring(L, -1));
  if (lua.lua_pcall(L, 0, 1, 0) !== lua.LUA_OK) return fail(lua.lua_tojsstring(L, -1));
  var text = lua.lua_tojsstring(L, -1);
  var lines = text.split('\n');
  var status = lines[0], logs = (lines[1] || '').split('\t').filter(Boolean);
  if (status.indexOf('SYNTAX') === 0) return {ok: false, error: withLine(status.replace(/^SYNTAX /, 'syntax error: '), source), parts: [], logs: []};
  var parts = [];
  for (var i = 2; i < lines.length; i++) {
    if (!lines[i]) continue;
    var f = lines[i].split(',');
    var num = function(k){ return parseFloat(f[k]) || 0; };
    parts.push({
      s: ({b:'box', w:'wedge', k:'cornerwedge', c:'cylinder', s:'ball'})[f[0]] || 'box',
      sz: [num(1), num(2), num(3)],
      p: [num(4), num(5), num(6)],
      m: [num(4), num(5), num(6), num(7), num(8), num(9), num(10), num(11), num(12), num(13), num(14), num(15)],
      rgb: [num(16), num(17), num(18)],
      t: num(19),
      mat: f[20],
      faces: f[21] || '000000',
      name: f[22] || ''
    });
  }
  var err = status === 'OK' ? null : status.replace(/^ERR /, '');
  return {ok: status === 'OK', error: err ? withLine(err, source) : null, parts: parts, logs: logs};
}

if (typeof module !== 'undefined') module.exports = { luauToLua: luauToLua, runLuauPreview: runLuauPreview };
