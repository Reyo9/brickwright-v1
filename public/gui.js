// GUI Maker: AI designs a Roblox ScreenGui as JSON → live preview (works like in-game) → Luau script.
(function(){
  'use strict';
  var $ = function(s, r){ return (r || document).querySelector(s); };
  var $$ = function(s, r){ return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var B = null;

  // ---------------------------------------------------------------- icons
  // Preview glyphs for the icon names the AI may use. Roblox image IDs go in ICON_IDS (filled from the icon pack).
  var ICON_GLYPH = {coin:'🪙', gem:'💎', cash:'💵', star:'⭐', heart:'❤️', shield:'🛡️', sword:'⚔️', bow:'🏹', pet:'🐾', egg:'🥚', crown:'👑', trophy:'🏆', gift:'🎁',
    lock:'🔒', unlock:'🔓', cart:'🛒', bag:'👜', backpack:'🎒', settings:'⚙️', close:'✖', check:'✔', plus:'➕', minus:'➖', arrow_left:'◀', arrow_right:'▶', arrow_up:'▲', arrow_down:'▼',
    home:'🏠', user:'👤', users:'👥', chat:'💬', bell:'🔔', info:'ℹ️', warning:'⚠️', question:'❓', search:'🔍', clock:'⏰', calendar:'📅', map:'🗺️', flag:'🚩', fire:'🔥',
    lightning:'⚡', snowflake:'❄️', leaf:'🍃', music:'🎵', sound:'🔊', mute:'🔇', play:'▶', pause:'⏸', refresh:'🔄', trash:'🗑️', edit:'✏️', upload:'⬆', download:'⬇',
    share:'📤', eye:'👁️', key:'🔑', potion:'🧪', hammer:'🔨', pickaxe:'⛏️', fish:'🐟', car:'🚗', rocket:'🚀', ticket:'🎟️', chest:'🧰', rebirth:'♻️', boost:'🚀', x2:'✖2'};
  var PACK = {"cell":128,"color":{"bunny":[0,0,0],"cat":[0,128,0],"dog":[0,256,0],"cash":[0,384,0],"coin":[0,512,0],"crystal":[0,640,0],"diamond":[0,768,0],"ingot":[0,896,0],"premium":[0,0,128],"robux":[0,128,128],"ticket":[0,256,128],"angel_heart":[0,384,128],"aura":[0,512,128],"aura2":[0,640,128],"magical_teleport":[0,768,128],"toilet":[0,896,128],"trail":[0,0,256],"tung":[0,128,256],"vip":[0,256,256],"avocado":[0,384,256],"bait":[0,512,256],"blueberry":[0,640,256],"burger":[0,768,256],"carrot":[0,896,256],"cookie":[0,0,384],"lemon":[0,128,384],"pancake":[0,256,384],"pizza":[0,384,384],"axe":[0,512,384],"backpack":[0,640,384],"balloon":[0,768,384],"bomb":[0,896,384],"book":[0,0,512],"box":[0,128,512],"bubble_gum":[0,256,512],"calendar":[0,384,512],"chest":[0,512,512],"clock":[0,640,512],"coil":[0,768,512],"cracked_egg":[0,896,512],"credit_card":[0,0,640],"crown":[0,128,640],"dice":[0,256,640],"egg":[0,384,640],"gift":[0,512,640],"gum":[0,640,640],"hammer":[0,768,640],"key":[0,896,640],"location_pin":[0,0,768],"lock":[0,128,768],"lucky_block":[0,256,768],"magnet":[0,384,768],"medal":[0,512,768],"newspaper":[0,640,768],"pencil":[0,768,768],"potion":[0,896,768],"rocket":[0,0,896],"scroll":[0,128,896],"shield":[0,256,896],"shoe":[0,384,896],"shovel":[0,512,896],"sword":[0,640,896],"target":[0,768,896],"teleporter":[0,896,896],"torch":[1,0,0],"trophy":[1,128,0],"broken_heart":[1,256,0],"codes":[1,384,0],"downgrade":[1,512,0],"fire":[1,640,0],"fire2":[1,768,0],"heart":[1,896,0],"house":[1,0,128],"hoverboard":[1,128,128],"lightning":[1,256,128],"search":[1,384,128],"music_off":[1,512,128],"music_on":[1,640,128],"paw":[1,768,128],"auto_open":[1,896,128],"save":[1,0,256],"settings":[1,128,256],"bag":[1,256,256],"cart":[1,384,256],"sound_off":[1,512,256],"sound_on":[1,640,256],"star":[1,768,256],"stats":[1,896,256],"trade":[1,0,384],"trash":[1,128,384],"upgrade":[1,256,384],"verify":[1,384,384],"wheel":[1,512,384],"apple":[1,640,384],"banana":[1,768,384],"cloud":[1,896,384],"cloud2":[1,0,512],"clover":[1,128,512],"leaf":[1,256,512],"orange":[1,384,512],"planet":[1,512,512],"strawberry":[1,640,512],"thunderstorm":[1,768,512],"wheat":[1,896,512],"players":[1,0,640],"add_player":[1,128,640],"arm":[1,256,640],"friend":[1,384,640],"full_body":[1,512,640],"player":[1,640,640],"rip":[1,768,640],"skull":[1,896,640],"devil":[1,0,768],"gamepad":[1,128,768],"guilded":[1,256,768],"bird":[1,384,768],"close_x":[2,128,0],"chat":[1,640,768],"check":[1,768,768],"check_button":[1,896,768],"close":[1,0,896],"cursor":[1,128,896],"exclamation":[1,256,896],"info":[1,384,896],"minus":[1,512,896],"plus":[1,640,896],"question":[1,768,896],"skip":[1,896,896],"warning":[2,0,0]},"white":{"cash":[0,0,0],"coin":[0,128,0],"crystal":[0,256,0],"diamond":[0,384,0],"ingot":[0,512,0],"premium":[0,640,0],"robux":[0,768,0],"ticket":[0,896,0],"avocado":[0,0,128],"bait":[0,128,128],"blueberry":[0,256,128],"burger":[0,384,128],"carrot":[0,512,128],"cookie":[0,640,128],"lemon":[0,768,128],"pancake":[0,896,128],"pizza":[0,0,256],"axe":[0,128,256],"backpack":[0,256,256],"balloon":[0,384,256],"bomb":[0,512,256],"book":[0,640,256],"box":[0,768,256],"bubble_gum":[0,896,256],"calendar":[0,0,384],"chest":[0,128,384],"clock":[0,256,384],"coil":[0,384,384],"cracked_egg":[0,512,384],"credit_card":[0,640,384],"crown":[0,768,384],"dice":[0,896,384],"egg":[0,0,512],"gift":[0,128,512],"gum":[0,256,512],"hammer":[0,384,512],"key":[0,512,512],"location_pin":[0,640,512],"lock":[0,768,512],"lucky_block":[0,896,512],"magnet":[0,0,640],"medal":[0,128,640],"newspaper":[0,256,640],"pencil":[0,384,640],"potion":[0,512,640],"rocket":[0,640,640],"scroll":[0,768,640],"shield":[0,896,640],"shoe":[0,0,768],"shovel":[0,128,768],"sword":[0,256,768],"target":[0,384,768],"teleporter":[0,512,768],"torch":[0,640,768],"trophy":[0,768,768],"broken_heart":[0,896,768],"codes":[0,0,896],"downgrade":[0,128,896],"fire":[0,256,896],"fire2":[0,384,896],"heart":[0,512,896],"house":[0,640,896],"hoverboard":[0,768,896],"lightning":[0,896,896],"search":[1,0,0],"music_off":[1,128,0],"music_on":[1,256,0],"paw":[1,384,0],"save":[1,512,0],"settings":[1,640,0],"bag":[1,768,0],"cart":[1,896,0],"sound_off":[1,0,128],"sound_on":[1,128,128],"star":[1,256,128],"stats":[1,384,128],"trade":[1,512,128],"trash":[1,640,128],"upgrade":[1,768,128],"verify":[1,896,128],"wheel":[1,0,256],"apple":[1,128,256],"banana":[1,256,256],"cloud":[1,384,256],"cloud2":[1,512,256],"clover":[1,640,256],"leaf":[1,768,256],"orange":[1,896,256],"planet":[1,0,384],"strawberry":[1,128,384],"thunderstorm":[1,256,384],"wheat":[1,384,384],"players":[1,512,384],"add_player":[1,640,384],"arm":[1,768,384],"friend":[1,896,384],"full_body":[1,0,512],"player":[1,128,512],"rip":[1,256,512],"skull":[1,384,512],"devil":[1,512,512],"gamepad":[1,640,512],"guilded":[1,768,512],"bird":[1,896,512],"close_x":[1,640,768],"chat":[1,128,640],"check":[1,256,640],"check_button":[1,384,640],"close":[1,512,640],"cursor":[1,640,640],"exclamation":[1,768,640],"info":[1,896,640],"minus":[1,0,768],"plus":[1,128,768],"question":[1,256,768],"skip":[1,384,768],"warning":[1,512,768]},"cid":["130519321592979","129307888123090","86042569574842"],"wid":["129686390273716","100116007474180"]};
  var ALIAS = {"gem": "diamond", "user": "player", "users": "players", "home": "house", "pet": "paw", "bag": "bag", "edit": "pencil", "x": "close", "map": "location_pin", "sound": "sound_on", "mute": "sound_off", "music": "music_on", "rebirth": "auto_open", "boost": "upgrade", "unlock": "lock", "bell": "exclamation", "lightning": "lightning", "pickaxe": "shovel", "fish": "bait", "x2": "premium", "refresh": "auto_open", "bow": "target", "snowflake": "cloud", "share": "trade", "eye": "search", "flag": "location_pin", "car": "hoverboard"};
  function iconKey(n){ n = String(n||'').toLowerCase(); return PACK.color[n] ? n : (ALIAS[n] || n); }
  function iconRef(n, white){ var k = iconKey(n), w = white && PACK.white[k], e = w || PACK.color[k]; if (!e) return null; return {id: (w ? PACK.wid : PACK.cid)[e[0]], sheet: (w ? 'white_' : 'color_') + (e[0]+1), x: e[1], y: e[2], white: !!w}; }
  var ICON_IDS = window.BW_ICON_IDS || {}; // name → "rbxassetid://123" (icon pack)
  var STUD_ID = window.BW_STUD_ID || 'rbxassetid://6927295847'; // Roblox image ID of /stud-tile.png once uploaded

  var FONTS = {Gotham:['Montserrat',500], GothamMedium:['Montserrat',600], GothamBold:['Montserrat',700], GothamBlack:['Montserrat',900],
    FredokaOne:['Fredoka',700], LuckiestGuy:['Luckiest Guy',400], Bangers:['Bangers',400], Arcade:['Press Start 2P',400],
    SourceSans:['Source Sans 3',400], SourceSansSemibold:['Source Sans 3',600], SourceSansBold:['Source Sans 3',700],
    Arial:['Arial',400], ArialBold:['Arial',700], Roboto:['Roboto',400], Ubuntu:['Ubuntu',400], Cartoon:['Fredoka',500], Highway:['Montserrat',600], SciFi:['Press Start 2P',400]};
  var ROBLOX_FONTS = Object.keys(FONTS).concat(['Oswald', 'Michroma', 'Creepster', 'PermanentMarker', 'DenkOne', 'Fondamento', 'Kalam', 'RobotoMono']);
  var CLASSES = ['Frame', 'TextLabel', 'TextButton', 'TextBox', 'ImageLabel', 'ImageButton', 'ScrollingFrame'];
  var DEVICES = {pc: [1280, 720], tablet: [1024, 768], phone: [844, 390]};
  var STYLES = [
    ['Dark modern', 'dark modern: near-black panels (#15171f / #1d2030), soft white text, rounded corners, thin light strokes, accent-coloured gradient buttons, GothamBold'],
    ['Cartoon simulator', 'bright cartoony simulator game: chunky rounded panels with thick dark strokes, saturated colours, big FredokaOne text with dark text stroke, playful gradients'],
    ['Neon gamer', 'neon gamer: very dark background, glowing accent-coloured strokes and gradients, high contrast, GothamBlack titles'],
    ['Clean light', 'clean light: off-white panels (#f4f5f8), dark grey text, subtle shadows/strokes, accent buttons, Gotham fonts'],
    ['Fantasy RPG', 'fantasy RPG: parchment/wood/gold colours, ornate thick borders, warm tones, SourceSansBold titles'],
    ['Retro pixel', 'retro pixel arcade: hard square corners (corner 0-4), bold flat colours, Arcade font for titles, chunky borders'],
    ['Stud brick', 'STUD STYLE: classic Roblox brick look with "studs": true on the window, title bar, panels and big buttons, bold saturated brick colours, thick darker strokes, small corners, chunky SourceSansBold or FredokaOne text'],
    ['Sci-fi HUD', 'sci-fi HUD: translucent dark panels (bgT 0.2-0.4), cyan/teal accents, thin strokes, Michroma or GothamMedium']];
  var CHIPS = [
    ['Shop menu', 'A shop menu with 3 tabs (Swords, Pets, Gamepasses), a scrolling grid of item cards each with an icon, name, price with a coin icon and a Buy button, a coins counter in the title bar and a close button. Starts closed with a Shop button on the left side of the screen.'],
    ['Inventory', 'An inventory window with a 5-column scrolling grid of item slots (some with icons and stack counts), a selected-item details panel on the right with name, rarity, description and Equip / Drop buttons, and a search box.'],
    ['Daily rewards', 'A daily rewards popup with 7 day cards in a row (day number, reward icon and amount), today highlighted, claimed days dimmed with a check, a big Claim button and a close button.'],
    ['Settings', 'A settings menu with toggles for Music, Sound effects, Shadows and Low graphics, a sensitivity slider bar, a "Reset to default" button and a close button.'],
    ['Game HUD', 'A simulator HUD: coins and gems counters top-left, a row of round buttons on the left side (Shop, Pets, Rebirth, Settings), a health bar bottom-centre and a quest tracker top-right.'],
    ['Admin panel', 'A dark admin panel with a sidebar of tabs (Players, Server, Fun, Logs), a players page with a scrolling list of player rows (avatar circle, name, Kick / Teleport buttons) and a search box at the top.'],
    ['Main menu', 'A game main menu with a big game title, Play, Settings, Shop and Credits buttons stacked in the middle, a version label in the corner.'],
    ['Pet hatch', 'An egg hatching popup: egg icon in the middle, egg name and price, chance list of 6 pets with percentages, Hatch 1 / Hatch 3 / Auto buttons and a close button.']];

  // ---------------------------------------------------------------- example (shown before the first generation)
  var EXAMPLE = {name: 'ShopGui', theme: 'dark modern with orange accent', root: {class: 'Frame', name: 'ShopWindow', pos: [0.5,0,0.5,0], size: [0.55,0,0.7,0], anchor: [0.5,0.5], bg: '#171a23', corner: 16,
    stroke: {color: '#ffffff', thickness: 1.5, transparency: 0.85}, aspect: 1.55, children: [
      {class: 'Frame', name: 'TitleBar', pos: [0,0,0,0], size: [1,0,0.14,0], bg: '#ffffff', corner: 16, gradient: {colors: ['#ff6b35', '#ffb547'], rotation: 0}, children: [
        {class: 'TextLabel', name: 'Title', pos: [0.04,0,0,0], size: [0.5,0,1,0], bgT: 1, text: 'SHOP', textColor: '#1a0b03', font: 'GothamBlack', textScaled: true, xAlign: 'Left', padding: [10,0,10,0]},
        {class: 'Frame', name: 'CoinsPill', pos: [0.62,0,0.5,0], anchor: [0,0.5], size: [0.22,0,0.6,0], bg: '#1a0b03', bgT: 0.35, corner: 99, children: [
          {class: 'ImageLabel', name: 'CoinIcon', pos: [0.06,0,0.5,0], anchor: [0,0.5], size: [0,26,0,26], bgT: 1, icon: 'coin'},
          {class: 'TextLabel', name: 'Coins', pos: [0.3,0,0,0], size: [0.65,0,1,0], bgT: 1, text: '12,450', textColor: '#ffffff', font: 'GothamBold', textSize: 18, xAlign: 'Left'}]},
        {class: 'TextButton', name: 'CloseButton', pos: [0.97,0,0.5,0], anchor: [1,0.5], size: [0,40,0,40], bg: '#1a0b03', bgT: 0.3, corner: 10, text: 'X', textColor: '#ffffff', font: 'GothamBlack', textSize: 20}]},
      {class: 'Frame', name: 'Tabs', pos: [0.03,0,0.18,0], size: [0.94,0,0.09,0], bgT: 1, list: {dir: 'Horizontal', padding: 8}, children: [
        {class: 'TextButton', name: 'SwordsTab', size: [0.2,0,1,0], bg: '#262b38', corner: 10, text: 'Swords', textColor: '#ffffff', font: 'GothamBold', textSize: 16},
        {class: 'TextButton', name: 'PetsTab', size: [0.2,0,1,0], bg: '#262b38', corner: 10, text: 'Pets', textColor: '#ffffff', font: 'GothamBold', textSize: 16}]},
      {class: 'ScrollingFrame', name: 'SwordsPage', pos: [0.03,0,0.3,0], size: [0.94,0,0.66,0], bgT: 1, auto: true, padding: 4, grid: {cell: [0.31,0,0,150], padding: [0.02,0,0,12]}, children: []},
      {class: 'ScrollingFrame', name: 'PetsPage', pos: [0.03,0,0.3,0], size: [0.94,0,0.66,0], bgT: 1, auto: true, padding: 4, grid: {cell: [0.31,0,0,150], padding: [0.02,0,0,12]}, children: []}]},
    behaviors: [{type: 'close', button: 'CloseButton', target: 'ShopWindow'}, {type: 'tabs', buttons: ['SwordsTab', 'PetsTab'], pages: ['SwordsPage', 'PetsPage']}]};
  (function fillExample(){
    var items = [['Wood Sword', 'sword', 100], ['Iron Sword', 'sword', 750], ['Fire Blade', 'fire', 4000], ['Ice Edge', 'snowflake', 9000], ['Thunder', 'lightning', 25000], ['Royal Sword', 'crown', 99000]];
    var pets = [['Puppy', 'pet', 200], ['Dragon Egg', 'egg', 1500], ['Golden Fish', 'fish', 5000]];
    function card(prefix, it, i){
      return {class: 'Frame', name: prefix + 'Card' + i, bg: '#20242f', corner: 12, stroke: {color: '#ffffff', thickness: 1, transparency: 0.9}, children: [
        {class: 'ImageLabel', name: prefix + 'Icon' + i, pos: [0.5,0,0.08,0], anchor: [0.5,0], size: [0,54,0,54], bgT: 1, icon: it[1]},
        {class: 'TextLabel', name: prefix + 'Name' + i, pos: [0,0,0.48,0], size: [1,0,0.16,0], bgT: 1, text: it[0], textColor: '#ffffff', font: 'GothamBold', textSize: 15},
        {class: 'TextButton', name: prefix + 'Buy' + i, pos: [0.5,0,0.92,0], anchor: [0.5,1], size: [0.8,0,0.24,0], bg: '#ffffff', corner: 8, gradient: {colors: ['#ff6b35', '#ffb547'], rotation: 0},
          text: '🪙 ' + it[2].toLocaleString(), textColor: '#1a0b03', font: 'GothamBold', textSize: 14}]};
    }
    EXAMPLE.root.children[2].children = items.map(function(it, i){ return card('Sword', it, i + 1); });
    EXAMPLE.root.children[3].children = pets.map(function(it, i){ return card('Pet', it, i + 1); });
    EXAMPLE.behaviors.push({type: 'hover', buttons: items.map(function(_, i){ return 'SwordBuy' + (i + 1); })});
  })();

  // ---------------------------------------------------------------- helpers
  function num(v, d){ v = Number(v); return isFinite(v) ? v : d; }
  function udim2(a, d){ if (!Array.isArray(a)) return d; return [num(a[0], 0), num(a[1], 0), num(a[2], 0), num(a[3], 0)]; }
  function hex(c, d){ c = String(c || ''); return /^#?[0-9a-f]{6}$/i.test(c) ? (c[0] === '#' ? c : '#' + c).toLowerCase() : d; }
  function calc(scale, off){ return 'calc(' + (scale * 100) + '% + ' + off + 'px)'; }
  function pad4(p){ if (Array.isArray(p)) return [num(p[0], 0), num(p[1], 0), num(p[2], 0), num(p[3], 0)]; var n = num(p, 0); return [n, n, n, n]; }
  function walk(node, fn, parent){ fn(node, parent); (node.children || []).forEach(function(c){ walk(c, fn, node); }); }
  function esc(s){ return String(s == null ? '' : s).replace(/[&<>"']/g, function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; }); }

  // Clean up whatever the AI sent so the preview and script never crash
  function sanitize(spec){
    if (!spec || typeof spec !== 'object' || !spec.root) throw new Error('The AI didn’t return a GUI.');
    var used = {};
    function fix(n, depth){
      if (!n || typeof n !== 'object' || depth > 14) return null;
      var o = {};
      o.class = CLASSES.indexOf(n.class) >= 0 ? n.class : (n.text != null ? 'TextLabel' : 'Frame');
      var name = String(n.name || o.class).replace(/[^A-Za-z0-9_]/g, '').slice(0, 40) || o.class, base = name, k = 2;
      while (used[name]) name = base + (k++);
      used[name] = 1; o.name = name;
      ['pos', 'size'].forEach(function(f){ if (n[f]) o[f] = udim2(n[f], null); });
      if (Array.isArray(n.anchor)) o.anchor = [num(n.anchor[0], 0), num(n.anchor[1], 0)];
      o.bg = hex(n.bg, '#ffffff'); o.bgT = Math.max(0, Math.min(1, num(n.bgT, /Text|Image/.test(o.class) && !/Button/.test(o.class) && n.bg == null ? 1 : 0)));
      if (/^Text/.test(o.class)) {
        o.text = n.text == null ? '' : String(n.text).slice(0, 300);
        o.textColor = hex(n.textColor, '#ffffff'); o.font = ROBLOX_FONTS.indexOf(n.font) >= 0 ? n.font : 'GothamBold';
        o.textSize = Math.max(6, Math.min(100, num(n.textSize, 18))); o.textScaled = !!n.textScaled;
        o.xAlign = ['Left', 'Right', 'Center'].indexOf(n.xAlign) >= 0 ? n.xAlign : 'Center';
        o.yAlign = ['Top', 'Bottom', 'Center'].indexOf(n.yAlign) >= 0 ? n.yAlign : 'Center';
        if (o.class === 'TextBox') o.placeholder = String(n.placeholder || '').slice(0, 80);
      }
      if (/^Image/.test(o.class)) { o.icon = String(n.icon || '').toLowerCase(); o.iconColor = hex(n.iconColor, '#ffffff'); o.iconWhite = n.iconStyle === 'white'; }
      ['zIndex', 'rotation'].forEach(function(f){ if (n[f] != null) o[f] = num(n[f], 0); });
      o.visible = n.visible !== false; o.clip = !!n.clip;
      if (o.class === 'ScrollingFrame') { o.auto = n.auto !== false && !n.canvas; if (Array.isArray(n.canvas)) o.canvas = [num(n.canvas[0], 0), num(n.canvas[1], 0)]; }
      if (n.corner != null) o.corner = Array.isArray(n.corner) ? [num(n.corner[0], 0), num(n.corner[1], 0)] : [0, num(n.corner, 8)];
      if (n.stroke && typeof n.stroke === 'object') o.stroke = {color: hex(n.stroke.color, '#000000'), thickness: Math.max(0, Math.min(12, num(n.stroke.thickness, 1.5))), transparency: Math.max(0, Math.min(1, num(n.stroke.transparency, 0)))};
      if (n.gradient && Array.isArray(n.gradient.colors) && n.gradient.colors.length >= 2) o.gradient = {colors: n.gradient.colors.slice(0, 4).map(function(c){ return hex(c, '#ffffff'); }), rotation: num(n.gradient.rotation, 0)};
      if (n.padding != null) o.padding = pad4(n.padding);
      if (n.list && typeof n.list === 'object') o.list = {dir: n.list.dir === 'Horizontal' ? 'Horizontal' : 'Vertical', padding: num(n.list.padding, 0),
        hAlign: ['Left', 'Right', 'Center'].indexOf(n.list.hAlign) >= 0 ? n.list.hAlign : 'Left', vAlign: ['Top', 'Bottom', 'Center'].indexOf(n.list.vAlign) >= 0 ? n.list.vAlign : 'Top'};
      else if (n.grid && typeof n.grid === 'object') o.grid = {cell: udim2(n.grid.cell, [0, 100, 0, 100]), padding: udim2(n.grid.padding, [0, 5, 0, 5])};
      if (n.studs) o.studs = typeof n.studs === 'number' ? Math.max(8, Math.min(80, n.studs)) : 16;
      if (n.aspect != null && num(n.aspect, 0) > 0) o.aspect = num(n.aspect, 1);
      o.children = (Array.isArray(n.children) ? n.children : []).slice(0, 200).map(function(c){ return fix(c, depth + 1); }).filter(Boolean);
      return o;
    }
    var out = {name: String(spec.name || 'BrickwrightGui').replace(/[^A-Za-z0-9_]/g, '').slice(0, 40) || 'BrickwrightGui', theme: String(spec.theme || ''),
      root: fix(spec.root, 0), extra: (Array.isArray(spec.extra) ? spec.extra : []).slice(0, 20).map(function(n){ return fix(n, 0); }).filter(Boolean)};
    var names = used;
    out.behaviors = (Array.isArray(spec.behaviors) ? spec.behaviors : []).filter(function(b){
      if (!b || typeof b !== 'object') return false;
      if (b.type === 'toggle' || b.type === 'close') return names[b.button] && names[b.target];
      if (b.type === 'tabs') return Array.isArray(b.buttons) && Array.isArray(b.pages) && b.buttons.length && b.buttons.length === b.pages.length && b.buttons.concat(b.pages).every(function(x){ return names[x]; });
      if (b.type === 'hover' || b.type === 'bounce') return Array.isArray(b.buttons) && b.buttons.some(function(x){ return names[x]; });
      if (b.type === 'popin' || b.type === 'pulse' || b.type === 'spin') return names[b.target];
      if (b.type === 'countup') return names[b.label] && isFinite(Number(b.to));
      return false;
    }).map(function(b){
      if (b.type === 'hover' || b.type === 'bounce') return {type: b.type, buttons: b.buttons.filter(function(x){ return names[x]; })};
      if (b.type === 'countup') return {type: 'countup', label: b.label, to: Math.max(0, Math.min(1e12, Number(b.to))), prefix: String(b.prefix || '').slice(0, 6), suffix: String(b.suffix || '').slice(0, 8), short: !!b.short};
      if (b.type === 'spin') return {type: 'spin', target: b.target, speed: Math.max(10, Math.min(720, Number(b.speed) || 60))};
      if (b.type === 'popin' || b.type === 'pulse') return {type: b.type, target: b.target};
      return b;
    });
    var count = 0; [out.root].concat(out.extra).forEach(function(r){ walk(r, function(){ count++; }); });
    out.count = count;
    return out;
  }

  // ---------------------------------------------------------------- preview renderer
  var screenEl, stageEl, device = 'pc', spec = null;
  function renderNode(n, parent){
    var el = document.createElement(/Button$/.test(n.class) ? 'button' : 'div');
    el.className = 'gn'; el.dataset.name = n.name;
    var flow = parent && (parent.list || parent.grid);
    if (flow) el.classList.add('flow');
    var st = el.style;
    var size = n.size || [0, 100, 0, 100];
    if (!(parent && parent.grid)) { st.width = calc(size[0], size[1]); st.height = calc(size[2], size[3]); }
    if (!flow) {
      var pos = n.pos || [0, 0, 0, 0], an = n.anchor || [0, 0];
      st.left = calc(pos[0], pos[1]); st.top = calc(pos[2], pos[3]);
      if (an[0] || an[1] || n.rotation) st.transform = 'translate(' + (-an[0] * 100) + '%,' + (-an[1] * 100) + '%)' + (n.rotation ? ' rotate(' + n.rotation + 'deg)' : '');
    }
    if (n.aspect) el.dataset.aspect = n.aspect;
    if (n.bgT < 1) {
      if (n.gradient) st.background = 'linear-gradient(' + (n.gradient.rotation + 90) + 'deg,' + n.gradient.colors.join(',') + ')';
      else st.background = n.bg;
      if (n.bgT > 0) st.backgroundColor = 'transparent', st.opacity = 1, el.style.setProperty('--a', 1 - n.bgT), st.background = mixAlpha(n, n.bgT);
    }
    if (n.corner) st.borderRadius = n.corner[0] ? (n.corner[0] * 100) + '%' : n.corner[1] + 'px';
    var textOnly = /^Text/.test(n.class) && n.bgT >= 1;
    if (n.stroke && n.stroke.transparency < 1) {
      var sc = rgba(n.stroke.color, 1 - n.stroke.transparency);
      if (textOnly) el.dataset.tstroke = sc + '|' + n.stroke.thickness;
      else st.boxShadow = '0 0 0 ' + n.stroke.thickness + 'px ' + sc;
    }
    if (n.padding) st.padding = n.padding.map(function(v){ return v + 'px'; }).join(' ');
    if (n.zIndex) st.zIndex = n.zIndex;
    if (!n.visible) st.display = 'none', el.dataset.hidden = '1';
    if (n.clip) el.classList.add('clip');
    if (n.class === 'ScrollingFrame') el.classList.add('scroll');
    if (n.list) {
      el.classList.add('layout-list');
      st.flexDirection = n.list.dir === 'Horizontal' ? 'row' : 'column'; st.gap = n.list.padding + 'px';
      var main = n.list.dir === 'Horizontal' ? n.list.hAlign : n.list.vAlign, cross = n.list.dir === 'Horizontal' ? n.list.vAlign : n.list.hAlign;
      var m = {Left: 'flex-start', Top: 'flex-start', Center: 'center', Right: 'flex-end', Bottom: 'flex-end'};
      st.justifyContent = m[main]; st.alignItems = m[cross];
    } else if (n.grid) {
      el.classList.add('layout-grid');
      var c = n.grid.cell, gp = n.grid.padding;
      st.gridTemplateColumns = 'repeat(auto-fill,' + calc(c[0], c[1]) + ')';
      st.gridAutoRows = c[2] ? calc(c[2], c[3]) : c[3] + 'px';
      st.columnGap = calc(gp[0], gp[1]); st.rowGap = gp[2] ? calc(gp[2], gp[3]) : gp[3] + 'px';
      st.alignContent = 'start';
    }
    if (/^Text/.test(n.class)) {
      var f = FONTS[n.font] || ['Montserrat', 700];
      st.fontFamily = '"' + f[0] + '",system-ui,sans-serif'; st.fontWeight = f[1]; st.color = n.textColor;
      var t = document.createElement('span'); t.className = 'gt';
      t.style.justifyContent = {Left: 'flex-start', Right: 'flex-end', Center: 'center'}[n.xAlign];
      t.style.alignItems = {Top: 'flex-start', Bottom: 'flex-end', Center: 'center'}[n.yAlign];
      t.style.textAlign = n.xAlign.toLowerCase();
      if (n.padding) t.style.padding = st.padding;
      if (n.class === 'TextBox') { var inp = document.createElement('input'); inp.placeholder = n.placeholder || n.text || ''; inp.style.fontSize = n.textSize + 'px'; el.appendChild(inp); }
      else { t.textContent = n.text; el.appendChild(t); }
      el.dataset.ts = n.textScaled ? 'scaled' : n.textSize;
    }
    if (/^Image/.test(n.class)) {
      var ic = document.createElement('span'); ic.className = 'gicon'; var r = iconRef(n.icon, n.iconWhite);
      if (r) { ic.className = 'gicon gimg'; ic.style.backgroundImage = 'url(/icons/bw_icons_' + r.sheet + '.png)'; ic.style.backgroundPosition = (-r.x/128*100/7*7) + '% 0'; ic.dataset.x = r.x; ic.dataset.y = r.y;
        if (r.white) { ic.style.webkitMaskImage = ic.style.maskImage = ic.style.backgroundImage; ic.style.backgroundImage = 'none'; ic.style.backgroundColor = n.iconColor; } }
      else ic.textContent = ICON_GLYPH[n.icon] || '▢';
      el.appendChild(ic); el.dataset.icon = '1';
    }
    if (n.studs) { var sd = document.createElement('span'); sd.className = 'gstud'; sd.style.backgroundSize = (n.studs*4) + 'px ' + (n.studs*4) + 'px'; el.insertBefore(sd, el.firstChild); }
    if (/Button$/.test(n.class)) el.classList.add('btn');
    (n.children || []).forEach(function(c){ el.appendChild(renderNode(c, n)); });
    return el;
  }
  function rgba(h, a){ var n = parseInt(h.slice(1), 16); return 'rgba(' + (n >> 16) + ',' + ((n >> 8) & 255) + ',' + (n & 255) + ',' + a + ')'; }
  function mixAlpha(n, t){
    if (n.gradient) return 'linear-gradient(' + (n.gradient.rotation + 90) + 'deg,' + n.gradient.colors.map(function(c){ return rgba(c, 1 - t); }).join(',') + ')';
    return rgba(n.bg, 1 - t);
  }
  // after layout: aspect ratio constraints, TextScaled, text strokes, icon sizes
  function finishLayout(root){
    $$('[data-aspect]', root).forEach(function(el){
      var a = Number(el.dataset.aspect), w = el.offsetWidth, h = el.offsetHeight;
      if (!w || !h) return;
      if (w / h > a) el.style.width = (h * a) + 'px'; else el.style.height = (w / a) + 'px';
    });
    $$('[data-ts]', root).forEach(function(el){
      var span = el.querySelector('.gt'); if (!span) return;
      if (el.dataset.ts === 'scaled') {
        var h = el.clientHeight, w = el.clientWidth, len = Math.max(1, span.textContent.length);
        span.style.fontSize = Math.max(6, Math.min(h * 0.82, w / (len * 0.62), 100)) + 'px';
      } else span.style.fontSize = el.dataset.ts + 'px';
      if (el.dataset.tstroke) { var p = el.dataset.tstroke.split('|'); span.style.webkitTextStroke = (p[1] * 0.9) + 'px ' + p[0]; span.style.paintOrder = 'stroke fill'; }
    });
    $$('[data-icon]', root).forEach(function(el){ var ic = el.querySelector('.gicon'); var s = Math.min(el.clientWidth, el.clientHeight); ic.style.fontSize = Math.max(8, s * 0.8) + 'px'; if (ic.dataset.x) { var z = s / 128, pos = (-ic.dataset.x*z) + 'px ' + (-ic.dataset.y*z) + 'px', sz = (1024*z) + 'px ' + (1024*z) + 'px'; ic.style.width = ic.style.height = s + 'px'; ic.style.backgroundPosition = ic.style.webkitMaskPosition = ic.style.maskPosition = pos; ic.style.backgroundSize = ic.style.webkitMaskSize = ic.style.maskSize = sz; } });
  }
  function fitScreen(){
    if (!screenEl || !stageEl) return;
    var d = DEVICES[device], k = stageEl.clientWidth / d[0];
    screenEl.style.width = d[0] + 'px'; screenEl.style.height = d[1] + 'px'; screenEl.style.transform = 'scale(' + k + ')';
  }
  function render(){
    if (!spec) return;
    stageEl.className = 'gstage dev-' + device;
    fitScreen();
    screenEl.innerHTML = '';
    try {
      [spec.root].concat(spec.extra).forEach(function(n){ screenEl.appendChild(renderNode(n, null)); });
      // tabs start on their first page
      spec.behaviors.forEach(function(b){ if (b.type === 'tabs') selectTab(b, 0); });
      requestAnimationFrame(function(){ finishLayout(screenEl); });
    } catch (e) { screenEl.innerHTML = '<div class="gerr">Preview error: ' + esc(e.message) + '</div>'; }
    $('#gInfo').textContent = spec.count + ' UI objects · ' + spec.behaviors.length + ' behaviours';
  }
  function byName(name){ return screenEl.querySelector('[data-name="' + name + '"]'); }
  function showEl(el, on){
    if (!el) return; el.style.display = on ? '' : 'none';
    if (on) {
      requestAnimationFrame(function(){ finishLayout(el); });
      if (spec && spec.behaviors.some(function(b){ return b.type === 'popin' && b.target === el.dataset.name; })) { el.classList.remove('g-pop'); void el.offsetWidth; el.classList.add('g-pop'); }
      runCountups(el);
    }
  }
  function fmtNum(n, b){
    if (b.short) { var u = [[1e12,'T'],[1e9,'B'],[1e6,'M'],[1e3,'K']]; for (var i = 0; i < u.length; i++) if (n >= u[i][0]) return b.prefix + (n / u[i][0]).toFixed(n / u[i][0] >= 100 ? 0 : 1).replace(/\.0$/, '') + u[i][1] + b.suffix; }
    return b.prefix + Math.round(n).toLocaleString('en-US') + b.suffix;
  }
  function runCountups(scope){
    if (!spec) return;
    spec.behaviors.forEach(function(b){
      if (b.type !== 'countup') return;
      var el = byName(b.label); if (!el || (scope && scope !== screenEl && !scope.contains(el))) return;
      var t = el.querySelector('.gt') || el; var t0 = performance.now(), dur = 1200, id = (el._cu = (el._cu || 0) + 1);
      (function step(now){ if (el._cu !== id) return; var k = Math.min(1, (now - t0) / dur), e = 1 - Math.pow(1 - k, 3); t.textContent = fmtNum(b.to * e, b); if (k < 1) requestAnimationFrame(step); })(t0);
    });
  }
  function applyAnims(){
    if (!spec) return;
    spec.behaviors.forEach(function(b){
      if (b.type === 'bounce') b.buttons.forEach(function(n){ var el = byName(n); if (el) el.classList.add('g-bounce'); });
      if (b.type === 'pulse') { var el = byName(b.target); if (el) el.classList.add('g-pulse'); }
      if (b.type === 'spin') { var el2 = byName(b.target); if (el2) { el2.classList.add('g-spin'); el2.style.animationDuration = (360 / b.speed) + 's'; } }
      if (b.type === 'popin') { var el3 = byName(b.target); if (el3 && el3.style.display !== 'none') el3.classList.add('g-pop'); }
    });
    runCountups(screenEl);
  }
  function selectTab(b, i){
    b.pages.forEach(function(p, k){ showEl(byName(p), k === i); });
    b.buttons.forEach(function(btn, k){ var el = byName(btn); if (el) el.style.filter = k === i ? 'brightness(1.35)' : ''; });
  }
  function onScreenClick(e){
    var btn = e.target.closest('.gn.btn'); if (!btn || !spec) return;
    var name = btn.dataset.name;
    spec.behaviors.forEach(function(b){
      if (b.type === 'toggle' && b.button === name) { var t = byName(b.target); showEl(t, t && t.style.display === 'none'); }
      if (b.type === 'close' && b.button === name) showEl(byName(b.target), false);
      if (b.type === 'tabs') { var i = b.buttons.indexOf(name); if (i >= 0) selectTab(b, i); }
    });
  }
  function applyHover(){
    applyAnims();
    spec.behaviors.forEach(function(b){ if (b.type === 'hover') b.buttons.forEach(function(n){ var el = byName(n); if (el) el.classList.add('grow'); }); });
  }

  // ---------------------------------------------------------------- Luau export
  function lstr(s){ return '"' + String(s).replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n') + '"'; }
  function u2(a){ return 'UDim2.new(' + a.join(', ') + ')'; }
  function toLuau(sp){
    var L = [], idx = 0;
    L.push('-- Made with Brickwright · https://brickwright.netlify.app');
    L.push('-- ' + sp.name + (sp.theme ? ' — ' + sp.theme.replace(/\n/g, ' ') : ''));
    L.push('-- Paste into the Studio command bar and press Enter. The ScreenGui appears in StarterGui.', '');
    L.push('local StarterGui = game:GetService("StarterGui")');
    L.push('local old = StarterGui:FindFirstChild(' + lstr(sp.name) + ')', 'if old then old:Destroy() end', '');
    L.push('local gui = Instance.new("ScreenGui")', 'gui.Name = ' + lstr(sp.name), 'gui.ResetOnSpawn = false', 'gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling', 'gui.IgnoreGuiInset = true', '');
    L.push('local function new(class, props, parent)', '\tlocal o = Instance.new(class)', '\tfor k, v in pairs(props) do o[k] = v end', '\to.Parent = parent', '\treturn o', 'end', '');
    var hasIcons = false, hasStuds = false;
    function emit(n, parentVar){
      var v = 'o' + (++idx), P = [];
      P.push('Name = ' + lstr(n.name));
      if (n.pos) P.push('Position = ' + u2(n.pos));
      if (n.size) P.push('Size = ' + u2(n.size));
      if (n.anchor) P.push('AnchorPoint = Vector2.new(' + n.anchor.join(', ') + ')');
      P.push('BackgroundColor3 = Color3.fromHex(' + lstr(n.gradient ? '#ffffff' : n.bg) + ')', 'BackgroundTransparency = ' + n.bgT, 'BorderSizePixel = 0');
      if (n.zIndex) P.push('ZIndex = ' + n.zIndex);
      if (n.rotation) P.push('Rotation = ' + n.rotation);
      if (!n.visible) P.push('Visible = false');
      if (n.clip || n.class === 'ScrollingFrame') P.push('ClipsDescendants = true');
      if (/^Text/.test(n.class)) {
        P.push('Text = ' + lstr(n.class === 'TextBox' ? '' : n.text), 'TextColor3 = Color3.fromHex(' + lstr(n.textColor) + ')', 'Font = Enum.Font.' + n.font,
          'TextSize = ' + n.textSize, 'TextScaled = ' + n.textScaled, 'TextWrapped = true', 'TextXAlignment = Enum.TextXAlignment.' + n.xAlign, 'TextYAlignment = Enum.TextYAlignment.' + n.yAlign);
        if (n.class === 'TextBox') P.push('PlaceholderText = ' + lstr(n.placeholder || n.text || ''), 'ClearTextOnFocus = false');
        if (/Button$/.test(n.class)) P.push('AutoButtonColor = true');
      }
      if (/^Image/.test(n.class)) {
        hasIcons = true;
        var r = iconRef(n.icon, n.iconWhite);
        if (r) P.push('Image = "rbxassetid://' + r.id + '"', 'ImageRectOffset = Vector2.new(' + r.x + ', ' + r.y + ')', 'ImageRectSize = Vector2.new(128, 128)', 'ImageColor3 = Color3.fromHex(' + lstr(r.white ? n.iconColor : '#ffffff') + ')', 'ScaleType = Enum.ScaleType.Fit');
        else P.push('Image = ICONS[' + lstr(n.icon) + '] or ""', 'ImageColor3 = Color3.fromHex(' + lstr(n.iconColor) + ')', 'ScaleType = Enum.ScaleType.Fit');
      }
      if (n.class === 'ScrollingFrame') {
        P.push('ScrollBarThickness = 6', 'ScrollBarImageColor3 = Color3.fromHex("#ffffff")', 'ScrollBarImageTransparency = 0.6', 'ScrollingDirection = Enum.ScrollingDirection.Y');
        if (n.canvas) P.push('CanvasSize = UDim2.new(0, 0, ' + n.canvas[0] + ', ' + n.canvas[1] + ')');
        else P.push('CanvasSize = UDim2.new(0, 0, 0, 0)', 'AutomaticCanvasSize = Enum.AutomaticSize.Y');
      }
      L.push('local ' + v + ' = new(' + lstr(n.class) + ', {' + P.join(', ') + '}, ' + parentVar + ')');
      if (n.corner) L.push('new("UICorner", {CornerRadius = UDim.new(' + n.corner[0] + ', ' + n.corner[1] + ')}, ' + v + ')');
      if (n.stroke) L.push('new("UIStroke", {Color = Color3.fromHex(' + lstr(n.stroke.color) + '), Thickness = ' + n.stroke.thickness + ', Transparency = ' + n.stroke.transparency +
        (/^Text/.test(n.class) && n.bgT >= 1 ? '' : ', ApplyStrokeMode = Enum.ApplyStrokeMode.Border') + '}, ' + v + ')');
      if (n.gradient) {
        var cs = n.gradient.colors, keys = cs.map(function(c, i){ return 'ColorSequenceKeypoint.new(' + (Math.round(i / (cs.length - 1) * 1000) / 1000) + ', Color3.fromHex(' + lstr(c) + '))'; });
        L.push('new("UIGradient", {Color = ColorSequence.new({' + keys.join(', ') + '}), Rotation = ' + n.gradient.rotation + '}, ' + v + ')');
      }
      if (n.padding) L.push('new("UIPadding", {PaddingTop = UDim.new(0, ' + n.padding[0] + '), PaddingRight = UDim.new(0, ' + n.padding[1] + '), PaddingBottom = UDim.new(0, ' + n.padding[2] + '), PaddingLeft = UDim.new(0, ' + n.padding[3] + ')}, ' + v + ')');
      if (n.list) L.push('new("UIListLayout", {FillDirection = Enum.FillDirection.' + n.list.dir + ', Padding = UDim.new(0, ' + n.list.padding + '), HorizontalAlignment = Enum.HorizontalAlignment.' + n.list.hAlign +
        ', VerticalAlignment = Enum.VerticalAlignment.' + n.list.vAlign + ', SortOrder = Enum.SortOrder.LayoutOrder}, ' + v + ')');
      if (n.grid) L.push('new("UIGridLayout", {CellSize = ' + u2(n.grid.cell) + ', CellPadding = ' + u2(n.grid.padding) + ', SortOrder = Enum.SortOrder.LayoutOrder}, ' + v + ')');
      if (n.studs) { hasStuds = true; L.push('do local s = new("ImageLabel", {Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = STUD_IMAGE, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(' + (n.studs*4) + ', ' + (n.studs*4) + '), ImageTransparency = 0.15, ZIndex = ' + ((n.zIndex || 1) - 1) + '}, ' + v + ')' + (n.corner ? ' new("UICorner", {CornerRadius = UDim.new(' + n.corner[0] + ', ' + n.corner[1] + ')}, s)' : '') + ' end'); }
      if (n.aspect) L.push('new("UIAspectRatioConstraint", {AspectRatio = ' + n.aspect + '}, ' + v + ')');
      (n.children || []).forEach(function(c, i){ var cv = emit(c, v); if (n.list || n.grid) L.push(cv + '.LayoutOrder = ' + (i + 1)); });
      return v;
    }
    var start = L.length;
    [sp.root].concat(sp.extra).forEach(function(n){ emit(n, 'gui'); L.push(''); });
    if (hasStuds) L.splice(start, 0, '-- Stud texture (swap for rbxassetid://110613161164843 for the universal studs)', 'local STUD_IMAGE = ' + lstr(STUD_ID), '');
    if (hasIcons) {
      var used = {}; [sp.root].concat(sp.extra).forEach(function(r){ walk(r, function(n){ if (n.icon && !iconRef(n.icon)) used[n.icon] = 1; }); });
      var lines = ['-- Icons: paste your image IDs here (rbxassetid://...) — empty ones stay blank', 'local ICONS = {'];
      Object.keys(used).sort().forEach(function(k){ lines.push('\t[' + lstr(k) + '] = ' + lstr(ICON_IDS[k] || '') + ','); });
      lines.push('}', '');
      L.splice.apply(L, [start, 0].concat(lines));
    }
    if (sp.behaviors.length) {
      var S = [];
      S.push('local gui = script.Parent', 'local function find(n) return gui:FindFirstChild(n, true) end', 'local TweenService = game:GetService("TweenService")');
      sp.behaviors.forEach(function(b){
        if (b.type === 'toggle') S.push('do local b, t = find(' + lstr(b.button) + '), find(' + lstr(b.target) + ')', '\tif b and t then b.Activated:Connect(function() t.Visible = not t.Visible end) end end');
        if (b.type === 'close') S.push('do local b, t = find(' + lstr(b.button) + '), find(' + lstr(b.target) + ')', '\tif b and t then b.Activated:Connect(function() t.Visible = false end) end end');
        if (b.type === 'tabs') {
          S.push('do', '\tlocal buttons = {' + b.buttons.map(function(x){ return 'find(' + lstr(x) + ')'; }).join(', ') + '}',
            '\tlocal pages = {' + b.pages.map(function(x){ return 'find(' + lstr(x) + ')'; }).join(', ') + '}',
            '\tlocal base = {}', '\tfor i, btn in ipairs(buttons) do base[i] = btn.BackgroundColor3 end',
            '\tlocal function select(i)', '\t\tfor k, p in ipairs(pages) do p.Visible = (k == i) end',
            '\t\tfor k, btn in ipairs(buttons) do btn.BackgroundColor3 = (k == i) and base[k]:Lerp(Color3.new(1, 1, 1), 0.25) or base[k] end', '\tend',
            '\tfor i, btn in ipairs(buttons) do btn.Activated:Connect(function() select(i) end) end', '\tselect(1)', 'end');
        }
        if (b.type === 'popin') S.push('do local t = find(' + lstr(b.target) + ')', '\tif t then', '\t\tlocal sc = t:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", t)',
          '\t\tlocal function pop() if t.Visible then sc.Scale = 0.6 TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play() end end',
          '\t\tt:GetPropertyChangedSignal("Visible"):Connect(pop) pop()', '\tend', 'end');
        if (b.type === 'bounce') S.push('for _, n in ipairs({' + b.buttons.map(lstr).join(', ') + '}) do', '\tlocal b = find(n)', '\tif b then',
          '\t\tlocal sc = b:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", b)',
          '\t\tb.MouseButton1Down:Connect(function() TweenService:Create(sc, TweenInfo.new(0.08), {Scale = 0.9}):Play() end)',
          '\t\tb.MouseButton1Up:Connect(function() TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play() end)',
          '\t\tb.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.15), {Scale = 1}):Play() end)', '\tend', 'end');
        if (b.type === 'pulse') S.push('do local t = find(' + lstr(b.target) + ')', '\tif t then', '\t\tlocal sc = t:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", t)',
          '\t\tTweenService:Create(sc, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.06}):Play()', '\tend', 'end');
        if (b.type === 'spin') S.push('do local t = find(' + lstr(b.target) + ')', '\tif t then task.spawn(function() while t.Parent do t.Rotation = (t.Rotation + ' + b.speed + ' * task.wait()) % 360 end end) end', 'end');
        if (b.type === 'countup') S.push('do local t = find(' + lstr(b.label) + ')', '\tif t then', '\t\tlocal target, prefix, suffix, short = ' + b.to + ', ' + lstr(b.prefix) + ', ' + lstr(b.suffix) + ', ' + b.short,
          '\t\tlocal function fmt(n)', '\t\t\tif short then for _, u in ipairs({{1e12, "T"}, {1e9, "B"}, {1e6, "M"}, {1e3, "K"}}) do if n >= u[1] then return prefix .. string.format(n / u[1] >= 100 and "%.0f" or "%.1f", n / u[1]):gsub("%.0$", "") .. u[2] .. suffix end end end',
          '\t\t\tlocal s = tostring(math.floor(n + 0.5)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")', '\t\t\treturn prefix .. s .. suffix', '\t\tend',
          '\t\tlocal v = Instance.new("NumberValue") v.Changed:Connect(function(n) t.Text = fmt(n) end)', '\t\tt.Text = fmt(0)',
          '\t\tTweenService:Create(v, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = target}):Play()', '\tend', 'end');
        if (b.type === 'hover') S.push('for _, n in ipairs({' + b.buttons.map(lstr).join(', ') + '}) do', '\tlocal b = find(n)', '\tif b then',
          '\t\tlocal s = b.Size', '\t\tlocal big = UDim2.new(s.X.Scale * 1.05, s.X.Offset * 1.05, s.Y.Scale * 1.05, s.Y.Offset * 1.05)',
          '\t\tb.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {Size = big}):Play() end)',
          '\t\tb.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {Size = s}):Play() end)', '\tend', 'end');
      });
      L.push('-- Button behaviours and animations', 'local ls = Instance.new("LocalScript")', 'ls.Name = "GuiBehaviours"', 'ls.Source = ' + '[==[\n' + S.join('\n') + '\n]==]', 'ls.Parent = gui', '');
    }
    L.push('gui.Parent = StarterGui', 'pcall(function() game:GetService("Selection"):Set({gui}) end)', 'print("' + sp.name + ' added to StarterGui — made with Brickwright")');
    return L.join('\n');
  }

  // ---------------------------------------------------------------- page logic
  var current = {spec: null, raw: '', notes: '', brief: ''}, busy = false, job = null, refImage = null;
  function setStatus(t, cls){ var s = $('#gStatus'); s.className = 'status' + (cls ? ' ' + cls : ''); $('#gStatusText').textContent = t; }
  function show(sp, notes){
    spec = sp; current.spec = sp; render(); applyHover();
    $('#gCode').textContent = toLuau(sp);
    $('#gNotes').textContent = notes || '';
  }
  function extractJSON(text){
    var m = text.match(/```(?:json)?\s*([\s\S]*?)```/i), body = m ? m[1] : text;
    var a = body.indexOf('{'), z = body.lastIndexOf('}');
    if (a < 0 || z < a) throw new Error('The AI didn’t return a GUI — try again.');
    return JSON.parse(body.slice(a, z + 1));
  }
  function notesOf(text){ var m = text.match(/NOTES:\s*([\s\S]*)$/i); return m ? m[1].trim() : ''; }
  function promptFor(brief){
    var style = STYLES[$('#gStyle').selectedIndex] || STYLES[0];
    return 'Design this Roblox GUI: "' + brief + '"\n\nStyle: ' + style[1] + '.\nAccent colour: ' + $('#gAccent').value +
      '\n' + ($('#gBehave').checked ? 'Add behaviors for every tab group, open button and close button.' : 'No behaviors (leave "behaviors" empty).') +
      ($('#gAnim').checked ? '\nAdd ANIMATIONS: popin on every window that opens, bounce on the main buttons, countup on currency/number labels, and pulse on the single most important button.' : '') +
      (refImage ? '\nA screenshot of a GUI is attached — recreate its layout, colours, proportions and style as closely as possible with real Roblox UI (use the closest icons from the ICON LIST).' : '') +
      '\nIt must look great on PC and phones (use Scale + an aspect constraint on main windows). Answer with the JSON block, then NOTES.';
  }
  async function runJob(messages, revise){
    var j = await B.api('/api/generate', {method: 'POST', body: {prompt: messages, kind: 'gui', revise: !!revise}});
    job = j.jobId; B.refreshMe().then(renderCost);
    var all = '', from = 0, t0 = Date.now();
    for (;;) {
      await new Promise(function(r){ setTimeout(r, 900); });
      var st = await B.api('/api/job?id=' + encodeURIComponent(j.jobId) + '&from=' + from);
      if (st.text) { all += st.text; from = st.length; }
      setStatus((revise ? 'Revising… ' : 'Designing your GUI… ') + Math.round((Date.now() - t0) / 1000) + 's' + (st.thinking && !all ? ' · thinking' : ''));
      if (st.status === 'done') { job = null; B.refreshMe().then(renderCost); return B.stripThink(all); }
      if (st.status === 'cancelled') { job = null; throw {message: 'Stopped — your credits were refunded.'}; }
      if (st.status === 'error') { job = null; B.refreshMe().then(renderCost); throw {message: (st.error || 'Failed.') + (st.refunded ? ' Credits refunded.' : '')}; }
    }
  }
  function setBusy(on){ busy = on; $('#gGo').disabled = on; $('#gRevise').disabled = on; $('#gStop').hidden = !on; }
  async function generate(){
    if (busy) return;
    var brief = $('#gBrief').value.trim();
    if (!brief && refImage) brief = 'Recreate the GUI in the attached screenshot';
    if (!brief) { setStatus('Describe the GUI you want first (or add a screenshot).', 'err'); $('#gBrief').focus(); return; }
    if (!B.session()) { setStatus('Sign in to generate GUIs.', 'err'); B.openLogin(); return; }
    setBusy(true);
    try {
      var msgs = [{role: 'user', content: refImage ? [{type: 'text', text: promptFor(brief)}, {type: 'image_url', image_url: {url: refImage}}] : promptFor(brief)}];
      var text = await runJob(msgs, false);
      var sp = sanitize(extractJSON(text));
      current = {spec: sp, raw: text, notes: notesOf(text), brief: brief, msgs: msgs};
      show(sp, current.notes); saveLocal(); saveCloud(); setStatus('Done — ' + sp.count + ' UI objects. Click the buttons in the preview to try it.', 'ok');
    } catch (e) { setStatus(e.message || 'Something went wrong — try again.', 'err'); }
    setBusy(false);
  }
  async function revise(){
    if (busy) return;
    var ask = $('#gReviseIn').value.trim();
    if (!ask) return;
    if (!current.raw) { setStatus('Generate a GUI first, then ask for changes.', 'err'); return; }
    if (!B.session()) { B.openLogin(); return; }
    setBusy(true);
    try {
      var msgs = (current.msgs || [{role: 'user', content: promptFor(current.brief)}]).slice(0, 1).concat([
        {role: 'assistant', content: '```json\n' + JSON.stringify(stripCount(current.spec)) + '\n```'},
        {role: 'user', content: 'Change it: ' + ask + '\nKeep everything else the same. Reply with the COMPLETE updated JSON block, then NOTES.'}]);
      var text = await runJob(msgs, true);
      var sp = sanitize(extractJSON(text));
      current = {spec: sp, raw: text, notes: notesOf(text), brief: current.brief, msgs: current.msgs};
      show(sp, current.notes); saveLocal(); saveCloud(); $('#gReviseIn').value = ''; setStatus('Updated — ' + sp.count + ' UI objects.', 'ok');
    } catch (e) { setStatus(e.message || 'Something went wrong — try again.', 'err'); }
    setBusy(false);
  }
  function stripCount(sp){ var c = JSON.parse(JSON.stringify(sp)); delete c.count; return c; }
  function renderCost(){
    var me = B.getMe(), c = (me && me.costs && me.costs.gui) || 40, r = (me && me.costs && me.costs.gui_revise) || 15;
    $('#gGo').textContent = 'Generate GUI · ' + c + ' credits';
    $('#gCost').textContent = 'Revisions cost ' + r + ' credits' + (me && me.signedIn ? '' : ' · sign in to get free credits every month');
  }
  // history (this browser)
  var HKEY = 'bw_guis';
  function loadLocal(){ try { return JSON.parse(localStorage.getItem(HKEY) || '[]'); } catch (e) { return []; } }
  function saveLocal(){
    try {
      var list = loadLocal().filter(function(x){ return x.brief !== current.brief || x.t > Date.now() - 1; });
      list.unshift({t: Date.now(), brief: current.brief, spec: stripCount(current.spec), notes: current.notes, msgs: current.msgs, cloud: B.session() ? 1 : 0});
      localStorage.setItem(HKEY, JSON.stringify(list.slice(0, 20)));
    } catch (e) {}
    renderHistory();
  }
  function saveCloud(){
    if (!B.session() || !current.spec) return;
    B.api('/api/plugin', {method: 'POST', body: {action: 'saveGui', name: current.spec.name, brief: current.brief, script: toLuau(current.spec)}}).catch(function(){});
  }
  // screenshot → GUI
  function pickImage(file){
    if (!file || !/^image\//.test(file.type)) return;
    var img = new Image(), url = URL.createObjectURL(file);
    img.onload = function(){
      var k = Math.min(1, 1280 / Math.max(img.width, img.height)), c = document.createElement('canvas');
      c.width = Math.round(img.width * k); c.height = Math.round(img.height * k); c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
      var q = 0.85, out = c.toDataURL('image/jpeg', q);
      while (out.length > 700000 && q > 0.4) { q -= 0.15; out = c.toDataURL('image/jpeg', q); }
      refImage = out; URL.revokeObjectURL(url);
      $('#gImgThumb').src = out; $('#gImgBox').hidden = false; $('#gImgPick').hidden = true;
    };
    img.src = url;
  }
  function clearImage(){ refImage = null; $('#gImgBox').hidden = true; $('#gImgPick').hidden = false; $('#gImgIn').value = ''; }
  // gallery
  var galNext = 0;
  async function share(){
    if (!current.spec) return;
    if (!B.session()) { B.openLogin(); return; }
    try { await B.api('/api/guis', {method: 'POST', body: {spec: stripCount(current.spec), brief: current.brief, style: STYLES[$('#gStyle').selectedIndex][0]}}); B.toast('Shared to the GUI gallery!'); loadGallery(true); }
    catch (e) { B.toast(e.message || 'Could not share.', true); }
  }
  function miniPreview(sp, box){
    // renders a scaled-down static preview into box
    try {
      var s2 = sanitize(sp), scr = document.createElement('div'); scr.className = 'gscreen gmini'; scr.style.width = '1280px'; scr.style.height = '720px';
      box.appendChild(scr);
      [s2.root].concat(s2.extra).forEach(function(n){ scr.appendChild(renderNode(n, null)); });
      s2.behaviors.forEach(function(b){ if (b.type === 'tabs') b.pages.forEach(function(p, k){ var el = scr.querySelector('[data-name="' + p + '"]'); if (el) el.style.display = k ? 'none' : ''; }); });
      var fit = function(){ var k = box.clientWidth / 1280; scr.style.transform = 'scale(' + k + ')'; };
      fit(); requestAnimationFrame(function(){ fit(); finishLayout(scr); });
    } catch (e) {}
  }
  async function loadGallery(reset){
    var el = $('#gGallery'); if (!el) return;
    if (reset) { galNext = 0; el.innerHTML = ''; }
    try {
      var j = await B.api('/api/guis?offset=' + galNext);
      if (!j.items.length && !galNext) el.innerHTML = '<p class="muted small">No shared GUIs yet — generate one and press Share.</p>';
      j.items.forEach(function(it){
        var card = document.createElement('div'); card.className = 'card gcard';
        card.innerHTML = '<div class="gthumb"></div><b>' + esc(it.name) + '</b><span class="muted small">' + esc((it.style ? it.style + ' · ' : '') + (it.brief || '').slice(0, 80)) + '</span>' +
          '<div class="gcard-actions"><button class="btn btn-sm btn-primary" data-act="remix">Remix</button>' + (it.mine ? '<button class="btn btn-sm btn-ghost" data-act="del">Delete</button>' : '') + '</div>';
        el.appendChild(card);
        miniPreview(it.spec, card.querySelector('.gthumb'));
        card.querySelector('[data-act="remix"]').onclick = function(){
          var sp = sanitize(it.spec); current = {spec: sp, raw: 'gallery', notes: '', brief: it.brief || it.name, msgs: null};
          $('#gBrief').value = it.brief || ''; show(sp, 'Remixing "' + it.name + '" from the gallery — ask for changes below (15 credits each).'); setStatus('Loaded from the gallery. Use Revise to make it yours.', 'ok'); window.scrollTo({top: 0, behavior: 'smooth'});
        };
        var d = card.querySelector('[data-act="del"]'); if (d) d.onclick = async function(){ try { await B.api('/api/guis?id=' + encodeURIComponent(it.id), {method: 'DELETE'}); card.remove(); } catch (e) { B.toast(e.message, true); } };
      });
      galNext = j.next; $('#gGalMore').hidden = j.next == null;
    } catch (e) { el.innerHTML = '<p class="muted small">Could not load the gallery.</p>'; }
  }
  function renderHistory(){
    var list = loadLocal(), el = $('#gHistory');
    if (!list.length) { el.innerHTML = '<p class="muted small">Your GUIs will appear here.</p>'; return; }
    el.innerHTML = list.map(function(x, i){
      return '<button class="card ghist" data-i="' + i + '"><b>' + esc((x.spec && x.spec.name) || 'GUI') + '</b><span class="muted small">' + esc(x.brief.slice(0, 90)) + '</span></button>';
    }).join('');
    $$('.ghist', el).forEach(function(b){ b.onclick = function(){
      var x = loadLocal()[Number(b.dataset.i)]; if (!x) return;
      try { var sp = sanitize(x.spec); current = {spec: sp, raw: 'saved', notes: x.notes, brief: x.brief, msgs: x.msgs}; $('#gBrief').value = x.brief; show(sp, x.notes); setStatus('Loaded from your GUIs.', 'ok'); window.scrollTo({top: 0, behavior: 'smooth'}); } catch (e) {}
    }; });
  }
  function download(){
    var blob = new Blob([$('#gCode').textContent], {type: 'text/plain'}), a = document.createElement('a');
    a.href = URL.createObjectURL(blob); a.download = ((spec && spec.name) || 'gui') + '.lua'; a.click(); setTimeout(function(){ URL.revokeObjectURL(a.href); }, 2000);
  }

  function init(){
    B = window.BW; screenEl = $('#gScreen'); stageEl = $('#gStage');
    $('#gStyle').innerHTML = STYLES.map(function(s){ return '<option>' + s[0] + '</option>'; }).join('');
    $('#gChips').innerHTML = CHIPS.map(function(c, i){ return '<button class="chip" data-i="' + i + '">' + c[0] + '</button>'; }).join('');
    $$('#gChips .chip').forEach(function(c){ c.onclick = function(){ $('#gBrief').value = CHIPS[Number(c.dataset.i)][1]; $('#gBrief').focus(); }; });
    $$('[data-gtab]').forEach(function(t){ t.onclick = function(){
      $$('[data-gtab]').forEach(function(x){ x.classList.toggle('active', x === t); });
      $$('[data-gpane]').forEach(function(p){ p.hidden = p.dataset.gpane !== t.dataset.gtab; });
      if (t.dataset.gtab === 'preview') render(), applyHover();
    }; });
    $$('#gDevice button').forEach(function(b){ b.onclick = function(){ $$('#gDevice button').forEach(function(x){ x.classList.toggle('active', x === b); }); device = b.dataset.dev; render(); applyHover(); }; });
    screenEl.addEventListener('click', onScreenClick);
    window.addEventListener('resize', function(){ fitScreen(); });
    $('#gGo').onclick = generate; $('#gRevise').onclick = revise;
    $('#gReviseIn').onkeydown = function(e){ if (e.key === 'Enter') revise(); };
    $('#gBrief').onkeydown = function(e){ if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) generate(); };
    $('#gStop').onclick = function(){ if (job) B.api('/api/job?id=' + encodeURIComponent(job), {method: 'POST', body: {cancel: true}}).catch(function(){}); setStatus('Stopping…'); };
    $('#gCopy').onclick = function(){ navigator.clipboard.writeText($('#gCode').textContent).then(function(){ B.toast('Script copied — paste it into the Studio command bar.'); }); };
    $('#gDownload').onclick = download;
    renderCost(); document.addEventListener('bw:me', renderCost);
    renderHistory();
    $('#gImgPick').onclick = function(){ $('#gImgIn').click(); };
    $('#gImgIn').onchange = function(){ pickImage(this.files[0]); };
    $('#gImgClear').onclick = clearImage;
    document.addEventListener('paste', function(e){ var f = [].slice.call((e.clipboardData && e.clipboardData.files) || [])[0]; if (f && /^image\//.test(f.type)) pickImage(f); });
    $('#gShare').onclick = share;
    $('#gGalMore').onclick = function(){ loadGallery(false); };
    loadGallery(true);
    // upload GUIs made before cloud saving, so the Studio plugin can see them
    setTimeout(async function syncLocal(){
      if (!B.session()) return;
      var list = loadLocal(), changed = false;
      for (var i = list.length - 1; i >= 0; i--) {
        var x = list[i]; if (x.cloud || !x.spec) continue;
        try { var sp = sanitize(x.spec); await B.api('/api/plugin', {method: 'POST', body: {action: 'saveGui', name: sp.name, brief: x.brief, script: toLuau(sp)}}); x.cloud = 1; changed = true; } catch (e) { break; }
      }
      if (changed) try { localStorage.setItem(HKEY, JSON.stringify(list)); } catch (e) {}
    }, 1500);
    show(sanitize(EXAMPLE), 'A built-in example. Describe your own GUI and press Generate.');
  }
  // exposed for tests
  window.BWGui = {sanitize: sanitize, toLuau: toLuau, EXAMPLE: EXAMPLE};
  if (window.BW) init(); else document.addEventListener('bw:ready', init);
})();
