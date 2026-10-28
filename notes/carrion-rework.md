# Carrion death growth and frenzy

Configure `enemies.carrion` in `datafiles/tune.json`:

| Parameter | Code fallback | Meaning |
| --- | --- | --- |
| `hp_gain_per_death_mult` | 0.2 | Standard enemy HP added to both current and maximum HP per qualifying death. With standard HP 150, this grants 30 HP. Negative values clamp to zero. |
| `heal_on_nearby_death_pct` | 15 | Additional healing as a percentage of the newly increased maximum HP. `15` means 15%, clamped to 0–100. Works before, during and after the flight transition; total current HP caps at max HP. |
| `deaths_to_frenzy` | 5 | Nearby deaths required to start the one-time screech-to-flight transition; integer, minimum 1. |
| `frenzy_speed_mult` | 3 | Multiplies Carrion's own base speed once after the screech ends; minimum 1. Frost and Banneret multipliers still compose normally. |
| `death_radius_tiles` | 1 | Nonnegative integer radius, rounded down. Measures differences in columns and lanes between the two enemies' occupied cells. |
| `screech_duration` | 0.5 | Screech duration in seconds, captured on spawn and rounded to simulation frames, with a one-frame minimum. |

Radius 0 includes only the same cell. Radius 1 deliberately includes all nine cells of a 3x3 square. Radius 2 includes 13 cells: the same nine cells plus the four cells two steps away along an axis. Larger radii use `dx*dx + dy*dy <= radius*radius`. Hitbox edges do not extend this range; enemies outside the grid do not qualify.

Each actual combat death is notified once. A living Carrion cannot feed on itself. Individual Swarmers count, and a revived skeletal body can count on its next death. Destroying a bone pile and room cleanup do not notify Carrion. Multiple nearby Carrions track their own counters. Deaths after frenzy still add HP and visual growth without another speed multiplier. Frenzy does not release Stun or Pull. A newly spawned/revived Carrion starts a fresh counter, consistent with the existing ability reset on skeletal revival.

Healing is additional to the current/max HP growth. For example, with standard enemy HP 150 and growth multiplier 0.2, a Carrion at 500/750 HP gains 30 current/max HP and then heals 15% of its new 780 max HP (117), ending at 647/780. Healing uses the existing death radius and notification exclusions, does not revive a dead Carrion, and does not replace the max HP growth.

At the threshold Carrion immediately uses the supplied screech pose and plays `snd_carrion_screech` once. During the transition its own movement speed is zero and it cannot attack the village. Pull continues moving it, and Burn/Frost/Lightning timers and mutation updates continue normally. Attack alarms can become ready, but no hit executes until the transition ends. The existing game pause deactivates enemy instances, freezing the transition alongside their other updates.

After the timer ends Carrion applies its speed multiplier and uses the supplied flight pose for all movement directions. Subsequent nearby deaths grant HP without restarting the screech or multiplying speed again. Sprite origins match the original walk sprite, and `mask_index` stays on the walk sprite to preserve gameplay collision geometry. The supplied PNGs and MP3 are imported byte-for-byte; the sound plays once at its full original 6.84-second duration, including after flight begins.

Rune immunity begins at that same transition to flight; walking and screeching Carrions remain vulnerable. A flying Carrion cannot trigger or consume a Rune, receive its splash/Pull/reaction effects, or receive a previously queued Rune hit that resolves after flight begins. Statuses already applied by Runes remain active, and an existing Pull continues; the immunity blocks new applications rather than cleansing statuses. Strike, Projectile and Beam still work normally.

## Complete change inventory

- `datafiles/tune.json`: Replace the old per-death HP/speed enrage settings with the four parameters above. Existing starting HP, speed, damage and attack timing stay unchanged.
- `objects/obj_carrion/Create_0.gml`: Read and clamp HP growth, death threshold and frenzy multiplier; initialize `nearby_deaths` and `frenzied`. Remove obsolete enrage variables.
- `scripts/EnemyHelper/EnemyHelper.gml`: Add `carrion_death_in_range` to implement the agreed grid shapes. Replace square hitbox overlap and additive speed growth with this range check, standard HP growth, an individual death counter and a one-time speed multiplication. Preserve notification deduplication, pile/dead-observer exclusions, visual scaling, siphon creation and shared movement updates.
- `scripts/EnemyCatalog/EnemyCatalog.gml`: Describe the health growth and permanent frenzy in Carrion's displayed description without hardcoding tunable numbers.
- `tools/test-carrion-growth.cjs`: Execute the real Create event and death/movement helpers. Cover JSON defaults and overrides, wounded current/max HP, threshold and later deaths, notification deduplication, piles/living/distant targets, skeletal revival, dead observers, independent Carrions, simultaneous deaths, exact radius 0/1/2/3 shapes, Frost, Banneret, Stun and Pull.
- `notes/enemy-abilities-implementation.md`: Replace the obsolete per-death speed description with the revised ability and radius rules.
- `notes/carrion-rework.md`: Record tuning, lifecycle semantics, verification and this inventory.

## Screech-to-flight change inventory

- `datafiles/tune.json`: Add only `screech_duration: 0.5`. Preserve the user's current HP-gain and speed-multiplier tuning.
- `objects/obj_carrion/Create_0.gml`: Capture the tuned screech duration in frames, initialize the timer and retain the original walk collision mask.
- `scripts/EnemyHelper/EnemyHelper.gml`: Add `carrion_begin_frenzy` for the immediate pose/sound/timer change and `carrion_update_frenzy` for the timed switch to flight and one-time speed boost. Death notification now starts the transition rather than applying speed immediately. Shared movement returns zero own speed during the screech, while leaving Pull handling intact.
- `objects/obj_carrion/Step_1.gml`: Advance the transition in Begin Step, then skip inherited attacks while screeching. Resume inherited attacks once it finishes.
- `objects/obj_carrion/obj_carrion.yy`: Register the new Begin Step event.
- `sprites/spr_enemy_carrionscreech/` and `sprites/spr_enemy_carrionflight/`: Add one resource file, one composite PNG and one layer PNG per sprite. Each image remains 264x264 with its original transparency, integer origin (122,217) matching the walk sprite and bounds matching visible pixels.
- `sounds/snd_carrion_screech/`: Add the original MP3 and its sound resource, using the existing SFX folder/default audio group, preloaded for the transition, with its source sample rate (24000 Hz) and duration (6.84 seconds).
- `Spell.yyp`: Register the two sprites and one sound without reordering existing resources.
- `tools/asset-sources/carrion-frenzy/manifest.json`: Record supplied filenames, SHA-256 hashes and imported sprite/audio metadata.
- `tools/test-carrion-growth.cjs`: Extend the actual GML tests for the delayed speed boost, frame-exact transition, custom/minimum duration, single sound, continued HP growth, attack suppression, live Pull and status timers, flight sprites, stable mask and Stun/Pull movement after the transition. Pin scenario tuning locally so changing the live HP/speed values does not invalidate those scenario assertions.
- `tools/test-carrion-frenzy-assets.cjs`: Check project registration, event registration, sprite frame/layer references, bounds, origins, audio metadata and original source hashes.
- `notes/enemy-abilities-implementation.md`: Update the ability overview for the screech and flight phase.
- `notes/carrion-rework.md`: Explain the transition, distinguish code fallbacks from editable JSON values, and add this complete inventory.

## Healing and Rune immunity change inventory

- `datafiles/tune.json`: Add `heal_on_nearby_death_pct: 15` under Carrion while preserving existing tuning edits.
- `objects/obj_carrion/Create_0.gml`: Read and clamp the healing percentage; initialize `is_rune_immune` to false so newly spawned/revived Carrions remain vulnerable until flight.
- `scripts/EnemyHelper/EnemyHelper.gml`: Enable Rune immunity when the screech timer finishes, alongside the flight sprite/speed change. On each qualifying death, grow max HP first, calculate percentage healing from that new maximum, then add growth plus healing to current HP with a max HP cap.
- `scripts/SpellExecution/SpellExecution.gml`: Extend the shared eligibility filter to reject Rune spells against enemies with `is_rune_immune`. Existing Swarmer immunity stays intact; trigger, splash, delayed-hit, Pull and reaction paths share this filter.
- `scripts/EnemyCatalog/EnemyCatalog.gml`: Update Carrion's displayed description to explain growth, healing, screech, flight and Rune immunity without hardcoded tuning values.
- `tools/test-carrion-growth.cjs`: Add arithmetic/order tests for extra healing in walking/screeching/flying phases, cap and percentage overrides/clamps, and lifecycle exclusions. Exercise actual Rune hits before/during/after transition, unchanged charges against flying targets, neighboring Rune triggers/splash, queued hits, Pull, Discharge/Combust reactions and other Forms.
- `notes/enemy-abilities-implementation.md`: Add healing and flight-only Rune immunity to the overview.
- `notes/carrion-rework.md`: Document the percentage units, HP calculation example, immunity timing/semantics and this full change inventory.

## Validation

All 37 regression scripts passed using `node tools/run-regressions.cjs`. The suite executes extracted GML with engine mocks; it does not compile or run GameMaker. Native compilation and playtesting remain unverified. In the existing F6 Carrion scenario in `rm_spell_interaction_test`, kill nearby enemies until the threshold and check the screech pose, sound, half-second stop, then permanent flight; repeat while Pull/Frost/Stun are active and pause mid-transition.
