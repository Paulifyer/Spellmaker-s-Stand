# Carrion death growth and frenzy

Configure `enemies.carrion` in `datafiles/tune.json`:

| Parameter | Default | Meaning |
| --- | --- | --- |
| `hp_gain_per_death_mult` | 0.2 | Standard enemy HP added to both current and maximum HP per qualifying death. With standard HP 150, this grants 30 HP. Negative values clamp to zero. |
| `deaths_to_frenzy` | 5 | Nearby deaths required for the one-time speed boost; integer, minimum 1. |
| `frenzy_speed_mult` | 3 | Multiplies Carrion's own base speed once when the threshold is reached; minimum 1. Frost and Banneret multipliers still compose normally. |
| `death_radius_tiles` | 1 | Nonnegative integer radius, rounded down. Measures differences in columns and lanes between the two enemies' occupied cells. |

Radius 0 includes only the same cell. Radius 1 deliberately includes all nine cells of a 3x3 square. Radius 2 includes 13 cells: the same nine cells plus the four cells two steps away along an axis. Larger radii use `dx*dx + dy*dy <= radius*radius`. Hitbox edges do not extend this range; enemies outside the grid do not qualify.

Each actual combat death is notified once. A living Carrion cannot feed on itself. Individual Swarmers count, and a revived skeletal body can count on its next death. Destroying a bone pile and room cleanup do not notify Carrion. Multiple nearby Carrions track their own counters. Deaths after frenzy still add HP and visual growth without another speed multiplier. Frenzy does not release Stun or Pull. A newly spawned/revived Carrion starts a fresh counter, consistent with the existing ability reset on skeletal revival.

## Complete change inventory

- `datafiles/tune.json`: Replace the old per-death HP/speed enrage settings with the four parameters above. Existing starting HP, speed, damage and attack timing stay unchanged.
- `objects/obj_carrion/Create_0.gml`: Read and clamp HP growth, death threshold and frenzy multiplier; initialize `nearby_deaths` and `frenzied`. Remove obsolete enrage variables.
- `scripts/EnemyHelper/EnemyHelper.gml`: Add `carrion_death_in_range` to implement the agreed grid shapes. Replace square hitbox overlap and additive speed growth with this range check, standard HP growth, an individual death counter and a one-time speed multiplication. Preserve notification deduplication, pile/dead-observer exclusions, visual scaling, siphon creation and shared movement updates.
- `scripts/EnemyCatalog/EnemyCatalog.gml`: Describe the health growth and permanent frenzy in Carrion's displayed description without hardcoding tunable numbers.
- `tools/test-carrion-growth.cjs`: Execute the real Create event and death/movement helpers. Cover JSON defaults and overrides, wounded current/max HP, threshold and later deaths, notification deduplication, piles/living/distant targets, skeletal revival, dead observers, independent Carrions, simultaneous deaths, exact radius 0/1/2/3 shapes, Frost, Banneret, Stun and Pull.
- `notes/enemy-abilities-implementation.md`: Replace the obsolete per-death speed description with the revised ability and radius rules.
- `notes/carrion-rework.md`: Record tuning, lifecycle semantics, verification and this inventory.

## Validation

All 36 regression scripts passed using `node tools/run-regressions.cjs`. The suite executes extracted GML with engine mocks; it does not compile or run GameMaker. Native compilation and playtesting remain unverified.
