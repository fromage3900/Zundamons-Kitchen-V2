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

## Current Project State (V2 Migration - Phase 6 Complete)

| Component | Status | Details |
|-----------|--------|---------|
| **Rojo Server** | ✅ ACTIVE (Port 34872) | Rojo 7.7.0 running; `$ignoreUnknownInstances: true` enabled on Workspace to preserve Studio level design |
| **Wally Packages** | ✅ INSTALLED | Matter 0.8.4, React 17.1.0, ProfileService, ReplicaService loaded in `Packages/` & `ServerPackages/` |
| **UI Bootstrapping** | ✅ DECOUPLED | All UI scripts load dynamically into `PlayerGui` with `ResetOnSpawn = false` |
| **VN Dialogue UI** | ✅ FIXED | Hidden by default on startup (`panel.Visible = false`) to eliminate UI overlaps |
| **Timed Cooking** | ✅ INTEGRATED | Client minigame linked to `CookingValidationSystem` Matter ECS system |
| **Harvesting & Tools** | ✅ ACTIVE | `LocalTools` dynamically binds to inventory tools via `CollectionService` |
| **Fishing** | ✅ ECS-BACKED | `FishingMinigameScript` now backed by `FishingSystem` Matter ECS module with server-authoritative session management |

---

## Active Task Backlog for Next 2 Hours

- [x] Task 1: Fix missing Wally packages and Rojo Workspace overwrite ($ignoreUnknownInstances).
- [x] Task 2: Patch VN UI default visibility overlap.
- [ ] Task 3: Complete HUD synchronization so `ChefPill` and `XPBar` reflect `DataManager` profile updates in real-time.
- [x] Task 4: Connect `FishingMinigameScript` directly to a dedicated `FishingSystem` ECS module.
- [ ] Task 5: Verify all remote events (`CraftFunction`, `HarvestNode`, `CookingHit`, `CookingResult`) operate securely under server-authoritative validation.
