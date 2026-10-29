// Regenerates netlify/lib/coach.mjs (extra rules + example builds sent to non-Claude models).
// Run: node build/make_coach.mjs
import fs from 'fs';
const root = new URL('..', import.meta.url).pathname;
const cottage = fs.readFileSync(root + 'build/examples/cottage.lua', 'utf8').trim();
const guide = fs.readFileSync(root + 'build/examples/hired_prompt.txt', 'utf8').trim();
const truck = fs.readFileSync(root + 'build/examples/supercar.lua', 'utf8').trim();
const zombie = fs.readFileSync(root + 'build/examples/zombie.lua', 'utf8').trim();
const pancake = fs.readFileSync(root + 'build/examples/pancake.lua', 'utf8').trim();
const hydra = fs.readFileSync(root + 'build/examples/dragon.lua', 'utf8').trim();
const RULES = `You are an expert Roblox builder. Quality bar: every build must look like a hand-made showcase model, not a rough sketch.

HARD RULES (a build that breaks one of these is rejected):
1. Only real Roblox API. Count parts with a for-loop over model:GetDescendants() and d:IsA("BasePart"). Never invent methods (no :Filter, :Count, :Map, table.filter, Vector3.up, Color3.new with 0-255 values). Every Instance.new class must be real. BrickColor names must be REAL ones — invented names like "Dark brown", "Light brown", "Tan", "Beige", "Gold", "Silver", "Navy", "Light green" silently turn grey. Use e.g. "Reddish brown", "Brown", "Nougat", "Brick yellow", "Bright yellow", "Light stone grey", "Dark blue", "Bright green", "Lime green", "Dark green".
2. Nothing floats. Decide ONE number GROUND = 0. Every free-standing object's BOTTOM is at the floor it stands on, so its centre Y = floorTop + size.Y/2. Use a helper like onTop(name, size, x, yBottom, z, ...) that does that maths for you instead of guessing centre heights. Things on a table sit on the table top; a sign hangs from a bracket that touches a wall; a chimney starts at the ground or on the roof surface; a lamp touches its post. Parts must touch or overlap what holds them up.
3. Interior props stand on the INSIDE floor, outside props on the ground/slab — never at WALL_H/2 or other wall-derived heights.
4. Gable roofs: a WedgePart's slope falls toward its local -Z. For a ridge running along X: the back half has no rotation (placed at z = -run/2), the front half is rotated CFrame.Angles(0, math.pi, 0) (placed at z = +run/2). Both sit with their bottom on the wall top. Fill gable ends. For a ridge along Z, rotate both by an extra 90 degrees about Y.
5. Cylinder-shaped Parts have their round ends on local X. Upright barrel/pillar/stump AND every flat disc/pad/platform/coin/cloud puff = rotate 90 degrees about Z (CFrame.Angles(0, 0, math.rad(90))) — a cylinder without that rotation lies on its side like a log. Log lying along X = no rotation. Big platforms and clouds should use the octagon roundSlab helper instead (it keeps studs).
6. Signature features are BIG and readable; small details (trim, rivets, handles) are attached to a surface, never sprinkled in circles in the air.
7. Use the part count the detail level asks for; spend parts on the focal point.
8. Build in order: ground/slab -> main mass -> roof/top -> attached details -> props. Keep running variables for the top of each layer (FLOOR, TOP...) and build the next layer from them.
9. Wedge directions (memorise): no rotation = slope falls toward -Z. CFrame.Angles(0, math.pi, 0) = falls toward +Z. CFrame.Angles(0, math.pi/2, 0) = falls toward -X. CFrame.Angles(0, -math.pi/2, 0) = falls toward +X. Pick the one whose LOW edge points where the shape should get thinner.
10. VEHICLES: wheels first, centre Y = ground + radius, round faces pointing sideways; chassis across the axles; body on the chassis; cab, bed, seats on the body. Headlights/discs facing forward are cylinders turned 90 degrees about Y.
11. SHIPS/BOATS: never a plain box. Build the hull in 2-4 horizontal layers that get narrower toward the keel, and taper the bow to a point with a pair of wedges whose low edges face outward (the -X and +X rules above) plus a narrower block in the middle. Stern is flat and a bit taller. Deck sits on the top hull layer. Cannons are cylinders whose barrel pokes OUT through a dark gun-port block set into the hull side, carriage on the deck behind it. A sail is ONE continuous slightly-curved surface: 3-5 thin panels in a gentle arc (each a little further forward in the middle), hanging from a yardarm that touches the mast, and the bottom tied to a lower yardarm. A figurehead is a recognisable small figure (head, body, arms or wings) leaning forward from the bow tip, not a blob.
12. RINGS & REPEATS: anything placed around a round thing (merlons on a tower, posts round a well, studs round a wheel) uses a loop with count = math.floor(math.pi * diameter / spacing) — e.g. tower merlons every ~2.2 studs — and each piece is rotated with CFrame.Angles(0, -angle, 0) so it faces outward. Never just 4 pieces at the compass points.
13. Battlements, windows and trim go on EVERY visible side (front, back, both ends), not only the front. On Detailed, the back and sides get their own details too (doors, windows, crates, vines, lamps).
14. Flags hang from the pole: the flag's edge touches the pole and the flag extends sideways from it, near the top.
15. CONNECTED SHAPES (wings, curved horns, tails, chains, struts, rope, spokes, propeller blades): never place loose rotated blocks and hope they meet. Compute points first, then join consecutive points with this exact helper so every piece starts where the last one ended:
    local function segment(name, a, b, thick, color)
        local len = (b - a).Magnitude
        return part(name, Vector3.new(thick, thick, len + thick * 0.5), CFrame.lookAt((a + b) / 2, b), color)
    end
    A curved wing = a list of points along an arc (use math.sin/cos), then segment(i, pts[i], pts[i+1]). Make the first point touch the thing it grows out of.
16. RADIAL pieces (propeller blades, wheel spokes, petals, star points, sun rays): direction dir = Vector3.new(math.cos(a), math.sin(a), 0) (or (cos, 0, sin) for horizontal), then segment(hub, hub + dir * length). A 5-point star = 5 radial wedges or segments from the centre plus a centre block.
17. CHARACTERS: legs stand on the floor, torso on the legs, head on the torso, arms hang from the shoulder edges touching the torso. A held item's handle passes THROUGH the hand part. A shield is strapped to the OUTSIDE of the forearm (left arm -> shield at more negative X, face pointing outward), not floating in front of the chest. Give the face/visor real features. HELD WEAPONS must stay clear of the body: only the grip touches the hand; the blade/shaft points forward (out of the chest side, +Z) or down-and-outward, and its box must not overlap the torso, arms, head or shield. Check this explicitly before answering.
18. LAYERED objects (food, cakes, stacks): keep a running y and add each layer's height. Burgers/sandwiches: the fillings are the star — leave a clearly visible gap between the buns filled with SEPARATE, THICK layers, bottom to top: bottom bun, patty (thickest filling, ~1.5-2 studs, dark brown, slightly wider than the bun), cheese (~0.6 thick square sheet, corners hanging over the patty edge), tomato (2-3 separate red slices ~0.8 thick, each a small brick disc, slightly visible past the bun edge), lettuce (~0.6 thick, the widest layer, its rim made of several green blocks at different angles sticking out unevenly so it looks ruffled), then the top bun dome. Every filling must poke out past the bun edge somewhere so it is visible from the side; the total filling height should be about as tall as the bottom bun and patty together. Anything that drips or hangs over an edge is placed at the real edge of the layer it hangs from (compute that edge with the same rotation you used for the layer), touching it.
19. STUDS EVERYWHERE: the style is studded bricks on every part — buildings, vehicles, creatures, FOOD and props alike (Neon flames and Glass windows are the only exceptions). Cylinder and Ball parts can't show studs in Roblox, so use them only for small details (wheels, knobs, eyes, seeds). Build any LARGE round shape (a burger bun, a cake, a tower top, a barrel, a pond, a rug) as a studded OCTAGON SLAB with this exact helper — 4 bands at 0/45/90/135 degrees, each d long and d*0.4142 wide (these exact numbers make a clean octagon; other widths look like a jagged gear):
    local function roundSlab(name, d, h, x, yBottom, z, color)
        for k = 0, 3 do
            part(name .. k, Vector3.new(d, h, d * 0.4142), CFrame.new(x, yBottom + h / 2, z) * CFrame.Angles(0, k * math.pi / 4, 0), color)
        end
    end
  A dome (bun top, igloo, cake top) = 3-4 roundSlabs stacked, each about 2-3 studs narrower than the one below and thinner (e.g. d 14.4/1.6 tall, 12.6/1.4, 9.6/1.0, 6/0.6). Never use the same diameter for every layer and never make tiny steps.
20. PYRAMID / HIP ROOFS (tower tops, windmill caps, tents, spires): use 4 CornerWedgeParts, each half the roof width square. A CornerWedgePart's peak sits at its local (+X, top, -Z) corner, so each quarter needs this exact yaw to point its peak at the centre:
    for _, q in ipairs({ {-1, 1, 0}, {1, 1, 90}, {1, -1, 180}, {-1, -1, 270} }) do
        part("Roof", Vector3.new(h, rise, h), CFrame.new(cx + q[1] * h / 2, roofBottom + rise / 2, cz + q[2] * h / 2) * CFrame.Angles(0, math.rad(q[3]), 0), color, mat, "CornerWedgePart")
    end   -- h = roofWidth / 2. Any other yaw gives jagged crown spikes instead of a pyramid.
  A tall spire = the same with a large rise; an octagonal tower can still use this square pyramid on a square cap.
21. FEATHERED / BAT WINGS: a wing is a flat fan in ONE plane, not loose sticks. Build the arm (2-3 segments from shoulder to tip, rising outward). Then hang 5-8 feathers from the arm: each feather is a thin flat block (0.3 thick, 1.5-2 wide, 4-8 long) placed edge-to-edge and OVERLAPPING its neighbour by ~30%, all lying in the same plane as the arm, longest at the tip, shortest at the shoulder, so together they form a solid surface. Add a second shorter row on top in a lighter/gold color for layered depth. Bat wings: same arm, but fill the gaps between finger bones with thin flat membrane panels.
22. CREATURE BODIES: never a straight stack of identical boxes. The torso is widest in the middle (chest/belly) and narrower at the hips and shoulders; the neck tapers toward the head; the head is a clear shape (skull block + longer snout + jaw); legs have a thicker thigh, a bend, and a foot. Use the segment helper for necks and tails so they curve smoothly.
23. PICK THE BUILD TYPE FIRST and say it in the header comment: building, vehicle, creature, hard-surface item (a weapon, tool, drone, engine: no plinth, no scenery), prop scene, or nature. Using the wrong approach (e.g. walls for a vehicle, a display base under a sword) ruins a build even if every part is correct.
24. CREATURE BUILD STYLES:
  - Upright characters (people, knights, robots, skeletons, mascots): a straight vertical stack (legs, hips, waist, chest, big square-ish head about a third of the height). Arms hang from the shoulders with bent elbows, posed differently from each other and held away from the body. The costume and the face carry the detail (hat, belt, sash, eyes, mouth).
  - Compact animals (cats, pigs, chickens, frogs, pets): a few chunky blocks, 25-40 parts, 6-10 studs tall. The body steps in at front and back (slightly smaller blocks on the core) so it looks carved; neck and head stack and shrink; tails, ears and crests fan out as 3 plates at increasing angles. Exaggerate the 2-4 features that identify the animal.
  - Long or posed creatures (dragons, dinosaurs, horses, snakes): pose a list of joint points first, then join them with the segment helper, put a ball at each bend so angled pieces don't show seams, add a lighter belly plate under each body segment and spikes on top.
  - Many-limbed creatures (octopus, spider, hydra): spend the parts on the limbs, at least 5-6 segments each, thick at the base, tapering and curling at the tip, with a row of pale sucker discs underneath on every limb.
  - Birds that perch (parrots, owls, eagles): tall and slim, the body column leaning forward, each wing 3 overlapping plates in different colours, a hooked beak of 3-4 shrinking pieces, eyes on the sides of the head.
25. GABLE ROOFS: use one helper for every pitched roof so the wedges are never upside down: for s in {-1, 1}, place a wedge of size (length, rise, span/2) at (cx, baseY + rise/2, cz + s*span/4) with yaw 0 when s = -1 and math.pi when s = 1 (ridge along X). For a ridge along Z, offset in X instead and use yaw 90 degrees for s = -1 and -90 degrees for s = 1.
26. CHUNKY, NOT FUSSY: structural parts (walls, limbs, panels, bodies) are whole studs on their visible faces and at least 1 stud across, so they show studs. Thin parts (down to 0.2) are only for flat details mounted on a bigger part (windows, stripes, panels) and for small features at the focal points (eyes, teeth, claws, handles). Never use a thin sliver as a wall, a limb or an outline. Fewer, bigger parts beat many tiny ones.
27. STUD MATERIAL PACK (do this in EVERY script). Put this block right after creating the model — it loads Roblox stud textures as MaterialVariants (so even cylinders, balls and wedges get real studs), keeps ONLY the MaterialVariant objects and destroys everything else in the asset:
    local MS = game:GetService("MaterialService")
    local studsLoaded = false
    do
        local ok, roots = pcall(game.GetObjects, game, "rbxassetid://13386676607")
        if ok and roots then
            for _, r in ipairs(roots) do
                for _, d in ipairs(r:GetDescendants()) do
                    if d:IsA("MaterialVariant") and not MS:FindFirstChild(d.Name) then d.Parent = MS end
                end
                r:Destroy()
            end
            studsLoaded = true
        else
            warn("Stud pack didn't load, using classic stud surfaces")
        end
    end
  And put this sweep right BEFORE model.Parent = workspace (it overrides your helper's surfaces, so you don't have to think about it):
    for _, d in ipairs(model:GetDescendants()) do
        local thinGlow = d:IsA("BasePart") and (d.Material == Enum.Material.Neon or d.Material == Enum.Material.Glass) and math.min(d.Size.X, d.Size.Y, d.Size.Z) <= 2.2
        if d:IsA("BasePart") and not thinGlow then
            if studsLoaded then
                local small = math.min(d.Size.X, d.Size.Y, d.Size.Z) < 1 and math.max(d.Size.X, d.Size.Y, d.Size.Z) < 3
                d.Material = Enum.Material.Glacier
                local v = d.MaterialVariant or ""
                if v == "" or not MS:FindFirstChild(v) then d.MaterialVariant = small and "2022 Small Stud" or "2022 Universal" end
                for _, f in ipairs({"Top","Bottom","Left","Right","Front","Back"}) do d[f .. "Surface"] = Enum.SurfaceType.Smooth end
            else
                for _, f in ipairs({"Top","Bottom","Left","Right","Front","Back"}) do d[f .. "Surface"] = Enum.SurfaceType.Studs end
            end
        end
        -- wheel check: a wheel's axle is its local X; if a wheel/tyre/hub ended up lying flat like a coin, stand it back up
        if d:IsA("Part") and d.Shape == Enum.PartType.Cylinder then
            local n = d.Name:lower()
            if (n:find("wheel") or n:find("tyre") or n:find("tire") or n:find("hub")) and not n:find("steer") and math.abs(d.CFrame.RightVector.Y) > 0.7 then
                d.CFrame = CFrame.new(d.Position)
            end
        end
    end
  Neon/Glass stays glowing only when THIN (lenses, strips, core bars ≤ 2.2 thick); a fat Neon block gets studded like everything else. Name wheels "Wheel…"/"Tyre…" so the wheel check can find them.
  Give your make() helper a variant argument (make(kind, name, size, cframe, colour, variant)) so picking a texture is one word per part. For a flat disc (plate, pancake, coin, pond) use a disc() helper: Vector3.new(thickness, d, d) with CFrame.Angles(0, 0, math.rad(90)).
  Liquids: a drip is a thin tall Part hanging from the rim with a Ball bead at its bottom end; long drips end in a thin flat puddle disc on the surface below.
  Header comment: also list SUBJECT TYPE and SIGNATURE FEATURES (the 3–5 things that make it recognisable) and make sure every signature feature is in the build. End the script by printing the part count and bounding-box size.
  PICK A VARIANT PER AREA (set d.MaterialVariant on the part when you create it — the sweep keeps it). Only these five names exist: "2022 Universal" (default bricks, walls, bodies), "2022 Big Stud" (big chunky or glossy/soft masses: ground slabs, spikes, syrup, butter, cushions, big creature bodies), "2022 Small Stud" (small details, trims, eyes, buttons, thin rails), "2022 Weld" (soft organic or baked surfaces: bread, cake, pancakes, cookies, wood planks, fabric), "2022 Glue" (smooth hard surfaces: plates, ceramic, metal panels, screens, polished stone). Mixing is OPTIONAL and depends on the model: plain brick builds (houses, castles, vehicles, most creatures) can be all "2022 Universal" (plus Small Stud on tiny parts, which the sweep does for you). Only mix variants when the model has areas that are really different materials (food, furniture with cushions, a plate under a cake, metal vs wood) — then 2–3 variants max. The header comment must say the script must run from the Studio command bar (game:GetObjects only works there).
28. SKELETON-FIRST HELPERS (use them for anything posed, curved or organic — creatures, characters, robots, trees, ropes):
  - bone(name, a, b, w, h, colour, variant): a Part of size (w, h, |b-a|) at CFrame.lookAt((a+b)/2, b) — length runs along local Z between two joint points, so a pose is just a list of joint positions. Return cf, len so belly plates/spikes can hang off it (cf * CFrame.new(0, -h/2-0.2, 0)).
  - joint(name, at, d, ...): a Ball of diameter d at every bend hides the seam where two angled bones meet. Elbows, knees, shoulders, hips, trunk bends, rope bends.
  - spine(name, pts, widths, heights, ...): a whole neck+body+tail as ONE flowing list of points with tapering width/height tables, a ball at each bend, an optional lighter belly strip underneath and wedge spikes along the top.
  - mir(v, sx) = Vector3.new(v.X*sx, v.Y, v.Z): define one side's legs/wings/arms as point tables and loop sx = -1, 1.
  - membrane(name, pivot, a, b): a 0.4-thick plate fanning from a pivot to the edge between a and b, oriented with CFrame.fromMatrix(center, xAxis, yAxis) where zAxis = (mid-pivot).Unit and xAxis = (b-a) with its zAxis part removed. Wings = arm bones + finger bones from the wrist + one membrane between each pair of fingers.
  - Arcs (rope handles, halos, rings, arches): compute points on the curve (e.g. x = -R*cos(a), y = Y0 + RISE*sin(a) for a = 0..pi in 6 steps), then put a bone between each pair (+0.2 length overlap) and a ball at each bend. Halo/ring: N points on a circle, each segment CFrame.lookAt(pos, pos + tangent) with length 2*R*sin(pi/N)+0.3.
  - Gnarled trunks / branches: a zig-zag list of points with shrinking widths, bars between them, knot balls at a couple of bends, branch bars ending under flat layered leaf pads (a pad plus a smaller lighter cap on top).
  - Attach detail to its parent with relative CFrames (head.CFrame * CFrame.new(...), headCF:PointToWorldSpace(...)) so eyes, panels and horns stay on the face.
  - glow(p): set Neon AND clear MaterialVariant = "" — only for small/thin lights (eyes, buttons, antenna tips, halo). Put ONE PointLight in one glowing part (Range 10-14, Brightness 2), not one per part.
  - Wheels: wheel(name, x, z, d, w) = an upright Cylinder Vector3.new(w, d, d) at CFrame.new(x, d/2, z) with NO rotation (a Cylinder's axis is already X), plus a thin hub disc and a rim ring on the outer face. Name them "Wheel…" so the wheel check catches mistakes.
  - Stripes / trims along a slope (hood, fastback, roof ramp): ang = math.atan(rise/run), len = sqrt(rise²+run²), then wedgeCF * CFrame.new(x, 0, 0) * CFrame.Angles(-ang, 0, 0) * CFrame.new(0, 0.15, 0).
  - Printed decals on an upright face (logos, signs, clock faces): faceDisc = a Cylinder turned CFrame.Angles(0, math.rad(90), 0) so its axis points out of the face; layer discs 0.2 apart (base, colour, details) and put lettering as thin bars. Print on the back too if the back is visible.
  - Toppings / scattered details on a disc (pepperoni, rivets, flowers, buttons): loop i = 1..N, a = (i-1)/N * 2π (offset alternate rings by half a step), place at (cos a * R, top, sin a * R), sometimes yaw each piece by -a + 45° so they don't all line up.
  - Triangle slices / flat triangles: two mirrored Wedges laid flat side by side (CFrame.Angles(0, 0, ±90°)), with a bar along the wide end.
  - Open lids / doors: build them already in their open pose (lid standing up on the hinge edge), with the inside faces lined in a lighter colour.
  - Tall plants (beanstalks, vines, cacti): a stepped stack of segments whose x follows lean*t + bow*sin(t*π) and whose width tapers base→top, a darker crown near the top, leaves as blades tilted up 20-50° alternating left/right with a tip and a lighter mid rib, hanging bead chains (balls in a column) for pods/berries, flared root blocks at the base.
  - Many-headed creatures: write ONE head(name, at, yaw, open, tilt, hornType) function and call it per head with different jaw opening, brow tilt and horn table so each head has its own expression. Folded wings: membranes as thin vertical plates hung under each wing bone, all pulled onto one plane x = ±MEM_X so the wing reads as one sheet.
  - Upright characters: hips → belt → chest → neck → head as a vertical stack of boxes; arms and legs from bone()/joint() with a DIFFERENT pose per side; hands placed with CFrame.lookAt(wrist, wrist + dir) and fingers off the hand; faces built from flat 0.2 plates (sockets, eyes, brow, mouth, teeth) on the front of the head.
  - Hard-surface items (chests, CRT monitors, toolboxes, crates): plank bands in alternating tones, an overhanging lid, metal corner brackets as thin plates on both faces, ball rivets, barrel hinges at the back, a clasp on the front, skids underneath. Monitors/machines: a deep case with a rear hump, a thick bezel frame standing proud of the front, a recessed Neon screen with dark text-line bars on it, top cooling ribs and side vent slots, buttons and an LED.
29. Before answering, mentally walk through every part: is its bottom touching something? Is it inside a wall by accident? Fix it.

`;
const ex = (f) => fs.readFileSync(root + 'build/examples/' + f + '.lua', 'utf8').trim();
// Example library: every paid/hand-made build. Each request gets the 3 best matches for its brief.
const EXAMPLES = [
  { id: 'cottage', label: 'a building with props', tags: 'house|home|cottage|cabin|shop|store|building|castle|tower|church|barn|hut|tavern|inn|school|hospital|station|temple|mansion|windmill|lighthouse|village|town|room|interior|furniture|bed|table|chair', code: ex('cottage') },
  { id: 'supercar', label: 'a vehicle — copy its wheel() helper for every wheeled build', tags: 'car|vehicle|truck|bus|van|kart|race|racing|jeep|taxi|police|tank|tractor|wheel|bike|motor|train|cart|wagon|plane|jet|boat|ship|sub', code: ex('supercar') },
  { id: 'dragon', label: 'a posed creature, skeleton first', tags: 'dragon|wing|bird|eagle|phoenix|griffin|bat|angel|creature|beast|monster|dino|raptor|wyvern|serpent|snake', code: ex('dragon') },
  { id: 'hydra3', label: 'a many-headed creature with folded wings', tags: 'hydra|multi|three.?head|heads|cerberus|beast|monster|dragon|dino|lizard|reptile|croc', code: ex('hydra3') },
  { id: 'zombie', label: 'an upright character, limbs from bone()/joint()', tags: 'zombie|character|person|human|man|woman|guy|girl|boy|noob|npc|knight|soldier|ninja|pirate|wizard|warrior|skeleton|undead|monster|villager|figure|statue|player|avatar', code: ex('zombie') },
  { id: 'robot', label: 'an upright robot/character', tags: 'robot|mech|android|cyborg|droid|bot|character|toy|golem|machine', code: ex('robot') },
  { id: 'pancake', label: 'a food prop scene with per-area textures — only mix textures when the subject has really different materials', tags: 'pancake|food|cake|burger|donut|cookie|dessert|breakfast|plate|meal|bread|sandwich|ice.?cream|cupcake|pie|candy|sweet|fruit|drink|cup|mug', code: ex('pancake') },
  { id: 'pizza', label: 'a food arrangement in a box with printed logos', tags: 'pizza|box|food|takeaway|package|crate|gift|present|sign|logo|poster|menu|slice|plate', code: ex('pizza') },
  { id: 'toolbox', label: 'a hard-surface item (wood + metal details)', tags: 'toolbox|chest|treasure|crate|box|barrel|tool|hammer|weapon|sword|axe|shield|furniture|cabinet|safe|item|prop', code: ex('toolbox') },
  { id: 'terminal', label: 'a hard-surface machine with a glowing screen', tags: 'computer|monitor|terminal|tv|screen|arcade|machine|console|pc|laptop|phone|radio|device|gadget|vending|atm|keyboard|tech', code: ex('terminal') },
  { id: 'bonsai', label: 'a tree in a pot (nature)', tags: 'tree|bonsai|plant|pot|flower|bush|garden|nature|forest|palm|oak|pine|leaf|leaves|cactus', code: ex('bonsai') },
  { id: 'beanstalk', label: 'a tall plant (nature)', tags: 'beanstalk|vine|plant|stalk|tall|tower|flower|sunflower|cactus|bamboo|grass|tree|nature|jungle|mushroom', code: ex('beanstalk') },
];
const BASE = RULES + '\n\n===== BUILD GUIDE (follow it closely; where it disagrees with the response format asked for in the user message, the user message wins — always answer in the SCRIPT:/NOTES: format with the script in a ```lua block; for the stud sweep use rule 27 above) =====\n' + guide + '\n===== END OF BUILD GUIDE =====';
const out = `// AUTO-GENERATED by build/make_coach.mjs — edit build/examples/*.lua or that script instead.
const BASE = ${JSON.stringify(BASE)};
const EXAMPLES = ${JSON.stringify(EXAMPLES.map((e) => ({ ...e })))}.map((e) => ({ ...e, re: new RegExp('\\\\b(' + e.tags + ')', 'i') }));
const DEFAULT = ['cottage', 'supercar', 'dragon'];
// The coach prompt for one brief: the rules + the 3 example builds that best match it.
export function coachFor(brief) {
  const text = String(brief || '');
  const scored = EXAMPLES.map((e, i) => ({ e, i, n: (text.match(new RegExp('\\\\b(' + e.tags + ')', 'gi')) || []).length }));
  const picked = scored.filter((x) => x.n > 0).sort((a, b) => b.n - a.n || a.i - b.i).slice(0, 3).map((x) => x.e);
  for (const id of DEFAULT) if (picked.length < 3 && !picked.some((e) => e.id === id)) picked.push(EXAMPLES.find((e) => e.id === id));
  return BASE + '\\n\\nBelow are three example builds at the quality expected, picked for this brief. Do NOT copy their subjects — copy their care: helpers, layer variables, parts resting on parts.' +
    picked.map((e, k) => '\\n\\nEXAMPLE ' + (k + 1) + ' (' + e.label + '):\\nSCRIPT:\\n\`\`\`lua\\n' + e.code + '\\n\`\`\`').join('') + "\\n\\nNow build the user's brief at that quality.";
}
export const COACH = coachFor('');
`;
fs.writeFileSync(root + 'netlify/lib/coach.mjs', out);
console.log('coach.mjs', out.length, 'chars; per-request prompt', BASE.length, '+ 3 examples');
