# Spellmaker's Stand

## Standard wave generation

Levels define a threat curve and an enemy roster instead of manually repeating
enemy objects in every wave. At room creation, `generate_standard_waves()` builds
the concrete `WaveData.enemy_array` queues used by the wave manager.

An enemy roster entry contains:

- `enemy_object`: the GameMaker enemy object to spawn.
- `cost`: how much of a wave's threat budget it consumes.
- `weight`: its relative selection frequency after its introduction.
- `intro_wave`: the wave where one copy is guaranteed to appear.
- `max_per_wave`: an upper bound for that enemy in one wave.

Level 1's configuration lives in
`objects/obj_wave_level_1/Create_0.gml`. Its starting and ending budgets define
the difficulty range, while `difficulty_curve` controls how quickly the budget
ramps up. Spawn delays interpolate from `starting_delay` to `minimum_delay`.

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
