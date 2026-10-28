# Enemy ability implementation

## Behavior

- Mutation entries accept a string or array. Skeletal, Banneret and one elemental ward can combine. Duplicate keys, unknown keys and multiple wards are rejected; costs add together.
- Banneret supplies 30% haste in a 3x3 area. Sources do not buff themselves, overlapping sources do not stack, and burrowing Moles provide no aura or visible banner. Piles neither give nor receive the aura. Revived enemies retain Banneret/wards and lose Skeletal.
- Wards reduce damage by 50% while their matching status is absent. Fire uses Burn, Frost uses Frost, Lightning uses Stun or Charged. Protection and visibility read the same live status. Wards return after expiry. Ward body tint is removed; skeletal gray remains.
- Supplied ward animations and the back-mounted banner are imported. Brutes use narrow wards; Siege Beasts and Carrion use wide wards. The first animation frame appears once, then the remaining frames loop at 5 FPS.
- Swarmers cannot trigger or receive any Rune delivery, including Area, delayed effects and Pull. Other Forms remain valid.
- Siege Beasts deal one immediate doubled arrival hit if charge survives. They are immune to displacement while `charge_active` is true. Pull is rejected without stopping the path or interrupting the charge. Stun permanently interrupts charge and immediately restores displacement eligibility, so Lightning followed by Pull works if the stun succeeds. Normal attacks resolve after scheduled spell effects and use a full windup, paused while stunned. A barricade interruption hook is ready for future Earth integration.
- Moles show their actual path destination while underground, snap to it on emergence, and hide the marker on emergence/death.
- Carrion gains +20% standard enemy HP to current and maximum health per nearby combat death, retaining visual growth. The fifth nearby death permanently multiplies its speed by 3, once per life; later deaths continue granting HP. All values and the death radius are tunable. Radius 1 covers a 3x3 square; radius 2 covers 13 cells including adjacent diagonals; larger radii use circular distance in columns/lanes. Individual Swarmers and revived bodies count; pile destruction and cleanup do not. See `notes/carrion-rework.md` for tuning and the full change inventory.

## Complete code/file inventory

Paths below are repository-relative. Imported animation frames are grouped by sprite rather than listing each duplicated composite/layer PNG.

| Files | Changes and purpose |
| --- | --- |
| `scripts/MutationScripts/MutationScripts.gml` | Normalize/validate mutation lists, sum costs, compose lifecycle hooks, retain non-Skeletal components on revival; dynamic ward protection/selection/drawing; Banneret source checks, nonstacking aura and banner drawing. |
| `scripts/WaveTypes/WaveTypes.gml`, `scripts/WaveValidation/WaveValidation.gml` | Accept lists, add component costs, validate mutation configuration; update parameter documentation. |
| `objects/obj_wave_manager/Alarm_0.gml` | Apply mutation sets on spawn, retain speed variation for both Siege speeds, initialize Mole destinations after assigning paths. |
| `objects/obj_enemy_parent/Create_0.gml` | Initialize mutation keys, pile/death flags, ward shape and animation state. |
| `objects/obj_enemy_parent/Step_0.gml` | Pass concrete instance IDs to status/movement/mutation lifecycle helpers. |
| `objects/obj_enemy_parent/Step_2.gml` | Notify combat death once before mutation/death handling; dispatch hooks on the concrete instance. |
| `objects/obj_enemy_parent/Destroy_0.gml` | Preserve wave counts only for an actual Skeletal lineage transition. |
| `objects/obj_enemy_parent/Draw_0.gml` | Draw supplied banner behind body and ward overlay using live protection state. |
| `objects/obj_bonepile/Create_0.gml` | Explicit pile flag for aura/death exclusions. |
| `objects/obj_revive_manager/Alarm_1.gml` | Restore retained mutation components and initialize revived Mole markers after path restoration. |
| `objects/obj_spellbook/Draw_64.gml` | Describe combined mutation sets. |
| `scripts/GameplayScripts/GameplayScripts.gml` | Apply ward reduction at damage time. |
| `scripts/SpellExecution/SpellExecution.gml` | Shared target eligibility excludes Swarmers from Rune trigger and effect application, including delayed deliveries. |
| `scripts/EffectGlyphs/EffectGlyphs.gml` | Apply the same eligibility rule to Pull's regional selection. |
| `scripts/EnemyHelper/EnemyHelper.gml` | Compose haste with Frost/movement; interrupt Siege charge when stun starts; resolve Siege attacks; initialize Mole markers; notify nearby Carrion of actual combat deaths. |
| `objects/obj_gameplay_manager/Step_2.gml` | Resolve Siege attacks after spell scheduler flush. |
| `objects/obj_siege_beast/Create_0.gml`, `Step_0.gml`, new `Step_1.gml`, `obj_siege_beast.yy` | Initialize charge/windup and wide ward; handle charge interruption; override inherited Begin Step attacks so the shared attack resolver owns timing; register event. |
| `objects/obj_mole/Create_0.gml`, `Step_1.gml`, `Draw_0.gml` | Track emergence/marker, stop exactly at destination and draw underground destination cue. |
| `objects/obj_carrion/Create_0.gml`, `Step_0.gml` | Use wide wards; correct `enrange` spelling; replace proximity polling with explicit combat death notifications; remove obsolete polling state. |
| `datafiles/tune.json` | Configure Banneret multiplier/radius and Siege arrival damage multiplier. |
| `sprites/spr_ward_{fire,frost,lightning}_{narrow,wide}/`, `sprites/spr_banneret_speed/`, `Spell.yyp` | Add seven sprite resources, metadata, frame/layer PNGs and project registrations. |
| `tools/asset-sources/enemy-modifiers/` | Preserve supplied PNG/GIF artwork, source manifest and import metadata. |
| `tools/import-enemy-visuals.cjs` | Reproducible importer preserving source pixels, alpha bounds, frame ordering and playback metadata. |
| `tools/enemy-test-context.cjs` | Mutation-focused harness using actual extracted GML helpers. |
| `tools/construction-test-context.cjs`, `execution-test-context.cjs`, `gml-test-utils.cjs` | Supply new lifecycle/eligibility dependencies to existing simulated-engine tests. |
| `tools/test-enemy-mutations.cjs`, `test-enemy-wards.cjs`, `test-enemy-banner.cjs`, `test-enemy-visual-assets.cjs` | Check mutation syntax/costs/composition, ward damage/status ordering, aura rules and supplied asset integrity. |
| `tools/test-swarmer-rune-immunity.cjs`, `test-siege-beast.cjs`, `test-mole-marker.cjs`, `test-carrion-growth.cjs` | Check each enemy ability, timing, exclusions and lifecycle behavior. |
| `tools/test-spell-editor.cjs`, `test-spell-timing-costs.cjs`, `test-status-interactions.cjs` | Adapt existing fixtures to combined descriptions, target eligibility and charge interruption dependencies. |
| `objects/obj_spell_test_driver/Create_0.gml`, `Step_0.gml`, `Draw_64.gml` | Preserve original spell tests and add F1–F6 native enemy scenarios, T status, K kill, R restart and control instructions. |
| `tools/run-regressions.cjs` | Run every regression script and report failures together. |
| `notes/level-campaign.draft.json`, `notes/level-campaign-import.md` | Replace reserved combined mutation key with supported array syntax and update activation prerequisites. |
| `notes/enemy-abilities-implementation.md` | This behavior, file inventory and validation guide. |

## Verification and native checks

Run `node tools/run-regressions.cjs` for all simulated-engine/static checks. These execute extracted GML helpers where practical, but do not replace GameMaker compilation or rendering.

Open `rm_spell_interaction_test` in GameMaker. Existing 1–6 cases remain available. F1 wards, F2 Banner/Skeletal revival, F3 Rune immunity, F4 Siege timing, F5 underground Mole banner/marker, F6 Carrion death growth. T applies a three-second status to the tracked enemy, K kills it, R restarts, P pauses. The F3 scenario invokes the delivery boundary directly; campaign Rune arming/collision still needs a playtest.

GameMaker compilation and visual playtesting have not been performed here. Check overlay placement across animation frames and movement directions, narrow Brutes, wide Siege/Carrion, banner disappearance underground, ward disappearance/reappearance, and mixed mutation revival. Actual barricade collision remains future Earth work.

## Charging displacement immunity update

- `scripts/EnemyHelper/EnemyHelper.gml`: add `enemy_can_be_displaced`, reading the live charge flag. Apply it in `enemy_begin_pull` alongside the existing Pull immunity/already-pulled checks. Future Force/knockback implementations should use this same predicate.
- `tools/test-siege-displacement.cjs`: execute the actual Pull helper and ordered spell delivery to check charging immunity, eligibility after impact/interruption, Lightning/Pull ordering, failed stun, delayed activation, ordinary enemies and existing Pull immunity.
- `notes/enemy-abilities-implementation.md`: document these rules and the complete change inventory.
