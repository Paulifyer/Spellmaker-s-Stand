# Spellmaker's Stand

## Debug level select

Press **F8** on the main menu to open the debug level select screen. Click a
level or press **1–8** to enter it directly; **Esc** or **Back** returns to the
menu. The screen shows each level's wave count and planned glyphs that are not
implemented yet. Returning to the menu after a debug run resets normal Start to
level 1. Finishing level 8 returns to the menu instead of advancing past the
campaign. Set `debug.level_select_enabled` to `false` in `datafiles/tune.json`
to hide the shortcut and disable the selector; set it to `true` to enable it.

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

Effects can add seconds to that slot's cooldown through
`effects.<glyph>.cooldown_penalty` in `datafiles/tune.json` (default 0).
Pull adds 5 seconds, Hex adds 3, and Discharge adds 2. Each occurrence counts,
including effects repeated after Delay; modifiers do not multiply the penalty.
The total is captured when casting and also applies when a channel ends.

Beam timing and damage per hit are configured in `datafiles/tune.json` under
`forms.beam`: `ticks_per_second` defaults to 4 and
`damage_multiplier_per_tick` defaults to 0.25. Beam hits immediately, then
repeats at the configured rate. The multiplier scales Harm damage on each hit;
raising the tick rate without lowering it raises damage per second. Beam mana
drain remains based on spell cost per second.

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

Modifier entries in `datafiles/tune.json` support optional `max_per_form` and
`max_per_effect` caps. Chain currently has `max_per_form: 2`; Amplify has
`max_per_effect: 2`. Each Effect group has its own allowance, including repeated
Effects after Delay. Omitted fields add no cap; zero forbids the attachment.
Values must be non-negative integers. Existing compatibility, non-stacking and
level-wide glyph limits still apply. Over-cap spells must be repaired before
Start or casting. Restart after tuning changes. Run
`node tools/test-glyph-limits.cjs` to check these limits.

Balance restrictions are configured under `compatibility` in `datafiles/tune.json`.
`form_modifier_exclusions` maps Form IDs to forbidden modifier IDs; Beam currently
excludes `area` (AoE). Each `exclusive_form_modifier_groups` array permits only
one modifier type on a Form; the current group prevents mixing AoE, Pierce, and
Chain while preserving legal Pierce/Chain stacks. Effect-level AoE is unaffected.
These overrides only restrict built-in compatibility. Use `{}` for exclusions
and `[]` for exclusive groups (or omit the settings) to restore built-in behavior.
The adjacent JSON notes list supported combinations. Restart after editing.
Existing invalid spells must be repaired before Start or casting. Run
`node tools/test-glyph-compatibility.cjs` to check these rules.

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

Pierce accepts Projectile/Beam; Amplify accepts Harm/Fire; Extend Time
accepts Fire/Frost/Lightning/Hex; Delay accepts all real Effects. AoE attaches
to a Form when the central group is selected, and cannot attach directly to
Pull. Pull accepts Projectile/Strike/Rune. Form-level AoE remains legal on
Pull spells: other Effects receive AoE delivery, but Pull still attracts its
normal 3x3 region around each impact. Switching to Beam removes Pull and its
modifiers automatically.

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

## Status interactions and Rune placement

Lightning only stuns vulnerable enemies. Further hits during the stun or its
following charged period do not refresh either timer. When the stun ends,
charged immunity starts once and lasts `effects.lightning.stun_immune_duration`
seconds. Extend Time lengthens the stun, not the charged period. Skeleton spawn
gaps use the same timer transition. Frost is applied to movement independently
of Lightning, retaining its three-stack/60% cap, including on enraged Brutes.
Stun stops path movement and Pull retains control of its custom movement.

Hex checks active statuses on every damage event. Adding/removing Burn, Frost,
or Lightning immediately changes its bonus without reapplying Hex. Stunned and
charged phases count as one Lightning status; Hex also counts itself. Amplify
is incompatible with Hex; Extend Time remains compatible.

Unmodified status durations match `datafiles/tune.json` exactly. Extend Time
adds only its configured extra duration. Fire includes its final burn tick at
expiry. Pull's configured hold time does not depend on the extra-duration field.
Stacked Amplify costs use the same per-effect surcharge as the mana preview.

Rune capacity is `forms.rune.max_placed` per exact Form/modifier/ordered-Effects
configuration, independent of the spell's name or prepared slot. Arming and
armed Runes both count. A successful cast over capacity replaces the oldest
matching Rune. Occupied tiles and unaffordable casts are rejected before any
Rune is removed or mana charged. Other Rune configurations remain unaffected.

Run `node tools/test-status-interactions.cjs`, `node tools/test-glyph-restrictions.cjs`,
`node tools/test-rune-placement.cjs`, and `node tools/test-spell-timing-costs.cjs`
alongside the existing regression scripts. GameMaker checks still required:

- Hold Beam+Lightning: one stun, a finite charged period, then eligibility for a new stun.
- Frost slows normal enemies and enraged Brutes; Stun/Pull do not undo the slow.
- Pull is unavailable with Beam; direct Pull+AoE and Hex+Amplify are unavailable.
- Form AoE+Pull keeps a 3x3 attraction region while other Effects use AoE.
- Rune overflow replaces the oldest matching Rune; failed casts leave traps intact.
- Status durations, burn ticks, and stacked Amplify mana charges match the preview/tuning.

## Shared spell execution

The preview and casting use `compile_spell()` for one cost/modifier calculation.
Compiled groups contain occurrence indices, target policies, cumulative delays,
and captured tuning parameters. Delivery instances own hit records; compiled
values are read-only by convention and are not recalculated when delayed work runs.

All Forms report deliveries to `spell_deliver()` in `scripts/SpellExecution/`.
Immediate and delayed groups use the same ordered executor. Pull starts movement
at its place in the sequence; it does not wait for that movement to complete.
For example, Strike + Pull + Harm misses enemies still travelling into the tile;
Strike + Pull + Delay + Harm checks the tile again after the delay.

| Delivery | Delayed targeting |
| --- | --- |
| Direct Projectile / individual Beam tick | Follow the hit enemy's skeletal lineage |
| Strike / triggered Rune / Projectile AoE | Reselect the original area at activation |
| Pull | Select the fixed 3x3 region around the original impact at activation |

One room-owned scheduler orders work by due frame and insertion order. Its clock
advances in the gameplay manager's Begin Step and drains in End Step, or when an
immediate delivery needs to run. Pausing freezes gameplay time; entering a room
creates a fresh queue. A destroyed delivery object does not cancel its work.
Permanent enemy/pile destruction cancels work following that enemy identity.
Beam epochs and Effect indices distinguish repeated applications; Projectile
contact and per-Effect records prevent overlap from consuming Pierce repeatedly.

The status registry in `EnemyHelper.gml` defines transfer fields, active counting,
expiry and overlays. Effect callbacks call its apply interface. Existing enemy
fields remain adapters, without a second copy of status state. Skeleton snapshots
carry statuses only; scheduled work remains in the room queue and follows lineage.

Run every `tools/test-*.cjs` script for the automated regression suite. The detailed
architecture, extension rules and manual checklist are in
`notes/spell-execution-refactor.md`.

For native verification, temporarily make `rm_spell_interaction_test` the starting
room in GameMaker, then restore `rm_menu` afterward. Keys 1–6 choose cases, R resets,
P pauses, M moves an enemy into the target tile, and Escape returns to the menu.
This room tests execution, timers and actual Pull movement. Campaign testing is
still required for delivery collisions, Rune arming and the full gameplay UI.

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
