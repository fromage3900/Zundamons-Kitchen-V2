# Zundamon's kItchen V2

A cooperative, massively persistent, and highly interactive Roblox experience. 

This repository serves as the single source of truth for the codebase, utilizing a strictly domain-driven structure mapped for `Rojo`. It has been architected to support **Infinity Nikki** scale features: thousands of items, vast open worlds, and a seamless, lag-free UI.

## 🚀 Onboarding: Step-by-Step Developer Setup

Welcome to the team! To ensure a smooth, lag-free, and collision-free collaborative environment, follow these steps exactly:

### Step 1: Install the Toolchain
We use **Mise** as our universal binary installer. This guarantees everyone on the team is using the exact same version of our tools.
1. Install [Mise](https://mise.jdx.dev/getting-started.html).
2. Open your terminal in the root of this repository and run:
   ```bash
   mise install
   wally install
   ```
   *This automatically downloads Rojo, Selene, StyLua, Blink, and our Wally packages.*

### Step 2: The Studio Workflow (Team Create Safe)
We use a strict **Domain-Driven Architecture**. The code lives in VS Code; the map lives in Roblox Studio.
1. Open the Team Create place in Roblox Studio.
2. Open this repository in VS Code.
3. In your terminal, run `rojo serve`.
4. Connect the Rojo plugin in Studio. 

> [!TIP]
> **Safe Data Testing**: When you hit "Play" in Studio, the game automatically uses a **Mock DataStore**. This means you will not lock out other developers who are testing at the same time, and you will not corrupt the live player database. 

### Step 3: UI Design with Hoarcekat
If you are designing React-Lua UI, you do **not** need to playtest the game!
1. Install the [Hoarcekat plugin](https://github.com/Roblox/hoarcekat) in Studio.
2. Create a `.story.lua` file next to your component.
3. Open Hoarcekat in Studio to view your UI update in real-time as you type in VS Code.

### Step 4: The Iron Gate (Committing Code)
You cannot push bad code to `main`. 
1. Before committing, run `stylua src/` to auto-format your code.
2. Remove **ALL** `print()` and `warn()` statements. Our `selene` linter will reject your Pull Request if you leave them in.
3. Create a Pull Request and fill out the provided template. The GitHub Actions CI/CD pipeline will automatically verify your code.

## 🛠️ The Tech Stack (2026 Professional Standard)
- **[Mise](https://mise.jdx.dev/)**: Toolchain manager.
- **[Rojo](https://rojo.space/)**: File sync.
- **[Wally](https://wally.run/)**: Package manager.
- **[Blink](https://github.com/1axen/blink)**: Ultra-fast networking compiler.
- **Matter**: High-performance Entity-Component-System (ECS).
- **React-Lua**: Declarative UI component rendering.
- **ProfileService & ReplicaService**: Bulletproof stat replication.
