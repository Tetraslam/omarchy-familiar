# Familiar

A little pixel fox that lives in your Omarchy bar and reacts to your day.

![kit typing along with two agents](preview.png)

| When | Kit |
|---|---|
| you're away (5 min idle) | curls up and sleeps, breathing slowly, with drifting z's |
| OpenCode agents are working | types on a tiny laptop |
| an agent finishes | cheers ✓ |
| you commit anywhere in `~/Programming` | hops ✦ |
| music is playing | wears headphones and bobs, with the odd ♪ |
| Crunchyroll, Jellyfin or Netflix is on screen | eats popcorn |
| it's 1–5am | yawns |
| the first time you show up each day | stretches awake ☀ |
| you're unplugged under 15% | lies down, running on fumes |
| otherwise | wanders, sits, blinks, wags, and turns to look at your cursor |

**Click** to pet (♥), **scroll** for belly rubs, **middle-click** for a berry (five a day, then it's full). It remembers today's pets and treats; hover to see.

## Naps cost nothing

**Right-click** tucks it into bed: one still frame under a blanket, with every timer and check stopped. Click to wake it. Turn on `napOnBattery` and it naps by itself whenever you unplug.

Awake, it ticks four times a second on power and slower on battery. Idle, music, battery and windows come from events; agents are checked every 15 seconds and commits every minute.

## Install

```bash
omarchy plugin add https://github.com/tetraslam/omarchy-familiar --enable
```

## Settings

| Key | Default | |
|---|---|---|
| `name` | `kit` | |
| `yard` | `Medium` | Room to wander: `Small` (stays put), `Medium`, `Large` |
| `napOnBattery` | `false` | Nap whenever unplugged |
| `projectsDir` | `~/Programming` | Commits here make it hop |

`omarchy-shell familiar <pet|treat|nap|wake|toggle|state>` from scripts.

## License

MIT
