# Zundamon's kItchen V2

A cooperative, massively persistent, and highly interactive Roblox experience. 

This repository serves as the single source of truth for the codebase, utilizing a strictly domain-driven structure mapped for `Rojo`. It has been architected to support **Infinity Nikki** scale features: thousands of items, vast open worlds, and a seamless, lag-free UI.

## 🛠️ The Tech Stack (2026 Professional Standard)

We utilize **Mise** as our universal binary installer to ensure every contributor is using the exact same tooling. 

- **[Mise](https://mise.jdx.dev/)**: Toolchain manager (Replaces Aftman/Rokit).
- **[Rojo](https://rojo.space/)**: One-way file sync to live Team Create sessions.
- **[Wally](https://wally.run/)**: Package manager for our dependencies.
- **Matter**: High-performance Entity-Component-System (ECS) for game logic.
- **React-Lua**: Declarative UI component rendering.
- **ProfileService & ReplicaService**: Bulletproof, session-locked inventory and stat replication.

## 📁 Repository Structure

The code is strictly decoupled from Roblox's physical hierarchy, promoting long-term health and modularity.

```text
src/
├── client/          -> (Maps to StarterPlayerScripts)
├── server/          -> (Maps to ServerScriptService)
└── shared/          -> (Maps to ReplicatedStorage)
```

## 🚀 Getting Started

1. Install [Mise](https://mise.jdx.dev/getting-started.html).
2. Open a terminal in the root of this project and run:
   ```bash
   mise install
   wally install
   ```
3. Boot up your Roblox Studio session.
4. Run `rojo serve` to begin pushing live code to the Studio session!

## 📈 Game Design Philosophy (2026 Standards)

Zundamon's kItchen is designed with the modern Roblox algorithm in mind:
- **Social + Progression**: The game is a "living world" where players hang out, cook together, and share progression.
- **Retention Over Whales**: We prioritize D1/D7 retention and massive session lengths to trigger natural algorithmic growth. 
- **Fair Monetization**: Volume over high-prices. We utilize accessible gamepasses for convenience rather than forced pay-to-win mechanics.
- **UGC & Ownership**: Giving players tools to create within our world to build long-term attachment.
