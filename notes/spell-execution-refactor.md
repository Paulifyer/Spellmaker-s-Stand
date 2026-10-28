# Spell execution refactor

## Data flow

1. `compile_spell(loadout)` calculates cost, modifiers and immutable-by-convention
   Effect groups. Each group has an occurrence index, captured tuning parameters,
   target policy, strength, duration bonus and cumulative delay.
2. A cast receives a unique ID. Its delivery instance holds contact/application
   records, while retaining the compiled plan without mutating glyph definitions.
3. Projectile contacts, Beam ticks, Strike landing and Rune triggering call
   `spell_deliver`. Each accepted delivery receives its own ID.
4. Every group is placed in the room scheduler in sequence order. Due groups run
   through `combat_execute_event`; future groups retain their due frame.
5. Targeted applications deduplicate by Effect index, Beam epoch and enemy lineage.
   Shared records belong to one cast, so different casts remain independent.

## Ordering and targeting

Pull/Harm and Harm/Pull execute in their written order. Pull begins motion without
blocking execution. Delay is measured from delivery time, not from when Pull ends.
The scheduler handles location and enemy applications together, so earlier due work
precedes a newly delivered instant Effect on the same frame. Ties use unique order
numbers. Reentrant deliveries wait for the current drain instead of recursively
reordering previously queued work.

Direct Projectile and Beam groups follow a stable lineage reference. Strike,
triggered Rune and Projectile AoE groups select occupants of the original area at
activation time. Pull selects its fixed 3x3 region, regardless of Form AoE. A target
must exist and be targetable when an enemy application executes.

Projectile hit records live for the cast. Beam contact records reset each quarter
second and receive a new epoch. A delayed old tick cannot reserve contacts in the
new epoch. Different Effect occurrences and different Beam ticks can therefore
queue independently without effect-object-reference suppression.

## Lifecycle and pause

The gameplay manager owns the queue and clock. Begin Step advances the clock;
End Step drains it. Immediate deliveries may also drain already-due work. Pausing
prevents clock advancement and scheduled execution. A new room manager starts a new
queue. No queue is attached to a projectile, Rune or enemy instance.

Skeleton death marks lineage as in the spawn gap. Enemy-following work remains
queued even if due; location work continues normally. Pile appearance binds that
same identity and flushes its overdue applications. Revival binds the replacement
without resetting scheduled due frames. Permanent destruction marks the identity
dead, causing its remaining targeted work to be discarded.

Status snapshots are separate from scheduled work. The registry drives capture,
restore, activity counting, overlays and expiry. Burn does not damage an invisible
gap target, but duration continues. Lightning uses the same transition clock both
live and in the gap. Existing named fields remain the authoritative storage used
by enemy abilities; no parallel status bag needs synchronization.

## Extending the system

- Add Form delivery behavior through `spell_deliver`, not a second effect loop.
- A location Effect declares `delivery_kind = "location"`; other Effects inherit
  the Form's targeting policy. Keep compatibility metadata aligned with the design.
- Capture new numeric parameters during compilation, not from a disappearing
  projectile or mutable tuning data when a delayed callback finally runs.
- Register new status fields/counting/display metadata and implement its application
  rule in the status interface. Add transfer, expiry and refresh tests.
- Discharge uses explicit reaction IDs, lineage-based hit budgets and an iterative
  burst work list. Combust attribution belongs to one delivery/Delay segment. See
  `payoff-glyphs.md`. Chain uses a separate iterative delivery traversal, stable
  lineage visits and the existing payload scheduler; see `chain-glyph.md`. Future
  Link propagation should preserve these identities rather than use callback identity.
- Keep compiled plans read-only; mutable delivery/contact state belongs to a cast.

## Native test room

`rm_spell_interaction_test` is isolated from campaign discovery (`rm_level_*`). It
does not replace the default starting room. Temporarily put it first in Room Order
to launch it, then restore `rm_menu` after testing.

| Key | Check |
| --- | --- |
| 1 | Immediate Strike/Pull/Harm: nearby enemy moves in but is missed by immediate Harm |
| 2 | Delayed Strike: enemy pulled into the tile is hit when Harm activates |
| 3 | Triggered Rune policy: delayed region selection at the trigger tile |
| 4 | Projectile AoE policy: use M to move the enemy into the area before delayed Harm |
| 5 | Two Beam deliveries: independent delayed hits 0.25 seconds apart |
| 6 | Skeletal direct hit: queued Harm follows the pile and prevents revival |
| R / P / M / Escape | Reset / pause / move into tile / return to menu |

The room uses the actual executor, status updates and Pull movement. Deliveries are
injected deliberately, so campaign checks remain necessary for sprite collisions,
Rune arming, channel keys, mana/cooldowns and room transitions. Native compilation
and playtesting have not been performed by the automated JavaScript harness.

## Automated checks

Run all `tools/test-*.cjs` scripts. They exercise the actual GML functions through
bounded syntax translation and mocked engine calls, not a separate spell engine.
`spell-execution-contracts.cjs` records the approved policies and is executed by
`test-spell-execution.cjs`. Asset checks verify registration, event file references,
default starting room, duplicate function names and obsolete-path removal.

## Complete change inventory

| Files | Change |
| --- | --- |
| `scripts/SpellCatalogScripts/SpellCatalogScripts.gml` | Shared cost/modifier compiler, captured tuning parameters, cast/delivery IDs, complete compiled snapshots; removed separate hit/impact scheduling loops |
| `scripts/SpellbookHelperScripts/SpellbookHelperScripts.gml` | Mana preview calls the shared compiler |
| `scripts/SpellExecution/SpellExecution.gml`, `.yy` | New registered ordered executor, shared queue/clock, target policies, application records and lineage flush |
| `scripts/FormGlyphs/FormGlyphs.gml` | All four Forms report deliveries; Beam epochs distinguish ticks; Rune no longer mutates a shared sprite definition |
| `scripts/EffectGlyphs/EffectGlyphs.gml` | Status interface calls, location-delivery metadata, captured parameter use; Pull remains fixed-area |
| `scripts/EnemyHelper/EnemyHelper.gml` | Status registry and lifecycle, automatic initialization, stable lineage creation/binding |
| `scripts/GameplayScripts/GameplayScripts.gml` | Hex counts active statuses through the registry |
| `scripts/MutationScripts/MutationScripts.gml` | Skeleton snapshots use status interface; gap marks stable lineage; removed copied per-enemy scheduling queues |
| `objects/obj_spells/Create_0.gml` | Uses compiled values once; initializes cast-owned records; removed duplicate modifier/delay calculation |
| `objects/obj_enemy_parent/Create_0.gml` | Initializes registered statuses and lineage, removes enemy delay queue |
| `objects/obj_enemy_parent/Step_0.gml` | Calls shared status advancement; removes enemy scheduler |
| `objects/obj_enemy_parent/Draw_0.gml` | Registry-driven status overlays, including charged Lightning |
| `objects/obj_enemy_parent/Destroy_0.gml` | Cancels lineage-following work on permanent death |
| `objects/obj_revive_manager/Alarm_0.gml`, `Alarm_1.gml` | Bind pile/revived enemy to lineage; flush overdue work on appearance; preserve status state and replacement count |
| `objects/obj_gameplay_manager/Create_0.gml`, `Step_0.gml` | Initialize room execution state; remove old impact queue |
| `objects/obj_gameplay_manager/Step_1.gml`, `Step_2.gml`, `obj_gameplay_manager.yy` | Register Begin/End Step clock and flush events |
| `objects/obj_spell_test_driver/Create_0.gml`, `Step_0.gml`, `Draw_64.gml`, `.yy` | Native test scenarios, controls, queue/HP display and manager inheritance |
| `objects/obj_spell_test_enemy/Create_0.gml`, `Step_0.gml`, `.yy` | Stationary native status/Pull target with pause support |
| `rooms/rm_spell_interaction_test/rm_spell_interaction_test.yy` | Isolated native test room |
| `Spell.yyp` | Register executor and test assets; preserve normal starting room |
| `tools/gml-test-utils.cjs` | Shared extraction/status loaders for actual GML tests |
| `tools/construction-test-context.cjs` | Real modifier metadata/callbacks and compiler loading |
| `tools/execution-test-context.cjs` | Integrated mock-engine harness for actual executor, Forms and Effects |
| `tools/spell-execution-contracts.cjs` | Approved behavioral contract assertions |
| `tools/test-combat-identities.cjs` | Cast/delivery uniqueness and skeletal lineage tests |
| `tools/test-status-lifecycle.cjs` | Status application, expiry, counting and registry transfer tests |
| `tools/test-spell-compilation.cjs` | Shared costs, independent compiled plans and captured parameter tests |
| `tools/test-spell-execution.cjs` | All target policies, order, pause/reset, Beam ticks, consumed Rune and cancellation tests |
| `tools/test-gamemaker-assets.cjs` | Project/asset/event registration and obsolete-path checks |
| `tools/test-delay.cjs`, `test-pierce.cjs`, `test-skeletal-status.cjs` | Migrated prior regression cases to the unified runtime |
| `tools/test-glyph-restrictions.cjs`, `test-mana-preview.cjs`, `test-spell-timing-costs.cjs`, `test-status-interactions.cjs` | Adapted existing tests to shared compilation, statuses and captured parameters |
| `README.md`, `notes/spell-execution-contract.md`, this document | Configuration/architecture documentation, approved contracts, native test instructions and change inventory |
