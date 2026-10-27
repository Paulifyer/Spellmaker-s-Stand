# Campaign JSON import

Source: https://docs.google.com/document/d/1LTrpE-MkG_Z15OTvQFKZCxWQj4My_fiyKoz903DobbI/edit?tab=t.knbk2gcadxdj

`datafiles/level.json` contains the three existing rooms, updated to the progression appendix. `notes/level-campaign.draft.json` contains all eight levels, but is NOT ready to replace the runtime file.

## Translation decisions

- Intro wave means first eligible wave, not a guaranteed spawn for every roster entry. Before introduction, weight and maximum are both zero. Explicit guarantees in notes become minimums: level 1 gets a Ranger in wave 2; level 2 gets one Ranger and one Brute in wave 1; level 3 gets one Frost-Warded Brute in wave 3.
- Level 1 uses the latest document's three waves; level 2 uses four; level 3 uses four. Enemy costs in code have not been changed.
- A zero maximum also sets weight to zero, as required by WaveValidation. Level 2's Brute weight override of zero in wave 2 is preserved without changing its maximum.
- Level 3 follows the numeric table in wave 3: skeletal enemies are disabled and one Frost-Warded Brute is guaranteed. The document's 'Skele only wave' note contradicts those numbers.
- Level 5's 'Fire Brute' and 'Fire Ranger' map to fire-warded variants. The Brute weight override applies to that variant.
- Level 8 wave 2's Banner Skeleton Brute maximum is raised from 3 to 4 to allow the required minimum of 4. 'Both Banner Skeleton Brutes' is interpreted as the single listed Haste Banner Skeleton Brute variant.
- Level 8's Carrion roster entry is interpreted as Haste Banner Carrion, matching its wave 5 and wave 6 requirements. 'Haste Carrion' and 'Haste Skele Brute' are aliases for the Banner variants.
- Unspecified minimums are zero; unspecified maximums after introduction are 999. No extra guarantees are inferred merely from a roster introduction.

## Before activating all eight levels

- Implement and register `banneret` with the intended haste aura. The current BanneretMut is empty and unregistered.
- Implement and register the reserved draft key `banneret-skeletal` for the combined haste/skeleton mutation. Current runtime supports only one mutation key per entry. Its intended surcharge is 4 (3 Banneret + 1 Skeletal).
- Create rooms rm_level_4 through rm_level_8 with their gameplay and wave managers.
- Implement missing glyphs and add their real catalog IDs to unlocked_glyphs: level 3 Combust; level 4 Snap; level 5 Chain; level 6 Force and Earth; level 7 Discharge. Existing glyphs are included; guessed IDs are intentionally not used.
- Add support for the document's per-level glyph limits (2, 3, 5, 6, 7, 8, 8, 8); the current level parser has no field for them.
- Decide whether to align EnemyCatalog costs with the document. JSON does not define base enemy costs. Both cost sets were checked for minimum-budget feasibility.
- Playtest in GameMaker. Static checks do not validate encounter pacing or implemented enemy/glyph behavior.

The draft is kept outside datafiles so it cannot trigger unknown mutation errors during the existing game's startup.
