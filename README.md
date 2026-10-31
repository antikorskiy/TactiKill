# TactiKill

**A tactical combat scoring system for Garry's Mod** — killstreak combos, CS:GO-style player ranks, achievements, contracts, style kills, random events, and a fully skinnable HUD.

Version: **1.5.0**

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [File Structure](#file-structure)
6. [Quick Start](#quick-start)
7. [Scoring System](#scoring-system)
8. [Combo Ranks (Killstreak)](#combo-ranks-killstreak)
9. [Player Ranks](#player-ranks)
10. [Style Kills](#style-kills)
11. [Multikills](#multikills)
12. [Achievements](#achievements)
13. [Contracts](#contracts)
14. [Random Events](#random-events)
15. [Weapons](#weapons)
16. [User Interface](#user-interface)
17. [Screen Shake](#screen-shake)
18. [Persistence (SQLite)](#persistence-sqlite)
19. [Leaderboard](#leaderboard)
20. [Auto-Spawn](#auto-spawn)
21. [Console Commands](#console-commands)
22. [Client ConVars](#client-convars)
23. [Server Settings (Tool Menu)](#server-settings-tool-menu)
24. [Configuration Reference (`sh_config.lua`)](#configuration-reference-sh_configlua)
25. [Sound Files](#sound-files)
26. [Debugging](#debugging)
27. [Notes & Tips](#notes--tips)

---

## Overview

TactiKill is a **server-side addon** that layers a full progression system on top of Garry's Mod's existing combat. It tracks every kill, awards points for style and streaks, unlocks achievements, gives out procedurally generated contracts from fictional organizations, and drops random airdrops and bombardments across the map — all with a custom HUD, scoreboard, dossier, and death screen.

Everything is designed to be:
- **Server authoritative** — stats, achievements, contracts, and events are validated on the server.
- **Client-aware** — the HUD, banners, shake, and sound can each be toggled or tuned per player.
- **Persistent** — progress is saved to SQLite across sessions.
- **Configurable** — every important number lives in `sh_config.lua` and the admin Tool Menu.

---

## Features

| Category | Highlights |
|---|---|
| **Scoring** | Kill score, headshot multiplier, style bonuses, multikill bonuses, rank-up bonuses |
| **Combo Ranks** | 27-tier killstreak ladder from `KILLING SPREE` to `LEGEND`, with configurable timeouts |
| **Player Ranks** | 60+ CS:GO/CS2-inspired ranks from `Silver I` to `TactiKill Legend`, with custom insignia |
| **Style Kills** | Airborne, Slide, Slow-Mo, Point Blank, Long Range, Prop |
| **Multikills** | Double / Triple / Squad Wipe / Mass Kill / Bloodbath |
| **Achievements** | ~100 achievements across 14 categories, with unlock banners + sound |
| **Contracts** | 22 contract templates from 100+ fictional organizations, 10 slots, difficulty 1–10 |
| **Random Events** | Bombardments (beam-of-light strikes) and falling airdrops |
| **HUD** | Agent panel, player rank panel, stats panel, combo panel, style log, banners |
| **Dossier** | Full-screen `AGENT / STATS`, `RANKS`, `ACHIEVEMENTS`, `CONTRACTS` tabs |
| **Scoreboard** | Replaces the default scoreboard with a detailed combat table |
| **Death Screen** | First-person death camera (locked position, free look), historical quotes, and a respawn countdown |
| **Screen Shake** | Camera-only, no aim impact by default, tuned per rank |
| **Persistence** | Auto-saved SQLite progress (45s autosave + shutdown save) |
| **Leaderboard** | Server-wide persistent rankings (kills / score / streak / headshots / multikills), backed by SQLite |
| **Weapons** | Artillery designator (player + admin), Field Terminal, Surrender, Free Hands |
| **Auto-Spawn** | Server-scheduled Combine / Rebel spawning |
| **Tools** | Timer tool with LMB/RMB/Reload binds |

---

## Requirements

- **Garry's Mod** (any recent branch)
- **No extra addons required** — TactiKill is self-contained.
- Optional: **SQLite** (bundled with Garry's Mod). If SQL is unavailable, persistence will be silently disabled.
- Optional: CS:S/HL2 content if you use sounds shipped as `.mp3`/`.wav` inside `sound/tactikill/*` (they're provided with the addon).

---

## Installation

1. Drop the `tactikill/` folder into `garrysmod/addons/`.
2. Ensure `lua/autorun/tactikill_init.lua` is present (it is the entry point).
3. Ensure any custom sounds you want are inside `sound/tactikill/…` (see [Sound Files](#sound-files)).
4. Start (or restart) the server.
5. Verify the console shows:
   ```
   [TACTIKILL] headshot sounds: N
   [TACTIKILL] death sounds: N
   [TACTIKILL] SQLite ready
   ```

---

## File Structure

```
tactikill/
├── lua/
│   ├── autorun/
│   │   └── tactikill_init.lua        # Entry point (loads all files)
│   ├── tactikill/
│   │   ├── sh_config.lua             # Master configuration
│   │   ├── sh_settings.lua           # Server settings definitions
│   │   ├── sh_achievements.lua       # Achievement definitions
│   │   ├── sh_contracts.lua          # Contract templates & customers
│   │   ├── cl_*.lua                  # Client-only modules (incl. cl_leaderboard.lua)
│   │   └── sv_*.lua                  # Server-only modules (incl. sv_leaderboard.lua)
│   └── weapons/
│       ├── tactikill_artillery.lua
│       ├── tactikill_artillery_admin.lua
│       ├── tactikill_noweapon.lua
│       ├── tactikill_surrender.lua
│       └── tactikill_terminal.lua
├── lua/tools/
│   └── tactikill_timer.lua           # Session timer tool
└── sound/tactikill/
    ├── headshot/                     # Random headshot sounds (mp3/wav/ogg)
    ├── death/                        # Random death sounds (mp3/wav/ogg)
    ├── low-honor-rdr-2.mp3           # Combo rank-up sound
    ├── projectile-launch.wav         # Bombardment launch
    └── parachute-airdrop.mp3         # Airdrop falling
```

Modules are grouped by prefix:

| Prefix | Runs on | Purpose |
|---|---|---|
| `sh_` | Client + Server | Shared data (config, achievements, contracts, settings) |
| `cl_` | Client | HUD, scoreboard, dossier, leaderboard, death screen, shake, sounds, events |
| `sv_` | Server | Scoring, combo, achievements, contracts, events, persistence, leaderboard, auto-spawn, tools |

---

## Quick Start

1. Join the server (or run a local game) as an admin.
2. Kill an NPC — you should see a floating style log like `HEADSHOT x2 +20` on the HUD.
3. Reach a **3-kill streak** — the combo panel lights up with `KILLING SPREE`.
4. Open the dossier with `tactikill_dossier`.
5. Open the achievements panel with `tactikill_achievements`.
6. Open the contract board with `tactikill_contracts`.
7. Customize the HUD and shake from **Utilities → TactiKill → Settings** in the Tool Menu.

---

## Scoring System

Every kill contributes to `score`. `kills` is tracked separately and is used for player-rank progression.

| Event | Default Score |
|---|---|
| Normal kill | `KillScore` = **10** |
| Headshot | `KillScore × HeadshotMultiplier` = **20** (base replaces the normal kill award) |
| Airborne kill | +`Bonus.Airborne` = **+15** |
| Slide kill | +`Bonus.Slide` = **+15** |
| Slow-mo kill | +`Bonus.SlowMo` = **+10** |
| Point blank | +`Bonus.PointBlank` = **+10** |
| Long range | +`Bonus.LongRange` = **+10** |
| Prop kill | +`Bonus.Prop` = **+10** |
| Double kill | +`MultikillBonus[2]` = **+30** |
| Triple kill | +`MultikillBonus[3]` = **+50** |
| 4+ multikill | +`MultikillBonus4Plus` = **+100** (per kill in the chain) |
| Combo rank up | +`RankUpBonus` = **+25** |
| Player rank up | +`PlayerRankBonus` = **+50** |
| Achievement unlock | +`Achievements.Bonus` (default **0**) |

Score is **int32** and clamped to `2147483647`.

> **Headshots** award only the multiplied base score, not `KillScore + multiplied`. This is intentional so that headshot hunting is not strictly better than style kills.

---

## Combo Ranks (Killstreak)

Combo ranks are short-lived (`KILLING SPREE`, `DOMINATING`, etc.). They decay when the timer expires and reset on death.

The full ladder (`C.Ranks`) — thresholds, timeouts, and screen-shake strength:

| # | Rank | Min kills | Timeout (s) | Shake |
|---|---|---|---|---|
| 1 | KILLING SPREE | 3 | 15 | 0.2 |
| 2 | DOMINATING | 4 | 13 | 0.35 |
| 3 | UNSTOPPABLE | 5 | 12 | 0.5 |
| 4 | RAMPAGE | 6 | 11 | 0.7 |
| 5 | GODLIKE | 7 | 10 | 0.9 |
| 6 | LEGENDARY | 8 | 9 | 1.1 |
| 7 | LEGENDARY+ | 10 | 8 | 1.3 |
| 8 | LEGENDARY++ | 12 | 7 | 1.5 |
| 9 | LEGENDARY+++ | 14 | 6 | 1.7 |
| 10 | MASTER | 16 | 5 | 1.9 |
| 11 | GRANDMASTER | 18 | 5 | 2.1 |
| 12 | SAVAGE | 20 | 4 | 2.3 |
| 13 | APEX PREDATOR | 22 | 4 | 2.5 |
| 14 | WICKED SICK | 24 | 4 | 2.7 |
| 15 | HOLY SHIT | 26 | 3 | 2.9 |
| 16 | MONSTER KILL | 28 | 3 | 3.1 |
| 17 | IMMORTAL | 30 | 3 | 3.3 |
| 18 | LUDICROUS KILL | 33 | 3 | 3.5 |
| 19 | ULTRA KILL | 36 | 3 | 3.7 |
| 20 | DEVASTATING | 40 | 2 | 3.9 |
| 21 | CATACLYSM | 44 | 2 | 4.1 |
| 22 | ANNIHILATION | 48 | 2 | 4.3 |
| 23 | OBLITERATION | 52 | 2 | 4.5 |
| 24 | APOCALYPSE | 56 | 2 | 4.8 |
| 25 | TRANSCENDENT | 60 | 2 | 5.0 |
| 26 | BEYOND GODLIKE | 65 | 2 | 5.5 |
| 27 | LEGEND | 70 | 2 | 6.0 |

**Decay** (`C.ComboDecayEnabled`): when the timeout expires, the combo drops **one rank at a time** instead of resetting. Each step uses `timeout × ComboDecayFactor` (default `0.6`), clamped to `ComboDecayMinTime` (default `0.5s`).

**Death** resets the combo (`C.DeathResetsCombo`).

---

## Player Ranks

Player ranks persist across sessions and are driven by `kills` **and** `score`. They are separate from combo ranks.

- **Threshold**: each rank has a `min` kill count and a `score` requirement.
- **Auto score**: by default, `score = min × PlayerRankScorePerKill` (default `10`). Changing `PlayerRankScorePerKill` in the admin settings rescales all auto-score ranks in real-time.
- **Insignia**: built from `symbol` (e.g. `>`, `*`, `+`, `^`, `=`, `#`, `~`, `@`), `count` (repetitions), `brackets` (wrapping `(`), and `stars` (leading `*`).
- **Range**: 60+ ranks from `Silver I` to `TactiKill Legend`.

Example ranks (abbreviated):

| Rank | Min kills (default) |
|---|---|
| Silver I | 0 |
| Silver IV | 4 |
| Gold Nova I | 33 |
| Master Guardian I | 140 |
| Legendary Eagle | 420 |
| Supreme Master First Class I | 850 |
| Global Elite I | 1450 |
| Immortal | 3300 |
| Mythic | 4160 |
| Apex | 8660 |
| TactiKill Legend | 19000 |

See `C.PlayerRanks` in `sh_config.lua` for the full table.

---

## Style Kills

Style bonuses are evaluated at the moment of the kill:

| Style | Detection |
|---|---|
| **Airborne** | Killer is not on ground, in `MOVETYPE_WALK`, water level `< 2`, not in vehicle |
| **Slide** | On ground, crouching, horizontal speed ≥ `SlideMinSpeed` (default 200). Can be overridden with `C.CustomSlideCheck(ply)` |
| **Slow-Mo** | `game.GetTimeScale() < SlowMoThreshold` (default 0.99) |
| **Point Blank** | Distance ≤ `PointBlankDistance` (default 150 units) |
| **Long Range** | Distance ≥ `LongRangeDistance` (default 1500 units) |
| **Prop** | Attacker is a `prop_physics` with a valid `GetPhysicsAttacker(PropAttackerTimeout)` |

All styles can be active simultaneously — they stack.

---

## Multikills

Tracked on a rolling window (`MultikillWindow`, default **3 seconds**):

| Chain | Label | Bonus |
|---|---|---|
| 2 kills | DOUBLE KILL | 30 |
| 3 kills | TRIPLE KILL | 50 |
| 4 kills | SQUAD WIPE | 100 |
| 5 kills | MASS KILL | 100 |
| 6+ kills | BLOODBATH | 100 |

The chain resets when `CurTime() - mkLast > MultikillWindow`.

`bestMultikill` is tracked permanently for the scoreboard and achievements.

---

## Achievements

Achievements are defined in `sh_achievements.lua`. Each definition is:

```lua
add(id, name, description, icon, checkFn, category)
```

- `checkFn(st, extra)` is evaluated **on the server** and returns `true` to unlock.
- `st` is the player's full state (kills, score, styles, hitbox counts, etc.).
- `extra` is either `{ kind = "kill", style = {...}, isHeadshot = bool, ... }` or `{ kind = "death" | "load" | "reset" }`.

### Categories

| Category | Example |
|---|---|
| Kills | `kills_1` … `kills_100k` |
| Headshots | `hs_1` … `hs_10k` |
| Multikill | `multi_2` … `multi_500` |
| Streaks | `streak_5` … `streak_100` |
| Style | `style_air`, `style_slide`, `style_slow`, `style_pb`, `style_lr`, `style_prop` |
| Weapons | `wep_pistol`, `wep_smg1`, `wep_ar2`, `wep_shotgun`, `wep_crowbar`, `wep_357`, `wep_crossbow`, `wep_rpg`, `wep_gravgun`, `wep_grenade`, `wep_melee` |
| Ranks | `rank_silver` … `rank_tklegend` |
| Combo | `combo_spree` … `combo_legend` |
| Deaths | `death_1`, `death_10`, `death_100`, `death_1k` |
| Accuracy | `shots_*`, `hits_*`, `acc_30`, `acc_50`, `acc_70` |
| Distance | `dist_500`, `dist_1k`, `dist_2k`, `dist_5k`, `dist_avg` |
| Hitbox | `hg_head_100`, `hg_torso_500`, `hg_limbs` |
| Special | `lucky`, `pentakill`, `veteran` |
| Trials | Stateful challenges: `trial_phoenix`, `trial_survivor`, `trial_air_hs`, `trial_executioner`, `trial_war_machine`, etc. |

### Unlock flow

1. Server runs `A.Check(ply, extra)` after each kill/death/load.
2. If a check returns `true` and the achievement isn't already unlocked, it's added to the player's `achievements` set.
3. A net message is sent to the client.
4. The client plays a banner + `ui/achievement_earned.wav`.

Achievement unlocks are **always silent on the scoreboard** — they only fire a banner to the player.

---

## Contracts

Contracts are procedurally generated tasks offered by fictional organizations (IATU, MI6, CIA, FSB, cartels, PMCs, cults — see `CT.Customers` for the full 100+ list).

### Slots

- **10 slots** by default (`CT.SlotCount`).
- **10 offers** are generated per player.
- Each offer has:
  - `templateId` — the contract type.
  - `customerId` — who issued it.
  - `title`, `desc` — display text.
  - `progress`, `target` — current and required progress.
  - `difficulty` — 1–10 (`kill_class` derives its difficulty from the target NPC class).
  - `reward`, `penalty` — points.
  - `state` — `4` (pending accept), `0` (active), `1` (complete), `2` (failed), `3` (expired).
  - `expiresAt`, `duration` — timer.

### Templates

| ID | Title | Target scaling |
|---|---|---|
| `kill_headshot` | Headhunter Protocol | `diff + 1` |
| `kill_total` | Clean Sweep | `diff × 3` |
| `kill_streak` | Killing Spree | `3 + diff`, fails on death |
| `kill_airborne` | Birds of Prey | `diff` |
| `kill_pointblank` | Close Quarters | `diff` |
| `kill_longrange` | Overwatch | `diff` |
| `kill_slide` | Momentum | `diff` |
| `kill_no_death` | Untouchable | `diff + 2`, fails on death |
| `kill_multikill` | Rampage | `max(2, diff - 3)` |
| `kill_class` | Hunt Order | Scales with class difficulty; capped at 2/3/5 |
| `kill_prop` | Gravity Assassin | `max(1, floor(diff * 0.8))`, prop kills |
| `kill_slowmo` | Bullet Time | `max(1, floor(diff * 0.7))`, slow-mo kills |
| `kill_style_any` | Signature Kill | `max(2, diff + 1)`, any style bonus |
| `kill_lowhp` | Do or Die | `max(1, floor(diff * 0.7))`, kills at HP <= 25 |
| `kill_fullhp` | Untouched Predator | `max(2, diff + 1)`, kills at full HP |
| `kill_double` | Double Down | `max(1, floor(diff * 0.7))`, exact double kills |
| `kill_headshot_chain` | Chain Reaction | `max(2, diff + 1)`, consecutive headshots |
| `kill_perfect` | Flawless | `max(2, diff + 1)`, kills without taking damage |
| `kill_variety` | Arms Dealer | `clamp(diff + 2, 2, 6)`, distinct weapons per life, no timer |
| `kill_pistol` | Sidearm Specialist | `max(2, diff + 1)`, pistol kills |
| `kill_shotgun` | Close Support | `max(2, diff + 1)`, shotgun kills |
| `kill_melee` | CQC Master | `max(1, floor(diff * 0.7))`, melee kills |

### Rewards

- `RewardBase` = 15
- `RewardPerDiff` = 2
- Reward = `RewardBase + difficulty² × RewardPerDiff`
- Penalty = `reward × PenaltyRatio` (default `1.0`)

### Refresh

- Contracts refresh every **300s** by default (`CT.RefreshInterval`).
- Active contracts have **5–10 minutes** of validity (`TimeLimitMin` / `TimeLimitMax`).
- `kill_no_death` contracts have **no timer**.

### Client sync

The server broadcasts the full contract state to the player whenever it changes, via `TACTIKILL_Contracts`.

---

## Random Events

Events are checked every **5 seconds**, and roll every `CheckInterval` = **75s** with `Chance` = **0.45**.

Only **one event** can be active at a time (`eventBusy` guard).

### Bombardment

1. Server picks `MinBeams..MaxBeams` (3–10) ground positions within `BeamRadius` (2000u) of random players.
2. Broadcasts `TACTIKILL_Event_Bombard_Start`.
3. Waits `ChargeTime` (5s), then sequentially:
   - Plays `projectile-launch.wav`.
   - Waits `SoundLeadTime` (0.4s).
   - Broadcasts `TACTIKILL_Event_Bombard_Strike`.
   - Spawns an `env_explosion` with `ExplosionRadius` (400) and `ExplosionDamage` (200), plus two follow-up waves at 0.15s and 0.30s.
4. Broadcasts `TACTIKILL_Event_Bombard_End` when finished.

Client-side: a vertical laser pillar with glow sprites is rendered at each strike. The pillar fades out after the strike hits.

### Airdrop

1. Server picks a ground position and broadcasts `TACTIKILL_Event_Airdrop_Start` with a `FallTime` (20s).
2. After `FallTime`, it plays `parachute-airdrop.mp3`, broadcasts `TACTIKILL_Event_Airdrop_Landing`, and spawns a physics box that slowly descends at `FallSpeed` (750 u/s).
3. The box is immune to damage and cannot be gravgun/pickup'd until it lands.
4. A player walking into it triggers `OpenAirdrop`, which grants one of:
   - **Artillery Designator** (15% chance, only if `ArtyEnabled` and player doesn't already have one).
   - **Ammo** for the current primary/secondary weapon, or `smg1` ammo if the current weapon has none.
   - **Health** (capped at `maxHp`).
5. The box self-destructs with an explosion effect.

### Admin trigger

```
tactikill_event bombard
tactikill_event airdrop
tactikill_event random
```

---

## Weapons

### `tactikill_artillery` — Artillery Designator

- **Player weapon**, one-shot per life.
- **E** enters/exits the artillery camera.
- **WASD** move the camera, **Space/Ctrl** up/down, **Shift** fast, **mouse wheel** quick up/down.
- **LMB** place a mark (max **5**), **RMB** undo, **R** fire, **ESC** exit.
- When fired, sends up to 5 marks to the server; `TK.FireBarrage` fires them with `chargeTime = 2.5s`, `fireInterval = 1.2s`.
- After firing, the designator is **stripped** and `TK_ArtyUsed` is set to `true` on the player (resets on respawn).

### `tactikill_artillery_admin` — Admin Artillery

- **Admin-only**, marked `AdminOnly = true`.
- Same controls, but max **64** marks, `MAX_HEIGHT = 50000`, `MAX_DIST = 50000`.
- Server checks `ply:IsAdmin()` before accepting a fire request.
- Fires with `chargeTime = 1.5s`, `fireInterval = 0.6s`, larger radius and damage.
- Can be fired repeatedly without being stripped.

### `tactikill_terminal` — Field Terminal

- Open the dossier by pressing **E** while holding it.
- Used to give players access to the dossier without typing commands.

### `tactikill_surrender` — Hands Up

- **Holding the weapon = surrendered**.
- `SetMaxSpeed(0)`, `SetWalkSpeed(0)`, `SetRunSpeed(0)`, `SetJumpPower(0)`.
- Cannot attack or move while deployed.
- Switching away un-sets `TACTIKILL_Surrendered` and restores movement.
- Renders a `SURRENDERING` label above the player for others, and a red warning for the holder.

### `tactikill_noweapon` — Free Hands

- Empty, lowered hands. Useful for cinematic surrender states.
- **No attack**, no crosshair, no ammo.

---

## User Interface

### HUD (`cl_hud.lua`)

The HUD is stacked in the **top-right corner**:

| Panel | Toggle ConVar |
|---|---|
| Agent (ID) | `tactikill_hud_agent` |
| Player Rank | `tactikill_hud_rank` |
| Stats (kills, K/D, health, score, timer) | `tactikill_hud_kd`, `tactikill_hud_hp`, `tactikill_hud_timer` |
| Combo (rank, streak, timer) | `tactikill_hud` |

Extra layers:

- **Rank banners** (`tactikill_hud_banner_duration`, default 1.8s)
- **Style logs** at `sh * 0.66`, toggleable with `tactikill_hud_logs`
- **Branding** (`tactikill_hud_brand`)

### Scoreboard (`cl_scoreboard.lua`)

`TAB` opens a detailed scoreboard with columns:

`Insignia | Player | K | D | K/D | SCORE | SPM | STREAK | HS | MULTI | DIST | ACC | HITBOX | FAV WEAPON`

Rows are sorted by **kills desc, then score desc**. Your own row is highlighted amber.

### Dossier (`cl_dossier.lua`)

Full-screen tabs:

- **AGENT / STATS** — agent ID, callsign, rank, K/D, headshots, multikills, best streak, accuracy, score, contract score, distance stats, favorite weapon.
- **RANKS** — full player-rank ladder with your current position.
- **ACHIEVEMENTS** — category-grouped achievement list.
- **CONTRACTS** — 10-slot contract board with "ACCEPT" buttons for pending offers.
- **LEADERBOARD** — server-wide rankings for KILLS / SCORE / STREAK / HEADSHOTS / MULTI, backed by SQLite (falls back to online players if SQL is unavailable).

Opened via:

- `tactikill_dossier`
- `tactikill_ranks`
- `tactikill_contracts`
- `tactikill_dossier_ach`
- `tactikill_leaderboard`
- `tactikill_terminal` weapon (E)
- The Tool Menu buttons.

### Death Screen (`cl_deathscreen.lua`)

- Uses a **first-person death camera**: your view stays at the spot where you died, but you can still look around with the mouse. No more free-floating death cam.
- Fades in over 0.4s, holds the quote, fades out over 0.5s.
- Renders a **random quote** from `C.DeathScreen.Quotes` and a live respawn countdown.
- Server **delays respawn** by `C.DeathScreen.Duration` (default 5s) — the player is spawned via `timer.Simple(dur + 0.1, …)`.
- `PlayerDeathThink` returns `true` while the death screen is up, so the default death cam spawn doesn't fire early.

### HUD Banners

- `COMBO RANK UP` — amber banner.
- `PLAYER RANK UP` — blue banner.
- `ACHIEVEMENT UNLOCKED` — yellow, from `cl_achievements.lua`.

---

## Screen Shake

Screen shake is a **camera offset only** by default (`ShakeRollDegrees = 0`), so it does **not** affect your aim.

Two components:

- **Sustained** — proportional to current combo rank (`Ranks[i].shake × ShakeSustainedFactor`).
- **Impulse** — a short pulse on rank up (`Ranks[i].shake × RankUpImpulseScale`), decays with `ShakeImpulseDecay`.

Per-player controls:

- `tactikill_shake_enabled` — master toggle.
- `tactikill_shake_multiplier` — 0–1 personal multiplier.
- `tactikill_shake_max` — personal max intensity cap.
- `tactikill_rankup_shake` — toggle impulse on rank up.

Server-side tuning: `C.ScreenShake*`, `C.RankUpShakeEnabled`, `C.Shake*` (`sh_config.lua`).

> If your weapon has a custom `CalcView`, TactiKill calls it first, then applies the offset, so weapon sway and idle animations are preserved.

---

## Persistence (SQLite)

When available (`C.PersistenceEnabled` and `sql` present), TactiKill uses:

```sql
CREATE TABLE tactikill_players (
    steamid TEXT PRIMARY KEY,
    nick TEXT,                   -- last known nickname
    kills, deaths, score, headshots, multikills, best_streak INTEGER,
    shots, hits INTEGER,
    distance_sum, distance_count, distance_max, distance_min REAL/INTEGER,
    weapon_kills TEXT,           -- JSON
    fav_weapon TEXT, fav_weapon_kills INTEGER,
    hg_counts TEXT,              -- JSON
    achievements TEXT,           -- JSON
    trials TEXT,                 -- JSON
    last_seen INTEGER
)
```

- **Identification**: prefers `SteamID64`; falls back to `SteamID`; if neither works, hashes `IP + lowercase nickname`.
- **Load** happens on `PlayerInitialSpawn`.
- **Save** happens:
  - Every **45 seconds** for dirty players (`TACTIKILL_AutoSave`).
  - On `PlayerDisconnected`.
  - On server `ShutDown`.
- **Anti-garbage rows** with `steamid ∈ {0, "", STEAM_0:0:0, STEAM_ID_PENDING, UNKNOWN}` are pruned on init.
- **Schema migration** adds `nick`, `achievements`, and `trials` columns if missing.
- **Nick** is refreshed on load/save, so the leaderboard never shows `UNKNOWN` for returning players.

### Trials blob

The `trials` JSON column stores:

```
bestHeadshotChain, bestPerfectStreak, lowHpKills, fullHpKills,
bestRank, bestMultikill, agentId, contractScore, contracts
```

If SQL is unavailable, persistence silently disables and the addon keeps working in memory.

---

## Leaderboard

Server-wide persistent rankings, stored in the same SQLite table and exposed through the dossier **LEADERBOARD** tab (`tactikill_leaderboard`).

- **Categories**: `kills`, `score`, `best_streak`, `headshots`, `multikills` (configurable via `C.Leaderboard.Categories`).
- **Limit**: top `C.Leaderboard.Limit` players (default 25, max 100).
- **MinKills**: only players with at least `C.Leaderboard.MinKills` kills (default 1).
- **Caching**: results cached for `C.Leaderboard.CacheSeconds` (default 30s) per category, invalidated on every save.
- **Fallback**: if SQL is unavailable or `PersistenceEnabled = false`, the leaderboard shows the current online players instead.
- **Nick display**: uses the stored `nick` column; if empty, falls back to the online nick by SteamID64/SteamID, then to `AGENT-<steamid tail>`.
- **Network**: one `TACTIKILL_Leaderboard` message per request, 1 request/second per player max.
- **Command**: `tactikill_leaderboard` (client) opens the tab.

---

## Auto-Spawn

Server-side NPC spawning, driven from `sv_autospawn.lua`.

- **Combine**: `C.AutoSpawn.CombineCount` (default 20), with random SMG1/AR2/Shotgun and 3 grenades.
- **Rebels**: `C.AutoSpawn.RebelCount` (default 15), only if `RebelsEnabled`.
- Positions are traced from `3000u above` down, within `Radius` (3500u) of random players, at least `MinPlayerDistance` (400u) away, with `MinNpcDistance` (120u) between NPCs.
- **Relations**:
  - Combine → `D_HT` to players.
  - Rebels → `D_HT` to players if `RebelsHostileToPlayer`, else `D_LI`.
- `CountAutoSpawned` caps total auto-spawned NPCs at `MaxTotal` (60).
- Clearing uses the `TACTIKILL_Autospawned` flag on each entity.

Trigger:

```
tactikill_autospawn all
tactikill_autospawn combine
tactikill_autospawn rebels
tactikill_autospawn clear
```

---

## Console Commands

### Client

| Command | Effect |
|---|---|
| `tactikill_dossier` | Open the dossier on the AGENT/STATS tab |
| `tactikill_ranks` | Open the dossier on the RANKS tab |
| `tactikill_contracts` | Open the dossier on the CONTRACTS tab |
| `tactikill_dossier_ach` | Open the dossier on the ACHIEVEMENTS tab |
| `tactikill_leaderboard` | Open the server leaderboard |
| `tactikill_achievements` | Open the standalone achievements panel |
| `tactikill_achievements_refresh` | Re-request achievements from the server |
| `tactikill_arty_fire` | Fire the held artillery designator (if held and active) |
| `tactikill_arty_fire_admin` | Fire the admin designator |

### Server (admin)

| Command | Effect |
|---|---|
| `tactikill_reset_stats confirm [userid\|name\|*]` | Reset kills, score, combo (timer preserved) |
| `tactikill_reset_achievements [nick]` | Reset a player's achievements |
| `tactikill_autospawn [all\|combine\|rebels\|clear]` | Manage auto-spawned NPCs |
| `tactikill_event [bombard\|airdrop\|random]` | Manually trigger an event |

Non-admins attempting server commands get `Admin only` in console.

---

## Client ConVars

| ConVar | Default | Range | Purpose |
|---|---|---|---|
| `tactikill_hud` | `1` | 0/1 | Master HUD toggle |
| `tactikill_hud_scale` | `1` | 0.6–1.6 | HUD scale |
| `tactikill_hud_rank` | `1` | 0/1 | Show player rank panel |
| `tactikill_hud_insignia` | `1` | 0/1 | Show rank insignia |
| `tactikill_hud_brand` | `1` | 0/1 | Show `TACTIKILL vX.Y.Z` header |
| `tactikill_hud_rank_progress` | `1` | 0/1 | Show rank progress bar |
| `tactikill_hud_kd` | `1` | 0/1 | Show K/D row |
| `tactikill_hud_hp` | `1` | 0/1 | Show HEALTH row |
| `tactikill_hud_agent` | `1` | 0/1 | Show agent ID panel |
| `tactikill_hud_lowhp_threshold` | `30` | 5–100 | HP % at which HEALTH turns red |
| `tactikill_hud_banner_duration` | `1.8` | 0.5–10 | Banner visibility (s) |
| `tactikill_hud_timer` | `1` | 0/1 | Show session timer |
| `tactikill_hud_logs` | `1` | 0/1 | Show style logs |
| `tactikill_sound_rankup` | `1` | 0/1 | Play combo rank-up sound |
| `tactikill_scoreboard` | `1` | 0/1 | Use TactiKill scoreboard |
| `tactikill_ach_banner` | `1` | 0/1 | Show achievement banners |
| `tactikill_ach_sound` | `1` | 0/1 | Play achievement sound |
| `tactikill_shake_enabled` | `1` | 0/1 | Enable screen shake |
| `tactikill_shake_multiplier` | `1` | 0–1 | Personal shake strength |
| `tactikill_shake_max` | `4.5` | 0–10 | Personal shake cap |
| `tactikill_rankup_shake` | `1` | 0/1 | Impulse on rank up |

All client cvars are marked `FCVAR_USERINFO`-ish (`true, false`) — they do **not** require a server connection to persist (but are reset with `Reset these settings to defaults` in the Tool Menu).

---

## Server Settings (Tool Menu)

**Utilities → TactiKill → Settings**

Settings are sent to the server via `TACTIKILL_SetSetting` and saved to `data/tactikill/settings.json`. Only **admins** (or superadmins, depending on `C.SettingsEditLevel`) can edit them.

The full list mirrors `TK.SettingsList` in `sh_settings.lua`, grouped as:

- **Score** — `KillScore`, `HeadshotMultiplier`, `RankUpBonus`, `PlayerRankBonus`, `PlayerRankScorePerKill`
- **Style bonuses** — `Bonus.*`
- **Style detection** — `PointBlankDistance`, `LongRangeDistance`, `SlideMinSpeed`, `SlowMoThreshold`, `PropAttackerTimeout`
- **Multikill** — `MultikillWindow`, `MultikillBonus[2..3]`, `MultikillBonus4Plus`
- **Combo rank timeouts** — per-rank
- **Combo rank thresholds** — per-rank (validated so min values stay strictly increasing)
- **Screen shake: strength per rank** — per-rank
- **Screen shake: global** — `ScreenShakeEnabled`, `ScreenShakeMultiplier`, `ScreenShakeMaxIntensity`, `RankUpShakeEnabled`, `ShakeSustainedFactor`, `RankUpImpulseScale`, `ShakeImpulseDecay`, `ShakeSmoothing`, `ShakeUnitsPerIntensity`, `ShakeMaxOffsetUnits`, `ShakeFrequency`, `ShakeRollDegrees`
- **Combo decay, death & sound** — `ComboDecayEnabled`, `ComboDecayFactor`, `ComboDecayMinTime`, `ComboDecayLog`, `DeathResetsCombo`, `DeathComboLostLog`, `ComboRankUpSoundEnabled`, `ComboRankUpSound` (validated against `^sound/[%w_/%-%.]+%.(mp3|wav|ogg)$`)
- **Player ranks** — `PlayerRankAnnounce`, `PlayerRankShowInLogs`, `RedAccentFromRank`
- **Style logs** — `MaxLogs`, `LogLifetime`, `ShowLogBonus`, `LogComboLost`
- **Random events** — `Events.*` and sub-tables
- **Death screen** — `DeathScreen.*`
- **Auto-spawn** — `AutoSpawn.*`
- **Achievements** — `Achievements.*`
- **Rules, session and admin** — `CountPlayerKills`, `CountFriendlyNPCs`, `ResetKillstreakOnExpire`, `SessionShowOnHUD`, `SessionAutoStart`, `ResetAllowSelf`, `ResetOthersLevel`, `PersistenceEnabled`, `Debug`

Changes take effect **immediately** for everyone (broadcast). Per-save JSON diff means only non-default values are stored.

A **Reset ALL server settings to defaults...** button is available at the bottom.

> `PlayerRankScorePerKill` changes automatically rescale every auto-scored player rank in real-time.

---

## Configuration Reference (`sh_config.lua`)

The single most important file. Key sections:

### General

```lua
C.HUDEnabledByDefault = true
C.CountPlayerKills    = false   -- PvP kills count
C.CountFriendlyNPCs   = false
C.Debug               = false
C.PersistenceEnabled  = true
C.SettingsEditLevel   = "admin"
```

### Scoring

```lua
C.KillScore              = 10
C.HeadshotMultiplier     = 2
C.RankUpBonus            = 25
C.PlayerRankBonus        = 50
C.PlayerRankScorePerKill = 10
```

### Style

```lua
C.PointBlankDistance  = 150
C.LongRangeDistance   = 1500
C.SlideMinSpeed       = 200
C.SlowMoThreshold     = 0.99
C.PropAttackerTimeout = 5
C.CustomSlideCheck    = nil  -- optional function(ply) -> bool
```

### Multikill

```lua
C.MultikillWindow     = 3
C.MultikillBonus      = { [2] = 30, [3] = 50 }
C.MultikillBonus4Plus = 100
```

### Combo / death

```lua
C.ResetKillstreakOnExpire = true
C.ComboDecayEnabled       = true
C.ComboDecayFactor        = 0.6
C.DeathResetsCombo        = true
```

### HUD / logs

```lua
C.MaxLogs      = 10
C.LogLifetime  = 3.5
C.ShowLogBonus = true
```

### Screen shake

```lua
C.ScreenShakeEnabled      = true
C.ScreenShakeMultiplier   = 1.0
C.ScreenShakeMaxIntensity = 4.5
C.ShakeRollDegrees        = 0  -- keep at 0 for aim-neutral shake
```

### Leaderboard

```lua
C.Leaderboard = {
    Enabled      = true,
    Limit        = 25,        -- 1..100
    MinKills     = 1,
    CacheSeconds = 30,        -- 0..600
    Categories   = {
        { id = "kills",       label = "KILLS"     },
        { id = "score",       label = "SCORE"     },
        { id = "best_streak", label = "STREAK"    },
        { id = "headshots",   label = "HEADSHOTS" },
        { id = "multikills",  label = "MULTI"     },
    },
}
```

### Events / auto-spawn / achievements

See the full commented table in `sh_config.lua`.

> `TK.ValidateConfig()` runs at load and clamps/repairs every value. If you hand-edit the file and introduce invalid data, defaults are restored with an `ErrorNoHalt`.

---

## Sound Files

### Structure

```
sound/tactikill/
├── headshot/    *.mp3, *.wav, *.ogg   -- random headshot sound per kill
├── death/       *.mp3, *.wav, *.ogg   -- random death sound per death
├── low-honor-rdr-2.mp3                -- combo rank-up
├── projectile-launch.wav              -- bombardment launch
└── parachute-airdrop.mp3              -- airdrop falling
```

### How they load

- `headshot/` and `death/` are **scanned on server start** and every file is `resource.AddFile`'d.
- The chosen file is sent to the attacker (headshot) or victim (death) via `TACTIKILL_PlaySound`, with **one dedicated channel per kind** (headshot = 0, death = 1), so multiple kills don't overlap and play through the correct file.

### Replacing sounds

Just drop your own files in the folders. The addon uses `sound.PlayFile` (client) or `sound.Play` (world) so any `.mp3`, `.wav`, or `.ogg` works.

### Disabling

- **Headshot sound** — remove all files from `sound/tactikill/headshot/`.
- **Death sound** — remove all files from `sound/tactikill/death/`.
- **Rank-up sound** — set `ComboRankUpSoundEnabled` to `false`, or `tactikill_sound_rankup 0`.
- **Achievement sound** — `tactikill_ach_sound 0`.

---

## Debugging

Enable debug logging:

```
tactikill_debug 1   -- not a convar, but C.Debug config
```

or set `C.Debug = true` in `sh_config.lua`. Then `TK.Debug(...)` will print to the server console. Useful for:

- Kill attribution and style detection.
- Combo decay and reset events.
- Achievement unlocks.
- Persistence load/save.
- Settings changes.

Events and artillery also print to console with `[TACTIKILL]` / `[TACTIKILL ADMIN]` prefixes for admins. Look for:

```
[TACTIKILL] Bombardment received: N beams
[TACTIKILL] Airdrop incoming: x,y,z in Ns
[TACTIKILL] Artillery fire by <player> (N marks)
```

---

## Notes & Tips

- **Headshot multiplier replaces the base kill score** for headshot kills. Set `HeadshotMultiplier = 1` if you want headshots to be score-neutral.
- **Combo decay** decays *down one rank at a time*. Setting `ComboDecayFactor` very low (e.g. `0.1`) effectively resets the combo.
- **`CountFriendlyNPCs = false`** means you can't farm friendly citizens or allied Combine. Set to `true` to allow it.
- **`RedAccentFromRank = 6`** (LEGENDARY) switches the combo panel accent from amber to red for higher ranks.
- **`PlayerRankScorePerKill`** lets you scale player ranks without editing `C.PlayerRanks` — perfect for servers that want fast or slow progression.
- **Contracts are per-player**, not global. Each player has their own 10-slot board.
- **The airdrop box is immune to damage and gravgun pickup** until a player touches it. Use that to prevent griefing.
- **Auto-spawn uses a soft cap** — `MaxTotal = 60` auto-spawned NPCs. If you raise `CombineCount`, raise `MaxTotal` too.
- **`CustomSlideCheck`** — set this in `sh_config.lua` if you use a custom movement base that doesn't follow the default crouch+speed detection.
- **`ResetAllowSelf`** — if false, only admins can reset stats, including their own.
- **`SettingsEditLevel`** — set to `"superadmin"` to require superadmin for changing server settings.
- **The death screen delays actual respawn** by `C.DeathScreen.Duration` — if you set the duration too high, players will wait a long time to respawn. A 5s default is a good balance.
- **The scoreboard is server-pushed** — it refreshes when the scoreboard is open, no more than once every 0.5s per client.
- **All HUD elements are scale-aware** — everything uses `ScrH()/1080` clamping and respects `tactikill_hud_scale`.
- **`TACTIKILL_BuildSettings`** is exposed globally — other addons can append to the TactiKill settings panel.
- **Achievements are checked on every kill**; if you add new `add(...)` definitions, they will automatically be picked up by the existing sync loop and the dossier/panel UI.
- **Leaderboard nick fallback** — if a player's stored nick is empty (e.g. old row before the `nick` migration), the addon shows the online nick or `AGENT-<steamid tail>` instead of `UNKNOWN`.
- **First-person death camera** — position is locked at the death spot, free look with the mouse. Set `C.DeathScreen.Enabled = false` to disable it entirely.
- **Contract templates** — 22 built-in templates now. Custom templates can be appended to `CT.Templates` at runtime (server-side only).

---

## License & Credits

- Addon by the TactiKill team.
- Some UI colors / rank naming patterns inspired by CS:GO/CS2 and the classic UT/Quake killstreak phrases.
- Historical quotes in the death screen are attributed to their authors where known.

---

**Have fun — and remember: the combo doesn't reset itself. Death does that for you.**