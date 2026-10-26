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
channeling. Invalid targets, unusable spells, insufficient mana, exhaustion, and
the shared cooldown reject casts without queuing them. The cooldown duration is
configured by `player.spell_cd` in `datafiles/tune.json`.

Menus block casting; opening the spellbook or losing window focus ends an active
channel. Pausing freezes gameplay. If the channel key is released while paused,
the channel ends on the first resumed frame. **Space** still starts mana recovery.

In GameMaker, check all three slots with both keyboard sections, tile targeting,
tap versus hold behavior, channel release and exhaustion, pause/resume, spellbook
naming, mouse-operated buttons, and the slot highlights and control hint.

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
