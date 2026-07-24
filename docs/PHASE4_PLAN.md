# Phase 4 — "It's fun and keeps you playing"

Author: Opus planning pass, 2026-07-24 (post Phase-3 publish). Grounded in a
live baseline session + a static content inventory, not aspiration.

Phase 3 shipped a **working, clean core loop**. Phase 4 is not about adding
systems or raw content — the inventory shows the game is already content-rich:

| Asset | Count | Read |
| --- | --- | --- |
| Recipes (`CraftConfig`) | 26 | plenty |
| Quests (`QuestConfig`) | 64 across 18 types | plenty |
| Companions | 8 (+ buffs) | plenty |
| Zones / biomes | ~15 | plenty |
| Guest types | 8 Kenney meshes | enough |

**The gap is not "more" — it's feel, life, and reason-to-return.** Phase 4 =
juice, NPC life, replayability structure, and the last polish. Ordered by the
user's stated priorities (ASMR audio, dopamine/reward, NPC interactivity,
extended/rotating quests) and impact.

---

## Baseline observations (live, 2026-07-24)

- ✅ Harvest works — "Pick" prompts render on nodes; the flower fix holds.
- ✅ VN/identity clean — "Zundamon" one character, dialogue fires.
- ✅ World aesthetic is genuinely strong — pastel Nikki look, minimap, zone labels, tool hotbar all read well.
- ⚠️ **Companion renders flat-white** — `SurfaceAppearance.ColorMap` is correctly set to `Zundamon_BaseColor` (uploaded, owned) but does not display even post-publish + time. Companion is correctly sized (5.2 studs, 0.79× player). Hypotheses: (a) Avatar-Importer mesh UVs don't match the texture's UV layout, (b) still in moderation, (c) `SurfaceAppearance` needs the full PBR set / different `AlphaMode`. Needs a focused look.
- ⚠️ One lingering white square in the skybox/distance — a leftover broken-texture billboard or FX plane; track down and kill.
- ✅ Companion idle/walk anim driver exists but is inert (no animation IDs yet — needs Animation Editor import of the FBX's 2 baked takes; user-side GUI step).

---

## Workstreams (prioritized)

### A — Reward Feel / "Juice" (HIGHEST — the dopamine ask)
The systems fire correctly but land flat. Make every reward *feel* earned.
1. **Full UI SFX overhaul** (`SoundConfig` + the 26-letter `SoundService` bank all point at ~1-2 placeholder IDs). Map distinct Nomagician samples per action **by frequency band + use-case** so nothing is repetitive or fatiguing: soft high ticks for hovers, warm mid clicks for confirms, low rounded tones for panel open/close, sparkle stingers for rewards. ASMR-cozy target. Source new samples via `tools/asset-pipeline` when a slot is empty. (Task #27. User is also supplying custom click SFX.)
2. **Reward-moment stingers** — a dedicated, satisfying audio+visual beat on: perfect cook, guest served, fish caught, quest complete, level-up, tier-up, Zundarooms escape. Bubbles SFX already wired to cook/fish; extend to the rest, each with its own signature.
3. **Visual juice layer** — number pop-ups (+25 Gold floats), a brief scale-punch on the ChefPill at XP gain, particle burst on level-up, subtle hit-stop on perfect cook. Reuse the `UIHelper.spawnSparkles` + `FloatingRating` patterns already in the codebase.
4. **Streak/combo feedback** — cooking already tracks combo; surface it loudly (escalating pitch, combo counter flourish).

### B — NPC Life (HIGH — the "wonky NPCs" ask)
Guests and roamers are functional but robotic.
1. **Guests visibly want service** — bounce/idle-sway, an emote bubble with their desired dish, a shrinking patience ring that colors from green→red. `GuestManager` already sets patience + a BillboardGui; enrich it, don't rebuild.
2. **Roaming feels alive** — `NPCPatrolSystem` tweens 2-part stand-ins between waypoints; add idle pauses, look-at-player when near, occasional ambient "bark" VN one-liners (data already in `VNDialogueData`), so they read as inhabitants not conveyor parts. Keep it non-intrusive (cooldowns, proximity-gated).
3. **Merchant/traveler payoff** — `Merchant_01` opens the Furniture Shop (done); give travelers a small reason to talk to (a rotating tip, a micro-reward on first chat) so the `npc_chat` quests feel rewarding not chore-like.

### C — Replayability Structure (HIGH — return-to-play)
The engine exists (`EndlessLoopWiring`: ChallengeMode + DailyChallenge services load clean); the question is whether they're *tuned* and *surfaced*.
1. **Playtest + tune Endless and Daily** end-to-end — are the waves paced? does the daily reset + reward? This is verification-first: play them, find where they stall or feel unrewarding, then tune.
2. **Daily login / streak reward** — a cozy "come back tomorrow" hook (cooking_streak already tracked in data; build the daily-reward surface if absent).
3. **Rotating quest content via Ollama** — `scripts/ollama_quest_worker.py` exists. Run it, review outputs, integrate the good ones into `QuestConfig` on a cadence so daily/endless quests stay fresh. (Also `ollama_dialogue_worker`, `ollama_recipe_worker`.)
4. **Tier/prestige clarity** — the ChefPill shows tier+level; add a "serve N more for [next tier]" nudge somewhere lightweight (tooltip or daily card) — the one thing the retired ProgressionPanel did that isn't yet re-surfaced.

### D — World & Companion Polish (MEDIUM)
1. **Companion texture** — investigate why `SurfaceAppearance` isn't rendering (UV vs moderation vs PBR-set); this is the most visible remaining rough edge.
2. **Companion animations** — import the FBX's 2 baked takes via Animation Editor, publish, drop the IDs into `CompanionVisualConfig.zundamon.idle/walkAnimationId` — the driver is already waiting for them.
3. **Zundarooms entrance → beach tunnel** relocation (task #25).
4. **Kill the lingering white square** + a final FX sweep.
5. **Stutter/lag investigation** (task #29) — profile for any per-frame workspace-wide scans that slipped back in.

### E — Content-Freshness Pipeline (LOW — enabling, not urgent)
Formalize the Ollama-generate → review → integrate loop and the asset pipeline as the standing way to add content, so Phase 4 content stays a repeatable process not a one-off.

---

## Suggested execution order
1. **A1+A2 (audio/SFX + reward stingers)** — biggest felt-impact-per-effort, directly the user's top ask, and unblocks the "cozy ASMR" identity.
2. **B1 (guests want service)** — the most-noticed NPC wonkiness.
3. **A3 (visual juice)** — compounds with A1/A2.
4. **C1 (tune endless/daily)** — verify the replay loops are actually fun before adding more.
5. **B2/B3, C2/C3, D** — interleave.

Verify each in live Play, commit per verified batch, same discipline as Phase 3.

## Open external/user-side items (not blocking Phase 4 code work)
- Companion animation IDs (Animation Editor import — GUI-only, user step).
- Any new custom SFX the user is recording (drop-in when ready).
- `git push` — 20 commits are ahead of `origin/main` locally (published to Roblox ≠ pushed to git).
