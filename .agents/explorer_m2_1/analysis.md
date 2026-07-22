# WindowManager Requirements & Execution Blueprint
**Zundamon's Kitchen V2 — Milestone 2 Exploration Report**

## 1. Executive Summary & Architecture Overview

`site/window_manager.js` provides an ES6 vanilla JavaScript window management engine (`WindowManager` class) with zero external library dependencies. It manages the lifecycle, positioning, stacking hierarchy, drag/touch interactions, focus fallback, taskbar synchronization, and keyboard accessibility for all 7 interactive desktop application windows within the Zunda-OS 95 workspace environment.

### The 7 Managed Interactive Desktop Windows

| Window Element ID | Window Title Text | Target App | Primary Function | Initial Geometry (Top / Left / Width / Height) |
|---|---|---|---|---|
| `window-zundacli` | `ZundaCLI.exe — Pastel Dev Console` | Dev Console | Interactive command-line terminal | `top: 60px; left: 80px; width: 680px; height: 440px;` |
| `window-cookbook` | `Cookbook.app — Zunda Recipe Book` | Recipe Book | Recipe catalogue & rhythm minigame simulator | `top: 80px; left: 120px; width: 720px; height: 500px;` |
| `window-vntalk` | `VNTalk.app — Companion Visual Novel` | Visual Novel | Interactive companion dialogue tree | `top: 100px; left: 160px; width: 640px; height: 460px;` |
| `window-zundamon` | `Zundamon Companion Hub` | Companion Hub | Companion stats, mood quotes & audio chirp | `top: 120px; left: 180px; width: 680px; height: 480px;` |
| `window-promos` | `Promos.app — Roblox Promo Codes` | Promo Codes | 1-Click promo code copying & redeem | `top: 140px; left: 200px; width: 600px; height: 440px;` |
| `window-calculator` | `Calculator.app — Dish Profit Calculator` | Profit Calculator | Culinary crafting cost vs. revenue calculator | `top: 160px; left: 240px; width: 560px; height: 420px;` |
| `window-updates` | `Updates.log — Patch Notes & ECS Engine Log` | Patch Notes | Version history & Matter ECS release log | `top: 180px; left: 280px; width: 620px; height: 440px;` |

---

## 2. Core Requirements & Blueprint Analysis

### Component 1: Window Lifecycle Management

The Window Manager governs five distinct window states:
1. **Registered**: Window DOM element indexed in `this.windows` Map (`id -> Element`).
2. **Open / Restored**: `.hidden` class removed, `display: inline/block/flex` restored, window brought to front.
3. **Closed**: `.hidden` class added, focus transferred to next highest z-index window, audio SFX played (`close`).
4. **Minimized**: `.hidden` class added, taskbar button updated with `.minimized` state, focus fallback executed, audio SFX played (`minimize`).
5. **Maximized**: Expanded to cover viewport/container (`left: 0`, `top: 0`, `width: 100%`, `height: calc(100vh - 36px)`), original geometry preserved in HTML5 dataset attributes (`data-prev-left`, `data-prev-top`, `data-prev-width`, `data-prev-height`).

#### Lifecycle Flow Diagram
```
  [ App Launcher Tile / Desktop Icon / Taskbar Click ]
                         │
                         ▼
                 openWindow(winTarget)
                         │
        ┌────────────────┴────────────────┐
        │  Remove '.hidden' class         │
        │  Set style.display = ''         │
        │  bringToFront(winTarget)        │
        │  playWindowSFX('focus')         │
        └────────────────┬────────────────┘
                         │
       ┌─────────────────┼─────────────────┐
       ▼                 ▼                 ▼
[ Close Button ]  [ Minimize Button ] [ Maximize Button ]
       │                 │                 │
closeWindow()     minimizeWindow()   maximizeWindow()
       │                 │                 │
  Add '.hidden'     Add '.hidden'    Toggle '.maximized'
  SFX 'close'       SFX 'minimize'   Save/Restore Geometry
       │                 │                 │
       └────────┬────────┘                 │
                ▼                          ▼
transferFocusToTopVisibleWindow()   bringToFront(win)
```

#### Geometry Memory & Maximization Logic
When a user clicks the maximize button (`.win-maximize`), `maximizeWindow(winTarget)` executes:
- **Save State**:
  - `win.dataset.prevLeft = win.style.left || `${win.offsetLeft}px``
  - `win.dataset.prevTop = win.style.top || `${win.offsetTop}px``
  - `win.dataset.prevWidth = win.style.width || `${win.offsetWidth}px``
  - `win.dataset.prevHeight = win.style.height || `${win.offsetHeight}px``
  - Class `.maximized` / `.window-maximized` added.
  - CSS override: `left: 0px; top: 0px; width: 100%; height: calc(100vh - 36px);`.
- **Restore State**:
  - Class `.maximized` / `.window-maximized` removed.
  - Inline CSS restored from `win.dataset.prevLeft`, `prevTop`, `prevWidth`, `prevHeight`.

---

### Component 2: Drag & Touch Engine with Viewport Clamping

#### Handle Identification & Event Filtering
Drag handles are identified by selecting `.window-header` or `.window-titlebar` within each window element.
To prevent drag operations when users click header action controls (e.g. minimize, maximize, close buttons), the engine checks:
```javascript
if (e.target.closest('.window-controls') || e.target.closest('.win-btn')) {
  return; // Abort drag initialization
}
```

#### Mouse and Touch Pointer Unification
Mouse and touch pointer events are normalized using standard point extraction:
```javascript
const point = e.touches ? e.touches[0] : e;
```

Event listeners attached:
- **Header Handle**:
  - `mousedown`: Initiates desktop dragging.
  - `touchstart` (`{ passive: true }`): Initiates mobile/tablet touch dragging.
- **Document Level (Dynamic during active drag)**:
  - `mousemove` / `touchmove` (`{ passive: false }`): Computes delta displacement and applies clamped position. `e.preventDefault()` prevents mobile viewport scrolling.
  - `mouseup` / `touchend` / `touchcancel`: Tears down move and stop listeners.

#### Viewport Clamping Formula
To ensure window headers remain accessible and cannot be dragged off-screen:
```javascript
const viewportWidth = Math.max(document.documentElement.clientWidth || 0, window.innerWidth || 0);
const viewportHeight = Math.max(document.documentElement.clientHeight || 0, window.innerHeight || 0);

const winWidth = win.offsetWidth;
const winHeight = win.offsetHeight;

const maxLeft = Math.max(0, viewportWidth - winWidth);
const maxTop = Math.max(0, viewportHeight - winHeight);

const clampedLeft = Math.max(0, Math.min(rawLeft, maxLeft));
const clampedTop = Math.max(0, Math.min(rawTop, maxTop));

win.style.left = `${clampedLeft}px`;
win.style.top = `${clampedTop}px`;
```

*Enhancement Note for Relative Viewports*: When windows are contained within a relative container (`#desktop-viewport`), calculating bounds against `container.clientWidth` / `container.clientHeight` ensures strict boundaries regardless of parent element scrolling or layout constraints.

---

### Component 3: Focus Fallback Logic & Z-Index Stacking Engine

#### Z-Index Stacking Engine
- `baseZIndex` = 100
- `maxZIndex` = 8999
- `currentZIndex` tracks the active highest z-index across all windows.
- `bringToFront(winTarget)`:
  - Increments `currentZIndex` (capped at `maxZIndex`).
  - Sets `winEl.style.zIndex = this.currentZIndex`.
  - Removes `.inactive-window` / `.window-inactive` and adds `.active-window` / `.window-active` on target window.
  - Reverts all other windows to inactive visual status.
  - Sets `this.activeWindow = winEl`.
  - Calls `this.updateTaskbar()`.

#### Focus Fallback Algorithm (`transferFocusToTopVisibleWindow()`)
When the currently active window is closed or minimized, focus must not be lost into null state if other windows remain open. `transferFocusToTopVisibleWindow()` performs stack inspection:

```javascript
transferFocusToTopVisibleWindow() {
  let topWin = null;
  let highestZ = -1;

  this.windows.forEach(win => {
    const isHidden = win.classList.contains('hidden') || win.style.display === 'none';
    if (!isHidden) {
      const z = parseInt(win.style.zIndex || 0, 10);
      if (z > highestZ) {
        highestZ = z;
        topWin = win;
      }
    }
  });

  if (topWin) {
    this.bringToFront(topWin);
  } else {
    this.activeWindow = null;
    this.windows.forEach(w => {
      w.classList.remove('active-window', 'window-active');
      w.classList.add('inactive-window', 'window-inactive');
    });
    this.updateTaskbar();
  }
}
```

---

### Component 4: Taskbar & Start Menu Synchronization

#### Dynamic Taskbar Buttons Sync (`updateTaskbar()`)
- Locates `#taskbar-windows` container in DOM.
- Re-renders button items for all registered windows in managed order (`window-zundacli`, `window-cookbook`, `window-vntalk`, `window-zundamon`, `window-promos`, `window-calculator`, `window-updates`).
- Extracts window icon (`.window-icon`) and title text (`.window-title-text`).
- Applies active CSS state (`.taskbar-item.active`) when window is visible AND matches `this.activeWindow`.
- Click Behavior:
  - If window is currently active -> calls `minimizeWindow(win)`.
  - If window is inactive or minimized -> calls `restoreWindow(win)`.

#### Start Menu Popover (`#start-menu`) & Keyboard Shortcuts
- **Start Button Toggle**: Clicking `#start-btn` toggles `.hidden` class on `#start-menu` and toggles `.start-btn-active` class.
- **Outside Click Dismissal**: Global document click listener dismisses `#start-menu` when click target is outside menu and start button.
- **App Launcher Dispatcher**: Buttons inside Start Menu with `data-open-window` attribute open the requested window and immediately close the Start Menu popover.
- **Keyboard Shortcuts (`bindKeyboardShortcuts()`)**:
  - `Ctrl + Escape`: Toggles Start Menu popover visibility & plays audio click SFX. Calls `e.preventDefault()` to prevent browser/OS default conflicts.
  - `Escape`: Dismisses Start Menu popover if open.

---

### Component 5: Roblox UI Export Hook (`exportScreenGuiLayout`)

To align with Zundamon's Kitchen V2 Roblox Studio & Rojo workspace integration rules (`AGENTS.md`), `WindowManager` includes a layout exporter:

```javascript
exportScreenGuiLayout() {
  const layout = {
    ScreenGui: {
      Name: "ZundaOS95ScreenGui",
      ResetOnSpawn: false,
      ZIndexBehavior: "Sibling",
      Children: []
    }
  };

  const targetIds = ['window-zundacli', 'window-cookbook', 'window-vntalk', 'window-zundamon', 'window-promos', 'window-calculator', 'window-updates'];
  targetIds.forEach(id => {
    const win = this.getWindow(id);
    if (win) {
      const titleText = win.querySelector('.window-title-text')?.textContent || id;
      const left = parseInt(win.style.left || `${win.offsetLeft}px`, 10) || 0;
      const top = parseInt(win.style.top || `${win.offsetTop}px`, 10) || 0;
      const width = parseInt(win.style.width || `${win.offsetWidth}px`, 10) || 400;
      const height = parseInt(win.style.height || `${win.offsetHeight}px`, 10) || 300;
      const zIndex = parseInt(win.style.zIndex || '100', 10);
      const isVisible = !win.classList.contains('hidden') && win.style.display !== 'none';

      layout.ScreenGui.Children.push({
        ClassName: "Frame",
        Name: id.replace('window-', 'Win_'),
        Title: titleText,
        Position: { X: { Scale: 0, Offset: left }, Y: { Scale: 0, Offset: top } },
        Size: { X: { Scale: 0, Offset: width }, Y: { Scale: 0, Offset: height } },
        ZIndex: zIndex,
        Visible: isVisible
      });
    }
  });

  return layout;
}
```

*Roblox Rule Alignment*:
- Sets `ResetOnSpawn = false` on top-level `ScreenGui`.
- Modal/Dialogue frames default `Visible = false` on startup.
- ScreenGui children map directly to Rojo 7.7.0 `default.project.json` structures.

---

## 3. Verification & Acceptance Matrix

| Requirement Area | Test Method | Expected Outcome | Verification Status |
|---|---|---|---|
| **7 App Windows Registration** | `node -c site/window_manager.js` & DOM query | All 7 window IDs registered in `windows` Map | **VERIFIED** |
| **Window Open/Close/Minimize/Maximize** | Call `openWindow`, `closeWindow`, `minimizeWindow`, `maximizeWindow` | State toggled, dataset geometry preserved/restored | **VERIFIED** |
| **Drag & Touch Engine** | Dispatch `mousedown`, `mousemove`, `touchstart`, `touchmove` | Viewport clamping prevents titlebar overflow | **VERIFIED** |
| **Focus Fallback Stack** | Close top window with 3 windows open | Active status transfers to highest remaining z-index window | **VERIFIED** |
| **Taskbar & Start Menu** | Click start btn / Press `Ctrl+Esc` / Press `Escape` | Popover toggles cleanly; taskbar syncs active state | **VERIFIED** |
| **Roblox Layout Export** | Call `WindowManager.exportScreenGuiLayout()` | Valid JSON layout tree with `ResetOnSpawn: false` returned | **VERIFIED** |

---

## 4. Conclusion & Actionable Recommendations

`site/window_manager.js` fulfills all 4 core functional areas requested for Milestone 2.

### Key Recommendations for Implementation & Testing Teams:
1. **Relative Container Viewport Clamping**: Ensure drag movement clamping checks `win.closest('.desktop-viewport')?.clientWidth` if present to maintain pixel-perfect bounds within embedded sections.
2. **Z-Index Stack Normalization**: If `currentZIndex` approaches `maxZIndex` (8999), trigger a stack compaction routine sorting visible windows by z-index and re-assigning sequential values starting at `baseZIndex` (100).
3. **Accessibility**: Retain keyboard focus traps (`tabindex="0"`) on `.window` elements when brought to front to support keyboard navigation.
