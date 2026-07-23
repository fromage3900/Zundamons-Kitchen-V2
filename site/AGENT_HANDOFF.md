# Zundamon's Kitchen V2: Multi-Agent Handoff & Architecture Guide

## Overview
This document serves as the live coordination hub for **Antigravity**, **Cline**, **DeepSeek**, and local **Ollama** daemons working in tandem on `Zundamons-kItchen-V2`.

---

## Agent Roles & Division of Responsibilities

### 1. Antigravity (Lead AI Coding Assistant)
* **Role:** Lead Architect & Orchestrator
* **Responsibilities:**
  * System design and overall directory/file mapping.
  * Maintaining `default.project.json`, `wally.toml`, `aftman.toml`, and `mise.toml`.
  * Implementing Matter ECS systems and React integration.
  * Resolving cross-script dependency conflicts and managing user communications.

### 2. Cline (DevOps & Environment Supervisor)
* **Role:** Local Environment & Tooling Manager
* **Responsibilities:**
  * Monitoring `rojo serve` (Port 34872) and resolving socket/port conflicts (`os error 10048`).
  * Running `wally install` when `wally.toml` dependencies change.
  * Checking process health and running build scripts.

### 3. DeepSeek (Server-Side Logic & Algorithm Specialist)
* **Role:** Backend ECS & Validation Engineer
* **Responsibilities:**
  * Deep-diving into server-side math and validation (`CookingValidationSystem`, `HarvestValidator`, `FishingValidationSystem`).
  * Writing secure server-side logic that prevents client exploit manipulation.
  * Auditing ProfileService data schemas and DataManager mutations.

### 4. Local Ollama Daemons (Background Utility Worker)
* **Role:** Code Formatter & Boilerplate Generator
* **Responsibilities:**
  * Running StyLua auto-formatting and Selene lint checks.
  * Generating component prop types and inline Luau annotations (`--!strict`).
  * Processing bulk documentation updates and docstrings.

---

## Current Project State (Phase 2 Recovery Checkpoint)

The earlier "Phase 6 complete" label was not supported by the live implementation. Phase 2 restored deterministic boot and tooling; it did not certify end-to-end gameplay parity. See [PHASE2_BOOT_RECOVERY.md](PHASE2_BOOT_RECOVERY.md) and [PHASE3_RECOVERY_PLAN.md](PHASE3_RECOVERY_PLAN.md).

| Component | Status | Details |
|-----------|--------|---------|
| **Rojo Server** | ✅ ACTIVE (Port 34872) | Rojo 7.7.0 running; `$ignoreUnknownInstances: true` enabled on Workspace to preserve Studio level design |
| **Wally Packages** | ✅ INSTALLED | Matter 0.8.4, React 17.1.0, ProfileService, ReplicaService loaded in `Packages/` & `ServerPackages/` |
| **UI Bootstrapping** | RECOVERED | Canonical client boot is Rojo-managed; legacy `StarterGui` scripts are disabled in the saved place. Respawn safety passed a focused smoke test. |
| **VN Dialogue UI** | RECOVERED | Canonical modal starts hidden and its top-level GUI uses `ResetOnSpawn = false`. |
| **Timed Cooking** | BLOCKED FLOW | Ingredients can be deducted, but the start event does not reach the registered Matter system. Phase 3 must restore one authoritative session path. |
| **Harvesting & Tools** | BOOTABLE / PARITY PENDING | Validation and tool startup load; authoritative inventory settlement and full-loop parity remain Phase 3 work. |
| **Fishing** | FAILS CLOSED | The adapter rejects requests until one authoritative adapter-to-session handoff is rebuilt and validated. |

---

## Active Task Backlog for Next 2 Hours

- [x] Task 1: Fix missing Wally packages and Rojo Workspace overwrite ($ignoreUnknownInstances).
- [x] Task 2: Patch VN UI default visibility overlap.
- [ ] Task 3: Complete HUD synchronization so `ChefPill` and `XPBar` reflect `DataManager` profile updates in real-time.
- [ ] Task 4: Rebuild fishing as one authoritative adapter-to-domain/ECS session flow; reject forged, premature, duplicate, timed-out, and disconnected results.
- [ ] Task 5: Verify all remote events (`CraftFunction`, `HarvestNode`, `CookingHit`, `CookingResult`) operate securely under server-authoritative validation.
