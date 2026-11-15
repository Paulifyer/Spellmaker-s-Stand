# AI Usage Declaration — NM4260, *Spellmaker’s Stand*

**Tool used:** ChatGPT / Codex

The prompts below are paraphrased. The outcomes reflect the available records.

| Task | Prompt | Outcome |
|---|---|---|
| Earth Barricade health bar | “Fix the Earth Barricade health bar so it decreases visually as the barricade takes damage.” | Patch verified in code. In-game behavior was still unverified. |
| Level selection label | “Show a bold ‘NEW’ label on unlocked levels that haven’t been cleared.” | Implemented. |
| Spellbook glyph order labels | “Draw indicators for the order of effects in the spellbook, then display the order using Roman numerals.” | Edits for the numeric indicators were recorded. Inclusion of the Roman numeral update in the submitted build is unconfirmed. |
| Mana recovery display | “Make the mana bar red during recovery and remove the flashing.” | Implementation requested. Inclusion in the submitted build is unconfirmed. |
| Level scenery correction | “Replace the misplaced house in the bottom-right corner of levels 2–8 with the tree formation from level 1.” | Implementation requested. Inclusion in the submitted build is unconfirmed. |
| Pre-level warning | “Show a warning before starting the level if none of the four spell slots contains a damaging effect.” | Implemented. Automated checks passed. The popup layout was still unverified in GameMaker. |
| Skeleton remains debugging | “Investigate why skeleton remains lose existing Delay effects.” | Investigated. The proposed fix was never applied. |
| Wave configuration debugging | “Check how the wave configuration handles an enemy with a positive spawn weight and a maximum count of zero.” | Reviewed how wave validation interprets the existing configuration. |
| Enemy tuning lookup | “Check why `tune_enemy` returns `undefined` when it reads the `enemies` section of the tuning configuration.” | Investigated the lookup and recorded code edits. |
| Frame stutter diagnosis | “Check why the game stutters and help me collect a Windows performance trace.” | Added diagnostic instrumentation and investigated frame timing. The stutter was also reproduced in a blank GameMaker project. |
| Projectile sprite transitions | “Use my three existing projectile sprites for launch, flight, and impact.” | Recorded edits for the projectile animation states. |
| Spellbook and beam animation debugging | “Why don’t the spellbook UI elements follow the drop animation, and why does the beam sprite appear static?” | Investigated the positioning and animation issues. |
| Unexpected next-level button | “Find why `obj_next_level_button` appears when an enemy dies.” | Investigated which code path created the button. |
| Earth Barricade spawn debugging | “Check why my existing Earth glyph fails to spawn its rock object.” | Investigated the existing spawn code. |
| Enemy and status animations | “Animate the mole’s transition from its emerging sprite to its normal sprite, and help draw and align the existing status-effect sprites.” | Recorded edits for animation and visual rendering. |
| Spell-effect visual debugging | “Fix the missing Snap animation, the frost overlay’s position and scale, and the misplaced Discharge rings.” | Investigated visual spawning, alignment, and scaling. |
| Barrier hit shader and wave banner | “Check why the barrier hit shader fails to trigger and why the portal sprite doesn’t draw over the wave banner.” | Investigated shader triggering and draw order. |
| Spell slot display | “Draw the spell slots as circles, size the glyphs to fit, and grey out the icon when the spell can’t be cast.” | Recorded edits to the slot shape, icon sizing, and disabled appearance. |
| Delayed-effect visual debugging | “Trace why delayed effects don’t animate as expected and why a later animation can still play after the target dies.” | Traced the existing combat queue and visual triggers. |
| Level selection layout | “Fit the level buttons to the menu and align them with the drop animation.” | Recorded level selection UI edits. |
| Level unlocks for playtesting | “Let F8 unlock all levels for testing. How do I also unlock all levels through the save file?” | Recorded edits for the F8 shortcut. ChatGPT also explained how to edit the save file. |
| Victory menu button scaling | “Why do the stretched buttons return to their original size when the victory menu animation ends?” | Reviewed how to preserve the initial button scale. |
| Spell sound playback code review | “Check my implementation of `combat_play_sfx` and `combat_spawn_sfx`.” | Reviewed the existing sound playback helpers. |

## Note on documentation
AI was used to generate the technical documentation as seen in the notes folder. This documentation has been reviewed to ensure its accuracy withe existing implementation.

## Note on exact code changes

The available records do not provide a complete line-by-line account for every entry. Some requests involved debugging advice, code review, or playtest guidance and produced no code edits. The repository chat archive preserves exact diffs for recorded editor operations and links relevant Git changes where available. Those diffs can include intermediate edits and diagnostic code, so they do not always show what shipped in the submitted build. See the [repository chat archive](notes/chat-history-ethan/README.md).
