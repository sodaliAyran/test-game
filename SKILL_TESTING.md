# Testing the Skill Tree System

## 🎮 Keyboard Shortcuts (Easiest Method!)

Just run the game and press number keys:

| Key | Skill | Effect |
|-----|-------|--------|
| **1** | Swift Strike | +20% attack speed |
| **2** | Power Strike | +30% damage |
| **3** | Wide Slash | +40% attack size |
| **4** | Double Strike | 2 hits (front → back) - *requires key 1* |
| **5** | Triple Strike | 3 hits (front → back → front) - *requires key 4* |
| **6** | Whirlwind Strike | 4 hits (all directions) - *requires key 5* |
| **7** | Devastating Blow | +50% damage - *requires key 2* |
| **0** | Reset All | Clear all unlocked skills |
| **9** | Unlock All | Unlock everything at once |

> **Note**: Skills with prerequisites will show an error message if you try to unlock them without the required skills first.

---

## Alternative: Using Godot Debugger

1. **Run the game** in Godot editor (F5)
2. **Open the debugger** (bottom panel)
3. **Go to the Remote tab**
4. In the **Remote Inspector**, find and expand the `SkillManager` node
5. **Call the debug method**:
   ```gdscript
   SkillManager.debug_unlock_all("warrior")
   ```

## Testing Individual Skills

### Test Attack Speed (Swift Strike)
```gdscript
SkillManager.unlock_skill("swift_strike")
```
**Expected**: Sword attacks 20% faster (cooldown reduced from 2.5s to ~2.08s)

### Test Damage Increase (Power Strike)
```gdscript
SkillManager.unlock_skill("power_strike")
```
**Expected**: Enemies take 30% more damage per hit

### Test Attack Size (Wide Slash)
```gdscript
SkillManager.unlock_skill("wide_slash")
```
**Expected**: Sword sprite becomes 40% larger during attacks

### Test Double Strike
```gdscript
SkillManager.unlock_skill("swift_strike")  # Prerequisite
SkillManager.unlock_skill("double_strike")
```
**Expected**: Sword attacks twice - first forward, then backward

### Test Triple Strike
```gdscript
SkillManager.unlock_skill("swift_strike")
SkillManager.unlock_skill("double_strike")
SkillManager.unlock_skill("triple_strike")
```
**Expected**: Sword attacks three times in a sweeping pattern (forward, left, right)

### Test Whirlwind Strike
```gdscript
SkillManager.unlock_skill("swift_strike")
SkillManager.unlock_skill("double_strike")
SkillManager.unlock_skill("triple_strike")
SkillManager.unlock_skill("whirlwind_strike")
```
**Expected**: Sword attacks in all four cardinal directions

## Reset Skills
```gdscript
SkillManager.reset_skills()
```

## Check Unlocked Skills
```gdscript
print(SkillManager.get_unlocked_skills())
```

## Notes

- Skills stack! You can unlock multiple skills and their effects will combine
- Multi-hit skills use the highest unlocked multi-hit count
- Damage and attack speed modifiers multiply together
- Prerequisites are enforced - you can't unlock Triple Strike without Double Strike first
