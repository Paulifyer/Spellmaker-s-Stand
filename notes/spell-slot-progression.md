# Four spell slots and level progression

Levels 1–8 expose **2, 2, 3, 3, 4, 4, 4, 4** spell slots. Each level's `spell_slots` field in `datafiles/level.json` is adjustable independently from its glyph limit. The parser requires an integer from 1 to 4.

Four spells remain stored throughout the run. New slots begin empty; entering an earlier level preserves spells in slots that become locked. Locked spells cannot be selected, renamed or cast, and do not block Start because of invalid construction or mana cost. Unlocking them restores editing/casting and Start validation. Existing menu/new-run spell retention behavior is unchanged.

The editor displays four buttons and labels unavailable slots Locked; hovering shows the first configured campaign level that permits the slot. The gameplay HUD hides retained spell details in locked slots and advertises only available casting keys. Number-row and numpad keys 1–4 use the same rules. Developer rooms without campaign configuration expose all four slots.

Cooldown arrays already size themselves from `SPELL_SLOTS`, so increasing that constant also expands both cooldown arrays. Slot 4 follows the existing tuning rules: `player.spell_cd_by_slot[3]` if provided, otherwise `player.spell_cd`. The current three-entry override remains unchanged, so slot 4 uses the configured default, currently 0.8 seconds. No cooldown balance values were changed.

## Every changed file

| File | Change and purpose |
| --- | --- |
| `scripts/SpellbookHelperScripts/SpellbookHelperScripts.gml` | Raise capacity from 3 to 4. Add current-level slot count, slot eligibility and unlock-level helpers. Reject creation/edit access through `spell_ensure` for locked slots. Limit expensive-spell reporting and Start validation to available slots. |
| `scripts/LevelScript/LevelScript.gml` | Parse, validate and retain `spell_slots` in each level's runtime configuration. |
| `datafiles/level.json` | Add the approved eight-level slot progression to the active campaign. |
| `notes/level-campaign.draft.json` | Mirror the progression in the campaign draft. |
| `objects/obj_spellbook/Draw_64.gml` | Arrange four buttons, disable locked buttons, hide their retained icons, label them and show unlock-level tooltips. Reset stale locked selection before reading/editing the spell. Reset the active glyph group when switching spells. |
| `objects/obj_spellbook/Step_0.gml` | Reset locked selections and stop naming before keyboard input can modify a retained locked spell. |
| `objects/Player/Step_0.gml` | Restrict the casting-key loop to available slots. Existing key arithmetic supports 4/numpad 4; existing cooldown/channel logic now has four-element storage. End a channel if its slot becomes locked. |
| `objects/Player/Draw_64.gml` | Display four HUD slots, hide locked spell details and cooldowns, show Locked, and build casting instructions from the available count. |
| `tools/construction-test-context.cjs` | Give shared tests a four-slot level configuration and load the actual slot helpers and `spell_ensure`; supply the engine minimum operation. |
| `tools/test-glyph-progression.cjs` | Supply four-slot capacity to the actual level-parser test. |
| `tools/test-mana-preview.cjs` | Supply slot count/minimum dependencies to the isolated mana tests. |
| `tools/test-spell-editor.cjs` | Expand the editor fixture to four slots. Exercise the actual editor Draw/Step code with locked slots, stale selection, disabled buttons and protected retained names. |
| `tools/test-spell-slot-progression.cjs` | Test both JSON files, parser errors, all eight levels, direct level entry, unlock levels, empty new slots, retained spells, Start validation, number-row/numpad 4 input, cooldown defaults/overrides, Beam release and HUD output. Uses actual extracted helpers and Player Step/Draw code with engine calls mocked. |
| `notes/spell-slot-progression.md` | This behavior, file inventory, cooldown clarification and verification guide. |

## Verification

Run `node tools/run-regressions.cjs` for all checks. GameMaker compilation and in-game visual/input verification remain outstanding.

In GameMaker, check levels 1, 3 and 5 for two, three and four available slots. Confirm the editor's four buttons fit the artwork, locked tooltips show levels 3/5, and key/numpad 4 casts only from level 5 onward. Prepare a Beam in slot 4, hold/release 4 and check its cooldown. Return to an earlier level and verify retained locked spells neither cast nor block Start; revisit level 5 to confirm they return.
