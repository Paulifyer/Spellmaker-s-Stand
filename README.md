# Spellmaker's Stand

## Spell controls

Hover a battlefield tile and press **1**, **2**, or **3** to cast the spell in
that slot immediately. Numpad **1–3** work too. Ordinary spells cast once per
press; holding the key does not repeat them. Mouse clicks still operate buttons
and menus.

For a channeled spell, hold the key that started it and release that same key to
stop. The channel stays aimed at its original lane when the cursor moves. Other
spell keys are ignored during a channel. Running out of mana also ends it.

Spell slots briefly flash cyan after a successful cast and stay cyan while
channeling. Each slot has its own cooldown, shown by the progress bar beneath it;
using one spell does not put the other slots on cooldown. Invalid targets,
unusable spells, insufficient mana, exhaustion, and that slot's cooldown reject
casts without queuing them. Configure slot durations in seconds with
`player.spell_cd_by_slot` in `datafiles/tune.json`; `player.spell_cd` is the
fallback when a slot has no configured value. A channel starts its slot cooldown
when the channel ends.

Menus block casting; opening the spellbook or losing window focus ends an active
channel. Pausing freezes gameplay. If the channel key is released while paused,
the channel ends on the first resumed frame. **Space** still starts mana recovery.

In GameMaker, check all three slots with both keyboard sections, tile targeting,
tap versus hold behavior, channel release and exhaustion, pause/resume, spellbook
naming, mouse-operated buttons, and the slot highlights and control hint.

## Delay in spell sequences

Attach Delay to an effect group to postpone the effects after that group.
For example, add Harm, attach Delay to Harm, then add Harm again: the first
Harm happens on contact and the second happens one second later by default.
All following effects keep that delay; another Delay adds another second.
Stacking Delay on a group also adds more time. Adjust the seconds per stack
with `modifiers.delay.delay_increase` in `datafiles/tune.json`.

An effect can appear only once between Delay boundaries. Harm → Harm and
Harm → Fire → Harm are rejected; Harm → Delay → Harm is allowed. Removing a
Delay or a group that would leave invalid repeats is rejected with a message.
Remove the repeated effect first. Every effect occurrence and Delay stack
adds its normal mana cost. A trailing Delay has no following effect to postpone.

## Spell construction rules

Each level entry in `datafiles/level.json` defines `max_glyphs` (an integer of
at least 2) and `unlocked_glyphs` (only the new unlocks for that level). Limits
for the existing rooms are 2, 3, and 5. The eight-level draft in `notes/` also
contains the later limits of 6, 7, 8, 8, and 8; it still requires unfinished
game features before activation. No separate progression JSON is used.

Every Form, Effect, modifier, and repeated modifier counts toward the limit.
The editor shows the count, refuses excess additions, and keeps excess groups
visible if an old spell needs repair. Form changes remove incompatible Form
modifiers and incompatible Effects (including their modifiers) automatically.
Compatible Effect modifiers are preserved.

A prepared spell needs a Form and at least one real Effect. Empty/name-only
slots do not block Start. All occupied slots must have available, compatible
glyphs, a valid Delay sequence, a legal glyph count, and an affordable cost.
Invalid spells are also rejected when casting. Palette hover text explains
why a glyph cannot be added; slot hover text explains invalid spells.

Pierce accepts Projectile/Beam; Amplify accepts Harm/Fire/Hex; Extend Time
accepts Fire/Frost/Lightning/Hex; Delay accepts all real Effects. AoE attaches
to any current Form when the central group is selected, or to Pull when its
Effect group is selected. These rules describe compatibility, not completion
of the separate Amplify+Hex or AoE+Pull behavior fixes.

Entering a level reconstructs cumulative ownership from that level and all
earlier JSON entries, so direct entry works and later unlocks do not leak into
earlier rooms. Victory previews upcoming glyphs without unlocking them early.
Unknown unlock IDs raise a configuration error instead of exposing missing
glyphs in the palette.

Run `node tools/test-glyph-progression.cjs`, `node tools/test-spell-construction.cjs`,
`node tools/test-spell-editor.cjs`, and `node tools/test-construction-regression.cjs`
for construction checks. Existing Delay, Pierce, and mana preview checks are
also retained. These tests simulate engine calls; verify in GameMaker:

- Levels 1–3 show limits 2/3/5 and the correct cumulative unlocks.
- Changing Projectile+Pierce to Strike removes Pierce but preserves legal Effect modifiers.
- Incompatible palette entries explain their restrictions; Extend Time accepts Hex.
- A Form-only, over-limit, or too-expensive spell in any slot blocks Start.
- Clearing that slot restores Start; empty/name-only slots remain unused.
- In a temporary test level with limit 8, seven Effect groups and modifier
  satellites remain readable and clickable. Revert the temporary limit afterward.

## Skeletal status inheritance

Skeletal enemies preserve Burn damage/duration, Frost strength/duration, stun,
charged immunity, Hex, and queued delayed effects when they die. Timers continue
through the one-second gap before the bone pile appears. Burn deals no damage
during this gap; expired statuses stay expired. Delayed effects due during the
gap apply once to the new pile, earliest due first and in insertion order for ties.

The pile keeps its normal 15 HP. A delayed killing blow can destroy it immediately
on appearance and cancel revival. If it survives, remaining statuses and delayed
effects transfer to the revived enemy without restarting their timers. The revived
enemy starts with its normal health and loses the skeletal mutation. Replacement
preserves the wave's active-enemy count; destroying the pile ends that enemy's slot.

Run `node tools/test-skeletal-status.cjs` for simulated-engine regression checks.
In GameMaker, check burning skeletons, delayed hits due before/after pile appearance,
pause during the spawn gap, and a surviving pile carrying effects into revival.

## Standard wave generation

Levels define a threat curve and an enemy roster instead of manually repeating
enemy objects in every wave. At room creation, `generate_standard_waves()` builds
the concrete `WaveData.enemy_array` queues used by the wave manager, then divides
each queue into coordinated spawn groups.

An enemy roster entry contains:

- `enemy_object`: the GameMaker enemy object to spawn.
- `cost`: how much of a wave's threat budget it consumes.
- `weight_setting`: its relative selection frequency after required minimums.
- `min_setting`: the required number of copies in a wave.
- `max_setting`: the total upper bound, including required copies.

Weight, minimum, and maximum settings accept either a scalar, which applies to
every wave in that level, or an array with exactly one entry per wave. A zero
weight prevents random additions but does not suppress a configured minimum.
Setting weight, minimum, and maximum to zero makes an enemy unavailable for a
wave.

Level 1's configuration lives in
`objects/obj_wave_level_1/Create_0.gml`. Its starting and ending budgets define
the difficulty range, while `difficulty_curve` controls how quickly the budget
ramps up.

Group composition is generated automatically. Early waves target roughly 2.5
threat per group and late waves target roughly 6, with seeded variation of
plus or minus 25 percent. Groups are limited to six enemies and every enemy in a
group is spawned on a distinct, randomly selected lane. Members enter 0.1 seconds
apart, keeping each group visually connected without placing every enemy on the
same frame. The original flat enemy queue is retained for validation and systems
such as the spellbook.

The delay between groups is selected randomly from the simple minimum and
maximum range in the wave manager's `WAVE TIMING SETTINGS`. It does not depend
on enemy threat, wave budget, or a timing pattern.

After a wave is completely cleared, the wave manager enters an intermission
before starting the next numbered wave. The `WAVE TIMING SETTINGS` section at
the top of `objects/obj_wave_manager/Create_0.gml` exposes all timing values as
plain seconds: within-group stagger, the random between-group range, and the
fixed intermission between numbered waves.

The generated order varies between runs. Minimums establish the required
composition, weights distribute the remaining budget, and maxima prevent extreme
random outcomes. The run seed
is printed to the debug log and can be passed back to
`generate_standard_waves()` to reproduce a generation.

To add an enemy to a level:

1. Make the enemy inherit from `obj_enemy_parent`.
2. Configure both `base_speed` and `my_speed` in its Create event.
3. Add an `EnemyWaveDefinition` to the level roster.
4. Choose scalar or per-wave weight, minimum, and maximum settings.
5. Ensure every wave can afford the combined cost of its configured minimums.

Invalid configurations and generated queues are checked at startup and report a
descriptive GameMaker error.
