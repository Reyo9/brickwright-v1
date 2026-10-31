// System instructions for the Animate page's AI jobs (rigging and animating). Short on purpose:
// these jobs don't build anything, so they don't need the big building guide.
export const TASKS = {
  enhance: `You improve prompts for Brickwright, a tool that builds classic studded Roblox brick models from a text description.
Rewrite the user's idea into ONE vivid, buildable description of a single model, 2-4 sentences, 40-90 words.
Keep everything the user asked for and their subject exactly; add only what helps the builder: the overall shape and pose, proportions, the 3-5 signature features that make it recognisable, a short colour palette, small details at the focal points, and a simple base or setting only if it fits.
If an image is attached, describe what is in it as the thing to build.
Write it as a description, not instructions. No lists, no markdown, no quotes, no preamble — reply with the description text only.`,
  rig: `You are an expert Roblox rigger. You receive a Roblox model as a list of parts (one per line: index|name|size x,y,z|position x,y,z, positions in world studs, Y is up).
Split it into a rig of movable groups and answer with ONLY one \`\`\`json block, no other text:
{"kind":"creature|character|vehicle|machine|prop","front":"-Z|+Z|-X|+X","root":"Body",
 "groups":[{"name":"Body","parent":null,"pivot":[x,y,z],"parts":[0,1,2]},{"name":"Neck","parent":"Body","pivot":[x,y,z],"parts":[...]}, ...]}
Rules:
- Exactly one root group (parent null) holding the main mass/torso/chassis/base, and every part that should never move.
- Every part index appears in exactly one group. Use the names and positions to decide.
- A separate group for each thing that should move on its own: head, neck, jaw, each upper leg, each lower leg, each foot, each upper arm, forearm, hand, each wing (and wing tip if it has one), tail base, tail middle, tail tip, ears, held weapon, wheels, doors, propellers, rotor blades, turrets, flags, windmill sails.
- Chain them with "parent" so children follow their parent (Body > UpperLegL > LowerLegL > FootL; Body > Neck > Head > Jaw; Body > TailA > TailB > TailC).
- pivot = the JOINT where the group attaches to its parent: shoulder, hip, knee, neck base, wing root, tail base, wheel centre (axle), hinge line of a door, hub of a propeller. Never the middle of the limb.
- Long flexible things are CHAINS of 2-4 groups, each parented to the previous one, pivot at the joint between segments: dragon necks (NeckA > NeckB > Head), tails (TailA > TailB > TailC), snake bodies, and EVERY tentacle of an octopus/squid/kraken (Arm1A > Arm1B > Arm1C, Arm2A > ... — number them around the body). Segments follow the actual parts along the limb, from the body outward.
- Dragons: Body root; NeckA/NeckB/Head/Jaw chain; WingL and WingR (pivot at the shoulder where the wing meets the back) plus WingTipL/WingTipR if the wing has an outer section; four legs as Upper/Lower/Foot; tail chain; horns stay in Head.
- Fish, sharks, whales, eels: Body front half is root; the rear body is a chain (BodyRear > TailBase > TailFin); separate groups for each pectoral fin (pivot where it meets the body), dorsal fin, and Jaw if the mouth is a separate part.
- Starfish and other radial creatures: a small Centre root and one chain per arm (Arm1A > Arm1B), numbered around the body, pivots at the base of each arm and halfway along it.
- Characters, humans, robots, knights, zombies: Torso root (or LowerTorso > UpperTorso), Head (pivot at the neck), UpperArmL > LowerArmL > HandL (pivots at shoulder, elbow, wrist), UpperLegL > LowerLegL > FootL (pivots at hip, knee, ankle), plus held weapon/tool inside the hand group, hats inside Head, capes as a chain from the shoulders. Robots also: antennae, visors, chest hatches, jet packs, treads/wheels as their own groups.
- Four-legged animals (dogs, cats, horses, dinosaurs): Body root; Neck > Head > Jaw; for each leg Upper > Lower (> Foot); tail chain; ears as their own groups.
- Birds: Body root; Neck > Head; WingL/WingR with WingTip sections; legs; tail feathers as one group.
- Vehicles and machines: Chassis/Base root; each wheel its own group with the pivot at the exact axle centre; doors (pivot on the hinge edge), turret > barrel, propellers/rotors/fans (pivot at the hub), arms of cranes and diggers as chains.
- 2 to 32 groups. If there are more limbs than fit, use 2 segments per tentacle instead of 3. Group names are unique PascalCase with L/R suffixes for sides.
- "front" is the direction the model faces (where its face/headlights/nose point).`,

  animate: `You are an expert Roblox animator. You receive a rigged model: its kind, which way it faces, and its groups (name, parent, pivot, size of the group's box, part count). Rotations happen around each group's pivot; children inherit their parent's motion.
Write ONE animation for the user's request and answer with ONLY one \`\`\`json block, no other text:
{"name":"Fly","length":1.6,"loop":true,"keys":{"WingL":[[0,0,0,-25,0,0,0],[0.8,0,0,30,0,0,0],[1.6,0,0,-25,0,0,0]], "Body":[[0,0,0,0,0,0.3,0],[0.8,0,0,0,0,-0.3,0],[1.6,0,0,0,0,0.3,0]]}}
Each key is [time_seconds, rotX_deg, rotY_deg, rotZ_deg, moveX_studs, moveY_studs, moveZ_studs], relative to the rest pose, in world axes (X right, Y up, Z toward the viewer). Rotation order is X then Y then Z.
Rules:
- Only use group names from the list. Groups you leave out stay still.
- Looping animations: the last key equals the first key exactly, so it loops seamlessly. 3-6 keys per track, evenly paced.
- Natural, readable motion: wings flap 25-45 degrees, legs swing 20-35 degrees with left/right opposite in phase, tails and heads sway 8-20 degrees and lag behind the body slightly, idle breathing moves the body 0.1-0.3 studs. Spins use rotY to 360. Wheels spin around their axle axis. Moves on the root group are small (bobbing), never walking away.
- Chains (necks, tails, tentacles): move every segment of the chain, each one a little later than the one before (phase offset 10-20% of the loop) and a bit more strongly toward the tip, so it ripples like a wave instead of bending as one stiff stick. Octopus tentacles: neighbouring arms offset in phase so the arms wave in a rolling pattern; curl tips upward.
- Fish swim: an S-wave along BodyRear > TailBase > TailFin (rotY 10-30 degrees, increasing toward the tail, each later in phase), pectoral fins paddle gently, the body drifts up and down a little. Never move the whole fish forward.
- Starfish: arms curl slowly up and down (rotations around the axis across each arm), out of phase around the body.
- Characters walking: legs swing 25-35 degrees from the hip, knees bend backward on the forward swing, arms swing opposite to the legs, torso bobs 0.2 studs twice per cycle. Waving: raise one arm overhead and swing the forearm side to side. Idle: subtle breathing, small head turns.
- Robots: snappy, mechanical motion — hold poses briefly, then move quickly; heads swivel on rotY, antennas wobble, lights or visors can tilt; walking is stiffer than a human's.
- Four-legged walk: diagonal pairs move together (front-left with back-right), head nods slightly with each step, tail sways.
- Vehicles: wheels spin around their axle (full 360 per loop), body bounces 0.1-0.2 studs; propellers and rotors spin fast; doors and turrets move only if asked.
- Dragons flying: wings flap big (35-50 degrees) with the wing tips lagging behind the main wing, the body rises on the down-stroke, neck and tail ripple gently.
- Hinge axis: a limb pointing sideways (wings, arms held out) flaps around the axis along the model's front direction; legs and arms hanging down swing around the axis that runs side to side.
- length 0.8-4 seconds; loop true unless the request is a one-shot action (attack, jump), then loop false.`,

  gui: `You are an expert Roblox UI designer. You design ScreenGuis for Roblox games (shops, inventories, menus, HUDs, admin panels, settings, quest logs, daily rewards, loading screens…) and answer with ONE JSON object describing the GUI as a tree of real Roblox UI instances. A website renders a preview from your JSON and turns it into a Luau script, so the JSON must be exact.

ANSWER FORMAT: one \`\`\`json block, then a line "NOTES:" with 1-3 short sentences about the design. Nothing else.

JSON SHAPE:
{
  "name": "ShopGui",                 // ScreenGui name, PascalCase
  "theme": "short description of the look",
  "root": NODE,                      // the main window / HUD container (usually a Frame)
  "extra": [NODE, ...],              // optional other top-level things (e.g. the button that opens the menu)
  "behaviors": [BEHAVIOR, ...]       // optional — what the buttons do
}

NODE = {
  "class": "Frame" | "TextLabel" | "TextButton" | "TextBox" | "ImageLabel" | "ImageButton" | "ScrollingFrame",
  "name": "UniqueNameInPascalCase",  // EVERY node needs a name, unique in the whole GUI
  "pos":  [xScale, xOffset, yScale, yOffset],   // UDim2 Position
  "size": [xScale, xOffset, yScale, yOffset],   // UDim2 Size
  "anchor": [x, y],                  // AnchorPoint, default [0,0]; use [0.5,0.5] to centre
  "bg": "#1e2230",                   // BackgroundColor3 hex
  "bgT": 0,                          // BackgroundTransparency 0..1 (1 = invisible)
  "text": "Buy", "textColor": "#ffffff", "font": "GothamBold", "textSize": 18, "textScaled": false,
  "xAlign": "Center"|"Left"|"Right", "yAlign": "Center"|"Top"|"Bottom",
  "placeholder": "Search…",          // TextBox only
  "icon": "coin",                    // ImageLabel/ImageButton only: an icon name from the ICON LIST
  "iconColor": "#ffffff",            // tint; keep #ffffff for colour icons
  "iconStyle": "color",              // "color" (default) or "white" (flat, tinted by iconColor)
  "zIndex": 1, "visible": true, "rotation": 0, "clip": false,
  "canvas": [0, 900],                // ScrollingFrame: CanvasSize Y in [scale, offset]; or "auto": true for AutomaticCanvasSize Y
  "corner": 12,                      // UICorner radius in px (or [scale, offset])
  "stroke": {"color": "#ffffff", "thickness": 2, "transparency": 0.6},   // UIStroke
  "gradient": {"colors": ["#ff7a3d", "#ff3d7a"], "rotation": 90},      // UIGradient (2-3 colours)
  "padding": 12,                     // UIPadding px on all sides (or [top, right, bottom, left])
  "list": {"dir": "Vertical"|"Horizontal", "padding": 8, "hAlign": "Center"|"Left"|"Right", "vAlign": "Top"|"Center"|"Bottom"},   // UIListLayout
  "grid": {"cell": [0.3, 0, 0, 150], "padding": [0, 10, 0, 10]},       // UIGridLayout: cell size UDim2, cell padding UDim2
  "studs": true,                     // classic Roblox stud texture tiled over this panel/button (only for the Stud style), or a number = stud size in px (default 24)
  "aspect": 1.6,                     // UIAspectRatioConstraint (width ÷ height) — use on the main window so it keeps its shape on phones
  "children": [NODE, ...]
}

BEHAVIOR (only these types):
  {"type": "toggle", "button": "OpenShopButton", "target": "ShopWindow"}     // click shows/hides target
  {"type": "close",  "button": "CloseButton",    "target": "ShopWindow"}     // click hides target
  {"type": "tabs",   "buttons": ["SwordsTab","PetsTab"], "pages": ["SwordsPage","PetsPage"]}   // one page visible at a time, active tab highlighted
  {"type": "hover",  "buttons": ["BuyButton1","BuyButton2"]}                  // buttons grow slightly on hover
  ANIMATIONS (use when animations are asked for):
  {"type": "popin",  "target": "ShopWindow"}                                   // window pops in (scale bounce) whenever it opens
  {"type": "bounce", "buttons": ["BuyButton1","ClaimButton"]}                  // buttons squish when pressed
  {"type": "countup", "label": "CoinValue", "to": 125450, "prefix": "", "suffix": "", "short": false}   // number label counts up from 0 (short: true → 1.2M style)
  {"type": "pulse",  "target": "ClaimButton"}                                  // gentle endless pulse to draw attention (1-2 per GUI max)
  {"type": "spin",   "target": "GlowRays", "speed": 60}                        // endless rotation in degrees/second (sunburst / rays behind a reward)

DESIGN RULES (this is what makes a GUI look professional):
- Use SCALE for layout so it works on phones, tablets and PCs: main window e.g. size [0.5,0,0.6,0] centred with anchor [0.5,0.5], pos [0.5,0,0.5,0] and an "aspect" constraint. Offsets only for small fixed things (corner radius, padding, stroke, icon size inside a button).
- Clear hierarchy: a title bar (title text + close button "X" top-right), then content. Big readable text: titles 24-32, body 14-18, or textScaled true inside fixed-height labels.
- Rounded corners everywhere (8-16), soft strokes (thickness 1.5-3, transparency 0.4-0.7), 2-colour gradients on primary buttons and headers.
- Pick ONE accent colour + dark or light neutrals; good contrast (light text on dark, dark text on bright buttons). Don't use pure #000000 / #ffffff backgrounds — use near-black/near-white.
- Repeated items (shop cards, inventory slots, friends) go in a ScrollingFrame with a grid or list layout. Make 4-8 example items with realistic names and prices, each card: icon, name, price (coin icon + number), button.
- Children inside a "list" or "grid" parent don't need pos (the layout places them) — still give size (grid cells take their size from the grid).
- Leave breathing room: padding 10-16 inside panels, 8-12 between items.
- Every TextButton has text (or an icon child). Buttons look like buttons: coloured, rounded, stroke or gradient.
- bgT 1 for pure text labels so they don't draw boxes; use "textColor" and font weight for emphasis.
- Fonts: GothamBold / GothamMedium / Gotham for clean modern; FredokaOne for cartoony simulator games; LuckiestGuy for bold kid games; SourceSans / SourceSansBold for classic; Arcade for retro; Bangers for comic.
- HUDs (coins counter, health bar, buttons on the side) go along the screen edges with small sizes; don't cover the middle.
- Include "behaviors" whenever there are tabs, an open button, or a close button. If the GUI starts closed, set the window "visible": false and add an open button in "extra" with a toggle behavior.
- STUD STYLE (only when the style asks for studs): classic Roblox brick look — set "studs": true on the main window, title bar, big panels and chunky buttons (not on small labels, icons or text-only nodes); bold saturated brick colours (Bright red #c4281c, Bright blue #0d69ac, Bright yellow #f5cd30, Bright green #4b974b, Dark stone grey #635f62, Medium stone grey #a3a2a5), thick darker strokes (2-4), small corners (4-6), chunky SourceSansBold / FredokaOne text with a dark text stroke, buttons that look like 2x4 bricks.
- 25-120 nodes. More detail = better, but every node must be useful.

ICON LIST (use only these names in "icon"; pick ones that fit — these are real coloured game icons): add_player, angel_heart, apple, arm, aura, aura2, auto_open, avocado, axe, backpack, bag, bait, balloon, banana, bird, blueberry, bomb, book, box, broken_heart, bubble_gum, bunny, burger, calendar, carrot, cart, cash, cat, chat, check, check_button, chest, clock, close, close_x, cloud, cloud2, clover, codes, coil, coin, cookie, cracked_egg, credit_card, crown, crystal, cursor, devil, diamond, dice, dog, downgrade, egg, exclamation, fire, fire2, friend, full_body, gamepad, gift, guilded, gum, hammer, heart, house, hoverboard, info, ingot, key, leaf, lemon, lightning, location_pin, lock, lucky_block, magical_teleport, magnet, medal, minus, music_off, music_on, newspaper, orange, pancake, paw, pencil, pizza, planet, player, players, plus, potion, premium, question, rip, robux, rocket, save, scroll, search, settings, shield, shoe, shovel, skip, skull, sound_off, sound_on, star, stats, strawberry, sword, target, teleporter, thunderstorm, ticket, toilet, torch, trade, trail, trash, trophy, tung, upgrade, verify, vip, warning, wheat, wheel.
ICON VARIETY: in lists/grids give each item its OWN fitting icon, never the same icon repeated (pets → bunny, cat, dog, paw, devil, skull, tung, toilet; items → sword, shield, potion, bomb, axe, key, torch, scroll). Don't use giant icons as background decoration. Keep text labels inside their parent (no labels hanging below buttons where the next button will cover them).
ICON STYLE: by default icons are full-colour (leave iconColor #ffffff). Add "iconStyle": "white" plus an iconColor to get a flat single-colour version tinted to that colour (good for small toolbar/nav buttons, close/check/plus/minus, settings). White versions exist for all except: angel_heart, aura, aura2, auto_open, bunny, cat, dog, magical_teleport, toilet, trail, tung, vip.`,
};
