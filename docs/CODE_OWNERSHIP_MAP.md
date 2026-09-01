# Code Ownership Map — src/

Generated 2026-08-25 from disk (272 Lua/Luau files, ~42.6k lines). This is the
"which file owns X / where does a new file go" reference. If a rule here
conflicts with reality, fix the doc in the same commit that moves the file.

## The problem this solves

`src/client` and `src/server` each grew four competing organizational schemes
(loose top-level scripts, `Controllers/`+`Services/`, `systems/`, `ui/`).
All four are load-bearing today. This doc makes the split intentional instead
of accidental, and gives one decision rule for new code.

## Decision rule for NEW files

1. Pure data/tuning (no behavior)            -> src/shared/ConfigurationFiles/
2. Shared logic both sides require            -> src/shared/Shared/Modules/
3. Matter ECS component                       -> src/shared/components/
4. Server domain logic (module, required)     -> src/server/Services/
5. Server Matter system / cross-service glue  -> src/server/systems/
6. Client module logic (no UI construction)   -> src/client/Controllers/
7. Client Matter system                       -> src/client/systems/
8. React/component-style UI (with stories)    -> src/client/ui/<domain>/
9. Studio-only tooling                        -> src/Plugins/ or src/server/DevTools/
10. NOTHING new goes loose in src/client or src/server top level.
    The ~60 loose .client.lua scripts are legacy; the goal is monotonic
    decrease. If you touch a loose script heavily, consider promoting it.

## src/client (5 schemes observed)

TOP-LEVEL LOOSE SCRIPTS (~57 files) — legacy, each self-bootstraps.
  Naming signals within the legacy pile:
    000_*        load-order-sensitive bootstrap (LegacyOverlayCleanup, RojoSyncMarker)
    *Script      panel/GUI scripts (CraftingScript, QuestScript, StoreScript, ...)
    *Controller  behavior without owning a panel (TutorialController, VNController,
                 SprintController, InventoryController, FXController)
    *UI/*Gui     newer panel scripts (ChallengeModeUI, PromoCodeGui, ...)
    *Client      client half of a server system (WeatherClient, ToolClient, FishingRodClient)
  Entry point: ClientMain.client.lua. HUD chain: HudBootstrap -> HudScript ->
  PlayerStateHud. PeaWheel chain: PeaWheelStarter -> PeaWheelBootstrap ->
  Controllers/PeaWheelController.

client/ConfigurationFiles/  (1 file, special)
  UIActionRegistry.lua — SINGLE SOURCE OF TRUTH for panel actions, keybinds,
  and THE one InputBegan hotkey dispatcher (line ~237). No other script may
  listen for panel hotkeys. Panels integrate via registerCallback(id, fn);
  unregistered dispatches queue for 8s then expire loudly.
  NOTE: this is PlayerScripts.ConfigurationFiles.UIActionRegistry — distinct
  from ReplicatedStorage's shared ConfigurationFiles tree. Easy to confuse.

client/Controllers/  (4 files) — module-style client logic, required not
  self-running: CookingController, HarvestController, PeaWheelController,
  ZundaSoundController (single-channel voice w/ barge-in; requires VoiceConfig
  in pcall).

client/systems/  (4 files) — Matter/loop systems: CompanionFollowSystem,
  ContentPreloader, StreamingSystem, cooking/CookingInputSystem.

client/ui/  — component-style UI, one folder per domain:
  ui/cooking/components/ (CookingHUD, PeaRhythmTrack) + stories/ (Hoarcekat)
  ui/inventory/components/ + hooks/ (useInventory)
  New built-UI goes here; legacy *Script panels stay put until promoted.

client/GuiService/ — EMPTY directory. Delete or claim.

## src/server (4 schemes observed)

TOP-LEVEL LOOSE SCRIPTS (~45 files) — legacy self-running .server.lua.
  Entry: ServerMain.server.lua (Matter loop; every system wrapped in pcall —
  one failing system must never kill the heartbeat).
  Big domains still loose: GuestManager, DataManager, InventoryServer,
  CraftManager, QuestManager, PlotManager, WeatherSystem, ZundaroomsServer.

server/Services/  (24 files) — the modern home for domain logic. Modules
  required by ServerMain/each other: PlayerDataService (ALL persistent player
  mutation goes through .mutate), CookingService, ServingService, GuestService,
  ChallengeModeService, DailyChallengeService, GachaService, PromoCodeService,
  RewardCore, etc.
  Exceptions inside Services/: ModifierBootstrap.server.lua and
  ScatterService.server.lua are self-running scripts, not modules.

server/systems/  (6 files) — cross-service wiring + Matter systems:
  EndlessLoopWiring (wires challenge/daily/serving; do NOT re-add dead
  IngredientGathered/GoldEarned listeners), ItemGatherSystem, FishingSystem,
  CompanionBuffSystem, CollectionTrackerServer, cooking/CookingValidationSystem.

server/DevTools/, server/Validation/, server/Plugins/ — studio-side dev
  tooling, input validators (HarvestValidator), runtime plugin scripts.

## src/shared (3 schemes)

shared/ConfigurationFiles/  (~60 files) — pure data/config. Mapped to
  ReplicatedStorage.ConfigurationFiles. Root lookups MUST be
  RS:WaitForChild("ConfigurationFiles") — never Shared:WaitForChild (fixed
  infinite-yield class of bugs, see PLAYTEST_NOTES).

shared/Shared/Config/ + shared/Shared/Modules/ — SECOND config+module tree
  (RS.Shared.*): pipeline configs (Blender/Architecture/Landscape) and shared
  logic (UIHelper, MeshProvider, ProceduralLandscape, ModifierStack + 6
  Modifiers/*). Rule of thumb: gameplay tuning -> ConfigurationFiles;
  pipeline/procgen + shared code -> Shared/.

shared/components/ — Matter ECS components (Companion, Owner, ItemDrop,
  BuffProvider, cooking/*, fishing/*).

Loose at shared root: AssetRegistry, DataSchema, QuestConfig (duplicate name
warning: shared/QuestConfig.lua AND shared/ConfigurationFiles/QuestConfig.lua
both exist — the ConfigurationFiles one is the canonical gameplay config).

## src/Plugins + src/Workspace

Plugins/ (14 files) — Studio authoring tools (ZundaWorldDecorator,
  ZundaMaterialAuthoring + their support modules).
Workspace/GameplayLoopArea/GatheringNodes/<Node>/descriptors.lua — per-node
  gathering descriptors, data-as-placement. The Workspace mapping carries
  $ignoreUnknownInstances: true and MUST keep it (Rojo would otherwise delete
  the whole map on sync).

## Known duplicate-name traps

- QuestConfig: shared root vs shared/ConfigurationFiles (canonical: ConfigurationFiles)
- CookingValidationSystem: server/Services/ AND server/systems/cooking/
- ConfigurationFiles: client/ (PlayerScripts) vs shared/ (ReplicatedStorage)
- ServingSystem.server.lua (loose) vs ServingService.lua (Services/) — Service is canonical
- server/NPCPatrolSystem.lua is a module loose among .server.lua scripts

## Migration direction (no big-bang refactor)

Loose scripts are frozen legacy: bugfixes in place, heavy feature work =
promote into the modern scheme first (Services/, Controllers/, systems/, ui/).
Track the loose-file counts (56 client / 46 server as of 2026-08-25) — they
should only go down.
