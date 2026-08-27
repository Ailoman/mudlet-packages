mpackage = [[skill-loop]]
author = [[Me]]
description = [[
### Skill Loop

Generic combat-skill looper for Icesus. Every skill alias remembers the
command it sent as the **last skill**, which is then auto-repeated on each
maneuver / attack-of-opportunity window.

### Aliases

| Alias | Action |
|---|---|
| `bj [target]` | Loop: use blow of justice |
| `bjs [target] [hp%]` | Loop: blow of justice → sacrifice (pauses below 30 % HP) |
| `bjj [target]` | Loop: blow of justice → judge |
| `kick [target]` | Loop: kick |
| `sr [target]` | Loop: use shield rush |
| `sp [target]` | Loop: use shield punch |
| `loop [target]` | Re-loop whichever skill was last used (optionally re-target) |
| `loopstop` / `bjstop` | Stop the loop |

### Auto-start

When you engage a new foe ("You attack X and get a chance to try to hit
first!") the loop automatically starts with the last skill you used —
no need to type anything.
]]
version = [[2]]
created = "2026-08-26T00:00:00+02:00"
