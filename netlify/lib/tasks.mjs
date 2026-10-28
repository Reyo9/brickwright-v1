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
};
