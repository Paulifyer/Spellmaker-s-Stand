# Snap, Combust and Discharge

## Agreed behavior

**Snap** requires active Frost. It deals standard damage times `damage_per_stack_mult` times the number of Frost stacks (maximum three), then consumes all Frost. Damage is calculated while Frost still drops a Frost Ward and contributes to Hex. Consumption clears stack count, slowdown and duration together. No Frost means no damage.

**Combust** damages burning targets. A burning target killed by any direct-damage Effect in that same immediate execution explodes, even when the killing Effect appears before Combust. The compiled execution knows that Combust is present; there is no persistent mark on the enemy. Each Delay boundary starts a separate execution segment, including a Delay tuned to zero seconds. A kill by another delivery/cast, a later segment, or Burn ticks cannot trigger the earlier Combust. A target must be burning at the killing hit and must belong to the delivery's Combust target region/lineage. Adding Fire after an already-lethal hit does not retroactively burn that kill.

Combust explosions damage nearby living eligible enemies, then apply fresh Burn using Combust's own captured tuning. Amplify scales direct damage, explosion damage and the new Burn strength. Explosion damage itself cannot recursively cause more Combust explosions. A nearby enemy that survives the explosion can still explode if a later direct Effect in the same immediate execution kills it while it qualifies as a primary Combust target. Each qualifying lineage explodes at most once per segment.

**Discharge** requires Charged (the stun-immunity phase after Stun), not merely Stunned. Each charged emitter consumes Charged as its queued burst executes. Bursts damage eligible charged and uncharged enemies, including their emitter. A charged enemy struck by a burst reserves its own emission before lethal damage, so it still emits if killed. Every emitter fires once and each lineage receives at most three burst hits per reaction by default. Consuming Charged also ends its stun immunity, removes its contribution to Hex and allows a Lightning Ward to return immediately.

One Discharge occurrence shares its budget across targets of one area delivery. All contacts for that occurrence in a Beam tick share the budget too; the next tick gets a new budget. Separate projectile contacts/deliveries and separate casts have independent reactions. Delayed events retain their originating tick's budget rather than borrowing the current one.

All three support Amplify and Delay. Combust/Discharge also support Effect AoE; Snap does not. Extend Time is incompatible with all three. Form AoE affects initial selection; Effect AoE separately expands bursts. Default bursts cover three columns by three lanes, using existing regional targeting; Effect AoE expands that to five by five. Rune-origin reactions respect Swarmer immunity. Burrowing Moles remain untargetable. Piles retain their real statuses and lineage, so they can participate if eligible.

All direct damage follows `deal_damage`, including live ward reduction and Hex. Beam direct damage/burst damage uses the existing captured Beam damage multiplier per tick. Burn follows the existing Fire convention: it is a timed per-second status, not repeated direct Beam damage. No bespoke explosion/chain artwork is added; damage uses existing hit feedback. The three glyphs use their supplied PNG icons in crafting and unlock previews.

## JSON tuning

Edit `datafiles/tune.json` under `effects`:

```json
"snap": {
  "cost": 15,
  "damage_per_stack_mult": 1.2
},
"combust": {
  "cost": 15,
  "damage_mult": 1,
  "explosion_damage_mult": 1,
  "radius_tiles": 1,
  "area_radius_tiles": 2,
  "burn_duration": 3,
  "burn_damage_mult": 0.4
},
"discharge": {
  "cost": 20,
  "damage_mult": 1,
  "radius_tiles": 1,
  "area_radius_tiles": 2,
  "max_hits_per_enemy": 3
}
```

Damage multipliers use `combat.base_dmg`. Duration is seconds. Radius 1 is 3x3; radius 2 is 5x5. Damage/duration must be non-negative numbers, radii non-negative integers, and the hit limit a positive integer. Numeric execution parameters are validated and captured during compilation, so later tuning changes cannot alter queued effects or ongoing reactions. Costs use the existing glyph initialization/tuning path; restart the game after changing the JSON.

Active and draft level JSON files unlock `combust` at level 3, `snap` at level 4 and `discharge` at level 7. Existing cumulative unlock behavior supplies them to later levels and direct level entry.

## Architecture

The existing compiler creates each Effect occurrence's immutable parameters, modifier results and `execution_segment`. The existing room-owned scheduler still owns delivery order, Delay and lifetime. Events within a segment share a small execution context for Combust attribution and burst work. Secondary bursts use an iterative work list drained during the triggering Effect, before proceeding to subsequent Effects. No recursive damage callbacks or enemy-owned delayed queues are introduced.

Reaction objects hold explicit IDs, emitter sets and hit counts keyed by stable enemy lineage. They are separate from cast contact records, so a spell's initial contact cannot accidentally suppress its secondary burst. Frost gains an explicit capped stack count in the existing status registry; capture, expiry, consumption and skeletal transfer use that same registry. The existing slowdown cap remains 60%.

## Every changed file

| File | Change and purpose |
| --- | --- |
| `scripts/EnemyHelper/EnemyHelper.gml` | Register/transfer Frost stack count, cap applications at three, clear all consumed/expired Frost fields together, and distinguish/consume Charged without clearing an active Stun. |
| `scripts/SpellExecution/SpellExecution.gml` | Shared damage scaling and direct-damage entry point; per-segment Combust context; nonrecursive burst work list; lineage-based reaction IDs, emitters and hit caps; existing immunity-aware burst targeting; shared per-tick Beam reaction budgets; attach contexts to scheduled events. |
| `scripts/EffectGlyphs/EffectGlyphs.gml` | Add Snap/Combust/Discharge callbacks, descriptions and tunable costs. Route Harm through the direct-damage entry point so same-segment kills can trigger Combust. |
| `scripts/SpellCatalogScripts/SpellCatalogScripts.gml` | Register all three glyphs and their palette order. Capture/validate new parameters, add per-Effect AoE flags, and identify execution segments separated by Delay. |
| `scripts/ModifierGlyphs/ModifierGlyphs.gml` | Permit Amplify on the three new glyphs; permit AoE on Combust/Discharge; distinguish Form AoE from Effect AoE instead of setting the whole spell's area flag in both cases. |
| `scripts/GameplayScripts/GameplayScripts.gml` | Support temporary glyph-name labels in unlock previews when no sprite exists. Existing glyphs still use their sprites. |
| `datafiles/tune.json` | Add the three tuning blocks above without changing existing balance values. |
| `datafiles/level.json`, `notes/level-campaign.draft.json` | Add Combust/Snap/Discharge unlocks at levels 3/4/7. |
| `objects/obj_spellbook/Draw_64.gml` | Reduce Effect row spacing to fit nine Effects above the existing Modifier palette. |
| `objects/obj_spell_test_driver/Create_0.gml`, `Step_0.gml`, `Draw_64.gml` | Add native cases 7–9 and their keyboard controls/descriptions while retaining the prior cases. |
| `tools/gml-test-utils.cjs` | Load the new status inspection/consumption helpers into status tests. |
| `tools/construction-test-context.cjs` | Add new effect catalog entries and compatibility metadata to shared tests. |
| `tools/execution-test-context.cjs` | Execute the new callbacks and movement helper; initialize explicit Frost counts; supply engine sprite/animation calls and state required by the current Forms; supply region/coordinate helpers. |
| `tools/payoff-test-context.cjs` | Add focused payoff harness using actual damage, effect, status and execution helpers with engine calls mocked. |
| `tools/test-payoff-primitives.cjs` | Check stack limits/transfer/consumption, Charged phases and bounded lineage-based identities. |
| `tools/test-snap.cjs` | Check 0–3 stacks, ward/Hex timing, movement restoration, Amplify, Delay, captured values and Beam scaling. |
| `tools/test-combust.cjs` | Check kills before/after Combust, burning eligibility, Delay/Burn/cast isolation, AoE, Amplify and nonrecursive explosions. |
| `tools/test-discharge.cjs` | Check Charged consumption, dense groups, hit caps, lethal emitters, area modifiers, immunity and Beam tick budgets. |
| `tools/test-payoff-integration.cjs` | Check all Forms, repeated consumers, zero-second Delay boundaries, area overlaps, skeletal transfer, captured tuning, modifier restrictions, invalid tuning and unlock previews. |
| `tools/test-mana-preview.cjs` | Supply array membership to the isolated compiler test now that compilation tracks Delay boundaries. |
| `tools/test-pierce.cjs` | Adapt checks to the current projectile impact-animation lifetime: verify impact state, then destruction after animation, while retaining contact/effect assertions. |
| `tools/test-spell-editor.cjs` | Exercise all nine palette effects and check that the third row fits; retain crafting/slot tests. |
| `objects/Player/Step_0.gml` | Separately approved restoration of available-slot input limits and release of a channel whose slot becomes locked. |
| `objects/Player/Draw_64.gml` | Separately approved restoration of locked-slot labels/detail hiding and the available-key hint, preserving current HUD positions, sizes, font and spell names. |
| `tools/test-spell-slot-progression.cjs` | Adapt HUD test stubs to the current font/name drawing and mana-recovery syntax; preserve locked-slot, channel release and hint assertions. |
| `notes/level-campaign-import.md`, `notes/spell-execution-refactor.md` | Replace obsolete missing-glyph/propagation notes with current implementation guidance. |
| `notes/payoff-glyphs.md` | This behavior, tuning, architecture, inventory and verification guide. |

### Supplied glyph icon import on main

- `sprites/spr_glyph_snap/`, `sprites/spr_glyph_combust/`, `sprites/spr_glyph_discharge/`: each contains one `.yy` sprite resource, a composite PNG and its layer PNG. All are 264x264 RGBA with a single frame, centered integer origins (132,132), and the existing Glyphs folder/texture settings. The source PNG bytes and transparency are preserved.
- `Spell.yyp`: register the three sprite resources once each.
- `scripts/EffectGlyphs/EffectGlyphs.gml`: set each new Effect's `icon` to its corresponding sprite, replacing its temporary label automatically wherever glyph icons are displayed.
- `tools/asset-sources/payoff-glyphs/`: keep the three original PNG files and `manifest.json` recording canonical Drive source IDs/URLs.
- `tools/import-payoff-glyphs.cjs`: reproducible importer based on the existing Fire glyph sprite format. Reuses frame/layer/key IDs when rerun and inserts only missing project registrations.
- `tools/test-payoff-glyph-assets.cjs`: check registration, effect bindings, frame/layer references, integer origins, source hashes and actual transparent/opaque pixels.
- `notes/payoff-glyphs.md`: update the artwork status and add this import inventory.

Source folder: https://drive.google.com/drive/folders/1EH65FOOAtnWcNEBBtXoz1V5vlhVsp-Is

## Verification and native playtest

Run `node tools/run-regressions.cjs` for all simulated-engine/static checks. GameMaker compilation and native visual playtesting have not been performed here.

Open `rm_spell_interaction_test` and press 7 (Snap on a Frost-Warded enemy with three stacks), 8 (Harm kills before Combust and ignites a neighbor), or 9 (charged chain with consumed statuses). R restarts. Existing cases 1–6 and F1–F6 remain available.

In campaign play, check levels 3/4/7 for unlocks and the supplied glyph icons. Try `Ice + Snap`, `Fire + Harm + Combust`, `Combust + Delay + Harm`, and `Lightning + Delay + Discharge` (the Delay must allow Stun to finish). Compare Form AoE against Effect AoE, verify narrowed/widened burst coverage and inspect the restored fourth-slot key hint at level 5 onward.
