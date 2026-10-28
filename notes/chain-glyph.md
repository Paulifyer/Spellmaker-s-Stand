# Chain and Form-modifier interaction costs

## Behavior

Chain is a stackable Form modifier usable with Projectile, Strike, Rune and Beam. Each glyph adds two additional hops by default. Every fresh direct Form hit starts its own sequential allowance; neither chain hops nor AoE splash victims create new independent allowances. Hops execute immediately, while each hop's Effects retain their existing written order and Delay timing.

Each hop searches the existing regional grid within two columns/lanes of the last hit position (a 5x5 area). Among living, targetable, unvisited candidates, choose the closest by squared world-space distance. Exact ties use the lower stable lineage ID. Recompute the search from each newly hit target. Stop when the hop count is exhausted or no candidate remains. Hit positions are captured before Effects run, allowing killed or subsequently moved targets to supply an onward hop/link.

The initial hit and every chained impact apply the full spell payload. Form AoE produces a local 3x3 impact around each hop. Original Beam AoE still widens the primary Beam to adjacent lanes; a chained Beam AoE impact is a local burst. Effect AoE on Combust/Discharge remains independent. Pull retains its normal fixed area and current charge-immunity checks.

An initial Strike/area delivery uses one seed (the nearest fresh enemy to its impact center), not a chain per splash victim. A Rune uses its triggering enemy. Empty initial areas can execute their existing location payload but cannot invent a chain root.

Visited state belongs to one cast and resets for each Beam damage tick. Initial and hop splash regions reserve their eligible occupants so they cannot be selected as subsequent chain centers even when a conditional Effect does nothing or another Effect is delayed. Payload application deduplication remains keyed by Effect occurrence, Beam epoch and lineage. Delayed location effects reselect at each impact's fixed anchor; direct effects keep following lineage. Discharge retains its own reaction budgets and is not converted into recursive Chain traversal.

Beam gathers/reserves all its primary targets before delivering them, preventing an earlier chain from selecting a later primary as a hop. Each fresh primary then gets its own allowance. A primary already affected by an earlier hop's AoE is skipped under normal same-spell overlap rules. Separate casts and later Beam ticks may hit the same enemies again. Projectile Pierce still ignores already-affected contacts without consuming another penetration.

Dead/untargetable enemies cannot be new hop targets. Rune-origin chains cannot trigger on or affect Swarmers. Skeletal bodies, spawn gaps, piles and revived bodies share lineage, so replacing a body does not reset same-cast eligibility.

## JSON tuning

In `datafiles/tune.json`, under `modifiers`:

```json
"chain": {
  "cost": 20,
  "hops_per_stack": 2,
  "range_radius_tiles": 2,
  "visual_duration": 0.15
},
"interaction_penalty": {
  "cost_per_pair": 10,
  "penalized_modifiers": ["area", "pierce", "chain"]
}
```

Radius 2 means 5x5; radius 1 means 3x3. Hops and radius must be non-negative integers; visual duration and pair cost must be non-negative numbers. A zero hop count disables traversal; zero visual duration hides links. The penalty list must contain unique, non-empty string IDs. Unlisted Form modifiers neither receive nor increase the penalty. Future IDs may be prepared in the list before their glyph is registered. Effect attachments never participate, even when their ID is listed.

Count every unordered pair of listed Form attachments whose IDs differ. Equal-type stacks never pair with each other, but every stack pairs with each attachment of another listed type:

| Form attachments | Different-type pairs | Extra mana at 10/pair |
| --- | ---: | ---: |
| Pierce x3 | 0 | 0 |
| Pierce + Chain | 1 | 10 |
| Pierce + Chain + AoE | 3 | 30 |
| Pierce x2 + Chain | 2 | 20 |
| Pierce x2 + Chain x2 | 4 | 40 |

The compiler adds the penalty to normal glyph costs and retains it as `form_modifier_penalty`. The existing mana preview, Start checks and actual casting all use that compiler. Amplify's existing Effect-stack surcharge is unchanged. Hops, range, visual duration and cost are captured for the compiled spell; changing tuning does not rewrite already-created casts. Restart after editing JSON.

Chain unlocks at level 5 in both active and draft level JSON files.

## Visuals

Links reuse `spr_beam`, rotated and stretched between recorded hit positions. Origin compensation aligns the sprite's centerline endpoints. Animation follows the sprite's configured playback rate and the room-owned combat clock; opacity starts at Beam's 0.5 and fades over the configured duration. Each link copies the spell's resolved blended colour. The original ordered half-blending rule is shared through `spell_effect_colour`, used by both real casts and native test plans.

Links live in the combat state rather than on the projectile. Destroying a projectile/Rune does not remove them early. Pausing freezes animation/fade; expired records are pruned during active End Step; entering a new room starts a new combat state. World Draw End renders the links over the battlefield.

The supplied Chain icon is preserved byte-for-byte from the shared Drive Glyphs folder, with 264x264 RGBA pixels, one frame and centered integer origins (132,132).

## Every changed file

| File | Change and purpose |
| --- | --- |
| `scripts/TuneScript/TuneScript.gml` | Add `tune_setting` for raw array/string settings with validation at their consumer; retain existing numeric tuning behavior. |
| `scripts/SpellCatalogScripts/SpellCatalogScripts.gml` | Add explicit-list pair pricing, captured penalty/hop/range/visual parameters and validation; register Chain/order; share the existing colour blend helper. |
| `scripts/ModifierGlyphs/ModifierGlyphs.gml` | Add stackable Form-only Chain, metadata, cost, icon and tunable hop contribution. |
| `scripts/SpellExecution/SpellExecution.gml` | Separate payload scheduling from Chain orchestration; add nearest/visited/root-reservation helpers, iterative hops, hop anchor/area policies and link records; account for forced local Beam AoE in Combust scopes; draw/prune links using the combat clock. |
| `scripts/FormGlyphs/FormGlyphs.gml` | Gather and reserve Beam primary targets before delivering them, then retain normal per-lane Pierce selection and damage scaling. Consume Projectile penetration only when delivery is accepted, including location-only overlapping Chain/AoE payloads. |
| `objects/obj_spells/Create_0.gml` | Call the shared colour helper instead of duplicating the same blend loop. |
| `objects/obj_gameplay_manager/Draw_73.gml`, `obj_gameplay_manager.yy` | Add/register World Draw End rendering for room-owned links. |
| `objects/obj_gameplay_manager/Step_2.gml` | Prune expired link records after active combat resolution. |
| `objects/obj_spell_test_driver/Create_0.gml`, `Step_0.gml`, `Draw_64.gml` | Add Q/W/E native scenarios for mixed-colour Chain, AoE overlap and actual Beam/Pierce ticks; use shared cast colours; provide concrete Projectile impact roots for new cases. |
| `datafiles/tune.json` | Add the Chain block and explicit global interaction-penalty block. |
| `datafiles/level.json`, `notes/level-campaign.draft.json` | Unlock Chain at level 5. |
| `Spell.yyp` | Register the Chain sprite. |
| `sprites/spr_glyph_chain/` | Add sprite metadata plus composite/layer PNG copies with preserved source pixels and integer origins. |
| `tools/asset-sources/chain-glyph/` | Store original PNG and canonical Drive source manifest. |
| `tools/import-payoff-glyphs.cjs` | Accept an optional manifest path, reusing the verified glyph importer for Chain without duplicating import code. |
| `tools/construction-test-context.cjs` | Add Chain metadata/callbacks and new compiler dependencies/numeric operations in the shared harness. |
| `tools/execution-test-context.cjs` | Load the shared colour helper alongside payload and casting helpers. |
| `tools/test-form-interaction-cost.cjs` | Check pair counting, stacks, order independence, explicit/custom/empty JSON lists, Effect exclusion, cost preview/Start and invalid settings. |
| `tools/test-chain.cjs` | Check sequential traversal, range/ties, fresh Pierce/Beam allowances, AoE deduplication, kills, lineage, immunity and Delay. |
| `tools/test-chain-visuals.cjs` | Check Beam rendering, captured colour, endpoint alignment, animation/fade, source destruction, pause, expiry and room reset. |
| `tools/test-chain-integration.cjs` | Check all Forms, local Beam AoE, delayed anchors/lineage, payoff glyphs, captured tuning, empty seeds, actual mana charging, validation, colour helper and unlocks. |
| `tools/test-mana-preview.cjs` | Load/provide the new compiler's penalty/tuning dependencies in the isolated harness. |
| `tools/test-spell-compilation.cjs` | Keep the tuning-change test's numeric doubling while preserving new array settings. |
| `tools/test-spell-timing-costs.cjs` | Update its creation-event slice boundary to the shared colour call, retaining its original cast/modifier timing checks. |
| `tools/test-payoff-glyph-assets.cjs` | Extend source-hash/transparency/frame/origin/registration checks to the Chain modifier icon. |
| `tools/test-gamemaker-assets.cjs` | Verify the manager's new Draw End event and rendering call. |
| `notes/level-campaign-import.md`, `notes/spell-execution-refactor.md` | Update Chain implementation/progression status and architecture guidance. |
| `notes/chain-glyph.md` | This tuning, behavior, complete inventory and verification guide. |

## Verification

Run `node tools/run-regressions.cjs`. These tests execute extracted GML with engine calls mocked and include static asset checks. GameMaker compilation and native visual playtesting remain unverified here.

Open `rm_spell_interaction_test`: Q starts a two-hop Fire/Ice chain, W tests AoE overlap, and E runs Beam + Pierce + Chain. R restarts and P pauses. Existing numbered/F-key cases remain available. In campaign play, check the level 5 unlock, stacking, the mana bar/Start limits with listed versus excluded modifiers, mixed spell colours and link placement across lanes.
