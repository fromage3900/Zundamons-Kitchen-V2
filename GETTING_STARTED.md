# Getting Started (Zundamon's kItchen V2)

Welcome to the team! We use a strict **domain-driven structure**, meaning our code lives in VS Code and our map lives in Roblox Studio. Follow these steps exactly to set up your environment.

---

## Step 1: Install the Toolchain

We use **Mise** as a universal package manager to guarantee everyone uses the exact same versions of Rojo, Wally, StyLua, and Selene.

1. Install **Mise**: [Getting Started Guide](https://mise.jdx.dev/getting-started.html)
2. Open your terminal in the root of the cloned repository.
3. Run the following commands:
```bash
mise install
wally install
```
*This installs Rojo, Linters, Formatters, and our Roblox package dependencies (Matter, React, ProfileService).*

> **No Mise?** If you are on an OS that struggles with Mise, you can alternatively use `npm install` to get `rojo` and `stylua` from npm. However, you will still need to manually install `wally` and `selene`.

---

## Step 2: The Studio Workflow

**Do not edit code in Studio!** All scripts and configuration files must be edited in VS Code.

1. Open the **Zundamon's kItchen V2** place in Roblox Studio (Team Create).
2. Open the repository in VS Code.
3. In your VS Code terminal, start Rojo:
```bash
rojo serve
```
4. In Roblox Studio, open the **Plugins** tab, click **Rojo**, and hit **Connect**.

Your scripts will now automatically sync to the game when you save them in VS Code.

---

## Step 3: Generating the Workspace (If starting from scratch)

If you are opening an empty baseplate instead of the live Team Create place, you need to populate the world.

1. With Rojo connected, open the Studio **View > Command Bar**.
2. Run this command to generate the terrain and placement nodes:
```lua
require(game.ServerScriptService.DevTools["PopulateWorld.dev"]).populate()
```

---

## Step 4: UI Development with Hoarcekat

If you are working on React-Lua UI, you don't need to press Play in Studio.

1. Install the [Hoarcekat plugin](https://github.com/Roblox/hoarcekat) in Roblox Studio.
2. Ensure your component has a corresponding `.story.lua` file.
3. Open the Hoarcekat plugin window to preview your UI live as you edit the code in VS Code.

---

## Step 5: Before You Commit (The Iron Gate)

Our CI pipeline will reject bad code. Before making a Pull Request:

1. **Format your code:**
```bash
stylua src/
```
2. **Lint your code:**
```bash
selene src/
```
*(Remember: `print()` and `warn()` are banned in production code and will cause Selene to fail. Remove them!)*
3. **Verify the build:**
```bash
rojo build default.project.json -o build/test.rbxl
```

---

## 🎉 You're ready!
Check out the [README.md](README.md) for an overview of our tech stack, and [CONTRIBUTING.md](CONTRIBUTING.md) for our code style and architecture rules.
