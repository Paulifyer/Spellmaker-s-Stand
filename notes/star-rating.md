# Level star ratings

Victories award one star for completion, two for remaining wall HP strictly above 33%, and three strictly above 66%. The calculation uses unrounded HP percentages and the maximum HP captured when the level starts. Failed and abandoned attempts do not write progress.

Edit `star_rating.two_star_wall_hp_percent` and `star_rating.three_star_wall_hp_percent` in `datafiles/tune.json`. Values are percentages (0–100), with the two-star threshold strictly below the three-star threshold. Invalid pairs fall back to 33/66. Restart the game after edits.

An individual `datafiles/level.json` level entry can optionally contain:

```json
"star_rating": {
    "two_star_wall_hp_percent": 40,
    "three_star_wall_hp_percent": 80
}
```

Omitted per-level fields inherit tuning defaults. The victory popup shows larger stars and a single Wall HP remaining label with the raw final HP value.

Any positive damage through `reduce_village_hp` permanently marks that run as damaged. Healing back to full does not restore flawless eligibility. A completed, undamaged run awards three stars with the supplied cyan gradient sprite. Normal earned stars use the yellow sprite; unearned slots use white. Each retry starts fresh damage history and HP.

The victory result is captured before gameplay deactivation, and is not recalculated during rendering. `level_stars.ini` in GameMaker's game save directory records best `stars` and `flawless` values by room name. Missing entries default to zero; lower-scoring replays cannot erase either achievement. This dedicated file does not change campaign unlock behavior.

Verification: `node tools/test-star-rating.cjs` covers strict threshold boundaries, failed results, overrides, invalid settings, damage history including healing, best-result persistence and sprite registration/dimensions. `node tools/test-gamemaker-assets.cjs` checks project assets. The existing glyph-progression and tower-targeting tests also fail on the original committed files (level-two max-glyph expectation and missing enemy_get_leftpoint test mock, respectively).

Native GameMaker compilation and visual playtesting remain unverified. In GameMaker, check one-, two-, three-star and flawless victories, retry after damage, and re-launch after a flawless victory to verify the INI entry remains. Check popup animation and glyph unlock spacing at the configured GUI size.
