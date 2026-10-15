# Spellmaker's Stand

## Standard wave generation

Levels define a threat curve and an enemy roster instead of manually repeating
enemy objects in every wave. At room creation, `generate_standard_waves()` builds
the concrete `WaveData.enemy_array` queues used by the wave manager, then divides
each queue into coordinated spawn groups.

An enemy roster entry contains:

- `enemy_object`: the GameMaker enemy object to spawn.
- `cost`: how much of a wave's threat budget it consumes.
- `weight`: its relative selection frequency after its introduction.
- `intro_wave`: the wave where one copy is guaranteed to appear.
- `max_per_wave`: an upper bound for that enemy in one wave.

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

The generated order varies between runs, but budgets, introductions, rarity
weights, and per-wave limits keep the level's structure comparable. The run seed
is printed to the debug log and can be passed back to
`generate_standard_waves()` to reproduce a generation.

To add an enemy to a level:

1. Make the enemy inherit from `obj_enemy_parent`.
2. Configure both `base_speed` and `my_speed` in its Create event.
3. Add an `EnemyWaveDefinition` to the level roster.
4. Choose a cost, weight, introduction wave, and per-wave limit.
5. Ensure its introduction wave has enough budget for every guaranteed enemy.

Invalid configurations and generated queues are checked at startup and report a
descriptive GameMaker error.
