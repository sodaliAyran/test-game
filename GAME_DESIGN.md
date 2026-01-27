# Game Design Document: Villain vs. Heroes Combat System

## Project Overview

A "Survivors-like" game where the player is a powerful Villain fighting against a team of iconic Heroes (Rogue, Mage, Barbarian). The player does not press attack buttons; combat is driven by positioning, timing, and automated "snapping."

---

## 1. The Global Token Bucket (AI Director)

Instead of mindless AI, use a **Global Action Point (AP) Pool** to manage hero behavior.

### The Bucket
A central resource that refills over time. Max capacity and refill rate increase as the game progresses (simulating heroes "leveling up").

### Action Costs
Every hero ability has a cost:
- **Basic Melee:** 1 AP
- **Rogue Dash/Backstab:** 3 AP
- **Mage Spell/CC:** 5 AP

### Priority Queue
Only N "Special" tokens can be active at once to prevent unreactable "CC spam."

### Hero Recovery
Heroes don't die; they get "Downed." They can spend Bucket AP to perform a "Second Wind" or be healed by a "Medic" hero role.

---

## 2. Automated "Arkham" Movement (The Snap)

To prevent "whiffing" strikes in a buttonless environment:

### Search Cone
The player character looks for targets in a **45° cone** based on the current Movement Direction.


---

## 3. Positioning-Based Countering

Since there is no "Counter" button, the player's **Movement Vector** acts as the input:

### Telegraphs
Heroes display a "Warning" (like Arkham's blue lightning) when spending AP on a strike.

### The "Towards" Logic
If the player moves **toward** the attacking hero during the telegraph, the auto-attack prioritizes that hero and triggers a "Counter" animation.

### The "Away" Logic
Moving **away/perpendicular** triggers a "Dodge/Evade" state with I-frames.

---

## 4. Intelligent Target Selection

The auto-attack "Brain" should prioritize targets in this order:

1. **Interrupters:** Heroes currently in a "Telegraphing" state
2. **Threats:** Ranged/Mage heroes currently spending AP
3. **Proximity:** The closest standing hero
4. **Ignore:** Downed heroes (unless no other targets exist)

---

## 5. Visual Polish & Feel

### Hit-Stop
Freeze frame for ~0.05s upon impact.

### Slot System
Heroes fill an "Inner Ring" (5–8 slots) around the player. If one is knocked away, another hero from the "Outer Ring" immediately steps up to fill the gap.

### Impact
Use directional screen shake and heavy VFX to compensate for the lack of tactile button feedback.

---

## Implementation Notes

### Core Systems Required
- [ ] Global AP Pool singleton (AI Director)
- [ ] Hero state machine with Downed/Recovery states
- [ ] Snap targeting system with cone detection
- [ ] Telegraph/Warning visual system
- [ ] Counter detection based on movement vector
- [ ] Target prioritization brain
- [ ] Slot-based positioning system (Inner/Outer rings)
- [ ] Hit-stop and screen shake effects

### Hero Archetypes
| Hero | Role | Primary Cost | Special Ability |
|------|------|--------------|-----------------|
| Barbarian | Melee Tank | 1 AP | Heavy Strike (2 AP) |
| Rogue | Melee Assassin | 1 AP | Dash/Backstab (3 AP) |
| Mage | Ranged CC | 2 AP | Spell/CC (5 AP) |
| Medic | Support | 1 AP | Heal Downed (4 AP) |
