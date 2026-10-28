# Strike cast time

Set `forms.strike.cast_time` in `datafiles/tune.json` to the number of seconds from casting to impact. For example, `0.5` takes half a second and `1` takes one second. Restart the game after editing tuning.

The default is `0.23`, approximately the previous 400-pixel descent at 30 pixels per frame. At 60 game steps per second, both take 14 steps. Values must be positive numbers; times round to the nearest game frame with a one-frame minimum. Zero is rejected. Timing uses game steps and pauses with the spell object.

Each compiled spell captures its impact frame count. Strike uses that count to set travel speed, and an elapsed-frame counter determines impact exactly once. The initial lifetime extends past the impact deadline for casts longer than the previous two-second timeout. Sprite animation speed and the existing post-impact animation/lifetime behavior are unchanged.

## Every change

- `datafiles/tune.json`: add `forms.strike.cast_time: 0.23` alongside the existing cost.
- `scripts/SpellCatalogScripts/SpellCatalogScripts.gml`: validate the positive duration and capture `strike_cast_frames` during compilation.
- `scripts/FormGlyphs/FormGlyphs.gml`: derive descent speed from the captured duration, track elapsed frames, snap to the target at the deadline, and extend pre-impact lifetime for long casts.
- `tools/test-strike-tuning.cjs`: run actual Strike callbacks and the spell Step event to verify short/default/long cast timing, captured tuning, rounding, lifetime and one-time impact. Check invalid tuning.
- `notes/strike-cast-time.md`: document tuning, timing and the complete change inventory.

Run `node tools/run-regressions.cjs` for automated checks. GameMaker compilation and native playtesting remain unverified.
