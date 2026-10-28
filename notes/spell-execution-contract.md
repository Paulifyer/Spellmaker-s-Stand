# Spell execution contracts

- Effects start in written order; starting Pull does not wait for movement to finish.
- Direct Projectile and Beam tick effects follow the hit enemy's skeletal lineage.
- Strike, Rune, and Projectile AoE select occupants of their original area at activation.
- Pull selects its normal 3x3 region at activation, independently of Form AoE.
- Each Beam tick and each repeated Effect occurrence has independent application identity.
- One room scheduler orders all delayed work by due time and insertion sequence.
- The scheduler freezes while paused, survives delivery-object destruction, and clears on room entry.
- Enemy-target work waits through the skeletal gap, then applies once to the pile.
- Permanent enemy/pile destruction cancels work following that enemy identity.
- Status inheritance, Lightning immunity, Frost cap, Rune overflow, and mana rules stay intact.

The executable fixture is tools/spell-execution-contracts.cjs. It is connected to
the integrated engine harness once the executor migration is complete.
