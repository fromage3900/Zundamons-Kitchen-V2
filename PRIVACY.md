# Privacy Policy — Zundamon's kItchen

**Last updated:** July 2026
**Creator:** fromage3900

This document describes how this Roblox experience handles player data.

---

## Overview

Zundamon's kItchen is a kitchen life-sim with **optional** AI mentor chat (Zundapal and Master Chef Zunda). Scripted dialogue and quests work without AI. Core gameplay uses Roblox DataStores for progression.

---

## Data We Store (Roblox DataStores)

Typical saved fields include:

- Currency, inventory, quest progress, tier, owned plots and decorations
- Companion selection and cosmetic unlocks
- `llm_disclaimer_accepted` — whether the player accepted the in-game AI disclosure

We do **not** persist LLM chat transcripts in DataStores.

---

## Optional AI Mentor Chat

When a player uses free chat after accepting the in-game disclaimer:

| Sent to AI provider | Not sent |
|---------------------|----------|
| Roblox display name | Real name, address, phone, email |
| Filtered message text | Passwords or payment info |
| Gameplay snapshot (tier, zone, inventory summary) | Full chat history from prior sessions |
| Persona id (`zundapal` or `master_chef`) | Other players' messages |

**Processing:** Outbound requests use Roblox `TextService` filtering. A per-user daily message cap applies (default: 20 messages/day).

**Session history:** Conversation context is held in server memory for the current session only and cleared when the player leaves.

---

## Third-Party Services

| Service | Purpose |
|---------|---------|
| Roblox platform | Hosting, authentication, DataStores, text filtering |
| LLM API (Studio-configured) | Optional mentor replies |

API keys are stored only in Roblox Studio (`ServerStorage.ZundapalLLMSecrets`), not in this repository.

---

## Children's Privacy

Players under 13 should use AI chat with a parent or guardian. The in-game modal states this. Do not share personal information in free chat.

---

## Contact

Report privacy concerns via Roblox experience feedback or GitHub issues. For security vulnerabilities see [`SECURITY.md`](SECURITY.md).
