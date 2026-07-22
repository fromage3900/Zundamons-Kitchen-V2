# Modular Window Lifecycle & Drag Engine Architecture Specification

**Target File**: `site/window_manager.js`  
**Project**: Zundamon's Kitchen V2 — Zunda-OS 95 CLI Launch Page & Creative Hub  
**Author**: Explorer 1 (Milestone 2)  
**Date**: 2026-07-21  

---

## 1. Overview & Objectives

The `site/window_manager.js` module provides a robust, object-oriented desktop window management system modeled after classic Windows 95 UI paradigms. It replaces inline script implementations in `site/index.html` with a modular, maintainable, and touch-compatible engine.

### Key Functional Goals
1. **Class/Object Architecture**: Encapsulate individual desktop applications (`ZundaCLI.exe`, `Cookbook.app`, `VNTalk.app`, `QuickStart.txt`) inside an extensible `WindowInstance` class, orchestrated by a central `WindowManager` singleton.
2. **Universal Drag Engine with Viewport Boundary Clamping**: Support both Mouse and Touch input events while strictly clamping window coordinates to ensure titlebars and window contents cannot be dragged off-screen under any screen resolution or device orientation.
3. **Sound Integration Triggers**: Trigger procedural audio synthesis hooks via `window.playWindowSFX()` on drag start, focus, minimize, maximize, and close events.
4. **Taskbar & Start Menu Synchronization**: Seamlessly manage active window z-indexes, taskbar button states, start menu focus, and window restore toggles.

---

## 2. Class & Object Architecture Specification

### 2.1 Object Model

```
+-----------------------------------------------------------------------+
|                             WindowManager                             |
+-----------------------------------------------------------------------+
| - windows: Map<string, WindowInstance>                                |
| - activeWindowId: string | null                                       |
| - zIndexCounter: number (starts at 100)                               |
| - taskbarContainer: HTMLElement                                       |
+-----------------------------------------------------------------------+
| + init(): void                                                        |
| + registerWindow(el: HTMLElement): WindowInstance                     |
| + getWindow(id: string): WindowInstance | undefined                   |
| + bringToFront(id: string): void                                      |
| + open(id: string): void                                              |
| + close(id: string): void                                             |
| + minimize(id: string): void                                          |
| + maximize(id: string): void                                          |
| + updateTaskbar(): void                                               |
| + getTaskbarHeight(): number                                          |
+-----------------------------------------------------------------------+
                                   | 1
                                   |
                                   | *
+-----------------------------------------------------------------------+
|                            WindowInstance                             |
+-----------------------------------------------------------------------+
| - manager: WindowManager                                              |
| - id: string                                                          |
| - element: HTMLElement                                                |
| - headerElement: HTMLElement                                          |
| - titleElement: HTMLElement                                           |
| - controlsElement: HTMLElement                                        |
| - bodyElement: HTMLElement                                            |
| - state: 'CLOSED' | 'OPEN' | 'MINIMIZED' | 'MAXIMIZED'                  |
| - isDragging: boolean                                                 |
| - preMaxPosition: { top: string, left: string, width: string, ... }   |
+-----------------------------------------------------------------------+
| + initDOMBindings(): void                                             |
| + initDragEngine(): void                                              |
| + focus(): void                                                       |
| + open(): void                                                        |
| + close(): void                                                       |
| + minimize(): void                                                    |
| + toggleMaximize(): void                                              |
| + clampPosition(top: number, left: number): { top: number, left: number }
+-----------------------------------------------------------------------+
```

### 2.2 DOM Structure & Element Bindings

Each desktop application window is represented in DOM by `<section class="window" id="window-<id>" data-window-id="<id>">`.

| Selector | Required Role | Lifecycle / Drag Handler |
|---|---|---|
| `.window` | Root window container | `mousedown` brings to front, handles z-index, visibility classes (`active-window`, `inactive-window`, `hidden`, `maximized`) |
| `.window-header` / `.window-titlebar` | Window title bar & drag handle | Attaches `mousedown` and `touchstart` drag engine listeners |
| `.window-title` / `.window-title-text` | Title display label | Source string for Taskbar button labels |
| `.window-controls` | Action button container | Container for `.win-btn` items |
| `.win-btn[data-action="minimize"]` | Minimize button | Invokes `instance.minimize()` |
| `.win-btn[data-action="maximize"]` | Maximize button | Invokes `instance.toggleMaximize()` |
| `.win-btn[data-action="close"]` | Close button | Invokes `instance.close()` |
| `.window-body` | Application view area | Contains app contents (CLI terminal, VN view, Recipe list, Notepad editor) |

### 2.3 Managed Application Instances

| App ID | DOM Selector | Initial Position (Inline CSS) | Initial State |
|---|---|---|---|
| `zundacli` | `#window-zundacli` | `top: 40px; left: 60px; width: 680px; height: 440px;` | `OPEN` (`active-window`) |
| `cookbook` | `#window-cookbook` | `top: 80px; left: 140px; width: 720px; height: 500px;` | `CLOSED` (`hidden`) |
| `vntalk` | `#window-vntalk` | `top: 100px; left: 220px; width: 640px; height: 460px;` | `CLOSED` (`hidden`) |
| `quickstart` | `#window-quickstart` | `top: 60px; left: 300px; width: 600px; height: 420px;` | `CLOSED` (`hidden`) |
| `trash` | `#window-trash` (dynamic/fallback) | `top: 120px; left: 180px; width: 400px; height: 300px;` | `CLOSED` (`hidden`) |

---

## 3. Drag Engine & Viewport Boundary Clamping Specification

### 3.1 Dual Pointer Event Lifecycle (Mouse & Touch)

To guarantee touch responsiveness on mobile/tablet devices without breaking desktop mouse UX, the drag engine subscribes to both input paradigms:

1. **Mouse Events**:
   - `mousedown` on `.window-header` -> Initiates drag. Attaches global `mousemove` and `mouseup` to `document`.
   - `mousemove` on `document` -> Updates position via clamped delta.
   - `mouseup` on `document` -> Cleans up listeners, releases drag state.

2. **Touch Events**:
   - `touchstart` on `.window-header` -> Captures initial `touches[0]` coordinate. Initiates drag. Attaches `touchmove` and `touchend`/`touchcancel` to `document`.
   - `touchmove` on `document` -> Calls `e.preventDefault()` to suppress document scrolling/pull-to-refresh. Updates position via clamped delta.
   - `touchend`/`touchcancel` on `document` -> Cleans up listeners, releases drag state.

### 3.2 Viewport Boundary Clamping Formula

When dragging starts, initial coordinates are cached:
- `startX = pointer.clientX`
- `startY = pointer.clientY`
- `initialLeft = element.offsetLeft`
- `initialTop = element.offsetTop`

During drag movement:
```js
const dx = pointer.clientX - startX;
const dy = pointer.clientY - startY;
const rawLeft = initialLeft + dx;
const rawTop = initialTop + dy;
```

#### Clamping Constraints Math
```js
const taskbarHeight = this.manager.getTaskbarHeight(); // e.g., 38px
const winWidth = element.offsetWidth;
const winHeight = element.offsetHeight;

// Compute maximum valid X and Y coordinates
const maxLeft = Math.max(0, window.innerWidth - winWidth);
const maxTop = Math.max(0, window.innerHeight - taskbarHeight - winHeight);

// Clamp left and top bounds strictly within [0, max]
const newLeft = Math.max(0, Math.min(rawLeft, maxLeft));
const newTop = Math.max(0, Math.min(rawTop, maxTop));
```

#### Offscreen Prevention Assurance
- `newLeft = 0` guarantees the left edge cannot cross off the left of the viewport.
- `newLeft = window.innerWidth - winWidth` guarantees the right edge of the window remains entirely visible inside the viewport.
- `newTop = 0` guarantees the top titlebar cannot be pushed above the top of the browser viewport.
- `newTop = window.innerHeight - taskbarHeight - winHeight` guarantees the bottom edge of the window does not sink behind or below the taskbar.

### 3.3 Maximized State Handling
If a window is in the `.maximized` state, drag interactions on the titlebar must be ignored (`if (this.isMaximized) return;`).

### 3.4 Responsive Viewport Resize Clamping
When the browser window is resized (`window.addEventListener('resize', ...)`), all non-maximized, visible windows are auto-clamped to prevent offscreen displacement caused by shrinking viewports.

---

## 4. Sound Engine Integration Specification

`site/window_manager.js` integrates directly with the procedural Web Audio API synthesizer defined in `site/assets/audio_engine.js`.

### 4.1 Audio Action Mapping

```js
function safePlayWindowSFX(action) {
  if (typeof window.playWindowSFX === 'function') {
    window.playWindowSFX(action);
  }
}
```

| Lifecycle Trigger Event | Action Passed to Audio Engine | Sound Characteristics |
|---|---|---|
| **Drag Start** (`mousedown` / `touchstart`) | `playWindowSFX('drag')` | Triangle wave frequency sweep (440Hz -> 110Hz, 15ms) |
| **Window Focus** (`bringToFront`) | `playWindowSFX('focus')` | Dual sine tone arpeggio (659Hz -> 987Hz) |
| **Window Minimize** | `playWindowSFX('minimize')` | Pitch drop triangle wave (987Hz -> 659Hz) |
| **Window Maximize / Restore** | `playWindowSFX('maximize')` | Ascending triad chord (659Hz -> 830Hz -> 987Hz) |
| **Window Close** | `playWindowSFX('close')` | Low sine decay sweep (350Hz -> 80Hz) |

---

## 5. Complete Production Code Implementation (`site/window_manager.js`)

Below is the complete ES6 class implementation designed for `site/window_manager.js`:

```javascript
/**
 * Zunda-OS 95 — Modular Window Manager & Drag Engine
 * Zundamon's Kitchen V2 (site/window_manager.js)
 * 
 * Features:
 * - OOP Window Lifecycle Management (ZundaCLI.exe, Cookbook.app, VNTalk.app, QuickStart.txt)
 * - Dual Mouse & Touch Drag Engine with strict Viewport Boundary Clamping
 * - Taskbar & Start Menu integration
 * - Procedural Audio SFX hooks via playWindowSFX()
 */

class WindowInstance {
  /**
   * @param {HTMLElement} element - The window section element
   * @param {WindowManager} manager - Reference to parent manager
   */
  constructor(element, manager) {
    this.element = element;
    this.manager = manager;
    this.id = element.dataset.windowId || element.id.replace('window-', '');
    
    this.headerElement = element.querySelector('.window-header') || element.querySelector('.window-titlebar');
    this.titleElement = element.querySelector('.window-title-text') || element.querySelector('.window-title');
    this.controlsElement = element.querySelector('.window-controls');
    this.bodyElement = element.querySelector('.window-body');

    this.isDragging = false;
    this.isMaximized = element.classList.contains('maximized');
    this.preMaxPosition = null;

    this.initDOMBindings();
    this.initDragEngine();
  }

  /**
   * Bind control buttons and focus handlers.
   */
  initDOMBindings() {
    // Bring window to front on click/tap inside window
    this.element.addEventListener('mousedown', () => {
      this.focus();
    });

    this.element.addEventListener('touchstart', () => {
      this.focus();
    }, { passive: true });

    // Window controls (minimize, maximize, close)
    if (this.controlsElement) {
      const buttons = this.controlsElement.querySelectorAll('.win-btn');
      buttons.forEach(btn => {
        btn.addEventListener('click', (e) => {
          e.stopPropagation();
          const action = btn.dataset.action;
          if (action === 'minimize') this.minimize();
          else if (action === 'maximize') this.toggleMaximize();
          else if (action === 'close') this.close();
        });

        btn.addEventListener('touchend', (e) => {
          e.stopPropagation();
          e.preventDefault();
          const action = btn.dataset.action;
          if (action === 'minimize') this.minimize();
          else if (action === 'maximize') this.toggleMaximize();
          else if (action === 'close') this.close();
        });
      });
    }
  }

  /**
   * Initialize Drag Engine with Mouse and Touch event support and Viewport Boundary Clamping.
   */
  initDragEngine() {
    if (!this.headerElement) return;

    let startX = 0;
    let startY = 0;
    let initialLeft = 0;
    let initialTop = 0;

    const startDrag = (clientX, clientY, target) => {
      // Ignore drags originating from control buttons
      if (target && target.closest('.window-controls')) return false;
      if (this.isMaximized) return false;

      this.isDragging = true;
      this.focus();
      this.manager.safePlaySFX('drag');

      startX = clientX;
      startY = clientY;
      initialLeft = this.element.offsetLeft;
      initialTop = this.element.offsetTop;
      return true;
    };

    const moveDrag = (clientX, clientY) => {
      if (!this.isDragging) return;

      const dx = clientX - startX;
      const dy = clientY - startY;

      const rawLeft = initialLeft + dx;
      const rawTop = initialTop + dy;

      const clamped = this.clampPosition(rawLeft, rawTop);
      this.element.style.left = `${clamped.left}px`;
      this.element.style.top = `${clamped.top}px`;
    };

    const stopDrag = () => {
      if (this.isDragging) {
        this.isDragging = false;
      }
    };

    // --- Mouse Drag Events ---
    this.headerElement.addEventListener('mousedown', (e) => {
      if (e.button !== 0) return; // Main button only
      if (!startDrag(e.clientX, e.clientY, e.target)) return;

      const onMouseMove = (moveEvent) => {
        moveDrag(moveEvent.clientX, moveEvent.clientY);
      };

      const onMouseUp = () => {
        stopDrag();
        document.removeEventListener('mousemove', onMouseMove);
        document.removeEventListener('mouseup', onMouseUp);
      };

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onMouseUp);
    });

    // --- Touch Drag Events ---
    this.headerElement.addEventListener('touchstart', (e) => {
      if (e.touches.length !== 1) return;
      const touch = e.touches[0];
      if (!startDrag(touch.clientX, touch.clientY, e.target)) return;

      const onTouchMove = (moveEvent) => {
        if (!this.isDragging) return;
        if (moveEvent.cancelable) moveEvent.preventDefault(); // Stop page scroll
        const t = moveEvent.touches[0];
        moveDrag(t.clientX, t.clientY);
      };

      const onTouchEnd = () => {
        stopDrag();
        document.removeEventListener('touchmove', onTouchMove);
        document.removeEventListener('touchend', onTouchEnd);
        document.removeEventListener('touchcancel', onTouchEnd);
      };

      document.addEventListener('touchmove', onTouchMove, { passive: false });
      document.addEventListener('touchend', onTouchEnd);
      document.addEventListener('touchcancel', onTouchEnd);
    });
  }

  /**
   * Clamps given left/top pixel positions within the browser viewport boundaries.
   * @param {number} rawLeft 
   * @param {number} rawTop 
   * @returns {{left: number, top: number}}
   */
  clampPosition(rawLeft, rawTop) {
    const taskbarHeight = this.manager.getTaskbarHeight();
    const winWidth = this.element.offsetWidth || 300;
    const winHeight = this.element.offsetHeight || 200;

    const maxLeft = Math.max(0, window.innerWidth - winWidth);
    const maxTop = Math.max(0, window.innerHeight - taskbarHeight - winHeight);

    const left = Math.max(0, Math.min(rawLeft, maxLeft));
    const top = Math.max(0, Math.min(rawTop, maxTop));

    return { left, top };
  }

  /**
   * Ensure window position stays inside viewport upon window resize.
   */
  enforceBounds() {
    if (this.isMaximized || this.isOpen()) {
      const currentLeft = this.element.offsetLeft;
      const currentTop = this.element.offsetTop;
      const clamped = this.clampPosition(currentLeft, currentTop);
      this.element.style.left = `${clamped.left}px`;
      this.element.style.top = `${clamped.top}px`;
    }
  }

  isOpen() {
    return !this.element.classList.contains('hidden');
  }

  focus() {
    this.manager.bringToFront(this.id);
  }

  open() {
    this.element.classList.remove('hidden');
    this.focus();
  }

  close() {
    this.element.classList.add('hidden');
    this.manager.safePlaySFX('close');
    this.manager.updateTaskbar();
  }

  minimize() {
    this.element.classList.add('hidden');
    this.manager.safePlaySFX('minimize');
    this.manager.updateTaskbar();
  }

  toggleMaximize() {
    this.isMaximized = !this.isMaximized;
    this.element.classList.toggle('maximized', this.isMaximized);
    this.manager.safePlaySFX('maximize');
    this.focus();
  }
}

class WindowManager {
  constructor() {
    this.windows = new Map();
    this.zIndexCounter = 100;
    this.activeWindowId = null;
    this.taskbarWindowsContainer = document.getElementById('taskbar-windows');
  }

  /**
   * Initialize all existing DOM windows and attach window resize listeners.
   */
  init() {
    const windowElements = document.querySelectorAll('.window');
    windowElements.forEach(el => {
      this.registerWindow(el);
    });

    // Re-clamp all windows when screen resizes
    window.addEventListener('resize', () => {
      this.windows.forEach(win => win.enforceBounds());
    });

    // Desktop shortcut triggers
    document.querySelectorAll('.desktop-shortcut').forEach(shortcut => {
      const targetId = shortcut.dataset.openWindow;
      if (!targetId) return;

      shortcut.addEventListener('click', () => {
        this.safePlayClick('down');
        this.open(targetId);
      });
    });

    // Start menu item triggers
    document.querySelectorAll('.start-item, .start-menu-item').forEach(item => {
      const targetId = item.dataset.openWindow;
      if (!targetId) return;

      item.addEventListener('click', () => {
        this.safePlayClick('down');
        this.open(targetId);
        // Hide start menu if function exists
        const startMenu = document.getElementById('start-menu');
        if (startMenu) startMenu.classList.add('hidden');
      });
    });

    this.updateTaskbar();
  }

  /**
   * Register a window element into manager.
   * @param {HTMLElement} element 
   * @returns {WindowInstance}
   */
  registerWindow(element) {
    const instance = new WindowInstance(element, this);
    this.windows.set(instance.id, instance);

    // Set initial focus if element starts active
    if (element.classList.contains('active-window')) {
      this.bringToFront(instance.id);
    }
    return instance;
  }

  getWindow(id) {
    const cleanId = id.replace('window-', '');
    return this.windows.get(cleanId);
  }

  bringToFront(id) {
    const targetWin = this.getWindow(id);
    if (!targetWin) return;

    this.zIndexCounter++;
    targetWin.element.style.zIndex = this.zIndexCounter;
    this.activeWindowId = targetWin.id;

    this.windows.forEach((win) => {
      if (win.id === targetWin.id) {
        win.element.classList.add('active-window', 'window-active');
        win.element.classList.remove('inactive-window', 'window-inactive');
      } else {
        win.element.classList.remove('active-window', 'window-active');
        win.element.classList.add('inactive-window', 'window-inactive');
      }
    });

    this.safePlaySFX('focus');
    this.updateTaskbar();
  }

  open(id) {
    const win = this.getWindow(id);
    if (win) {
      win.open();
    }
  }

  close(id) {
    const win = this.getWindow(id);
    if (win) {
      win.close();
    }
  }

  minimize(id) {
    const win = this.getWindow(id);
    if (win) {
      win.minimize();
    }
  }

  maximize(id) {
    const win = this.getWindow(id);
    if (win) {
      win.toggleMaximize();
    }
  }

  /**
   * Helper to retrieve computed taskbar height in pixels.
   * @returns {number}
   */
  getTaskbarHeight() {
    const taskbarEl = document.getElementById('taskbar');
    if (taskbarEl && taskbarEl.offsetHeight > 0) {
      return taskbarEl.offsetHeight;
    }
    const rootStyle = getComputedStyle(document.documentElement);
    const cssHeight = parseInt(rootStyle.getPropertyValue('--taskbar-height'), 10);
    return isNaN(cssHeight) ? 38 : cssHeight;
  }

  /**
   * Synchronize taskbar buttons with active and open windows.
   */
  updateTaskbar() {
    if (!this.taskbarWindowsContainer) return;
    this.taskbarWindowsContainer.innerHTML = '';

    this.windows.forEach(win => {
      if (win.isOpen()) {
        const isActive = (this.activeWindowId === win.id);
        const titleText = win.titleElement ? win.titleElement.textContent : win.id;

        const btn = document.createElement('button');
        btn.className = `taskbar-item ${isActive ? 'active' : ''}`;
        btn.dataset.windowTarget = `window-${win.id}`;
        btn.innerHTML = `<span class="tb-icon">🫛</span> ${titleText}`;

        btn.addEventListener('click', () => {
          this.safePlayClick('down');
          if (isActive) {
            win.minimize();
          } else {
            win.open();
          }
        });

        this.taskbarWindowsContainer.appendChild(btn);
      }
    });
  }

  safePlaySFX(action) {
    if (typeof window.playWindowSFX === 'function') {
      window.playWindowSFX(action);
    }
  }

  safePlayClick(type) {
    if (typeof window.playClickSFX === 'function') {
      window.playClickSFX(type);
    }
  }
}

// Global initialization export
window.WindowManager = WindowManager;

document.addEventListener('DOMContentLoaded', () => {
  window.windowManager = new WindowManager();
  window.windowManager.init();
});
```

---

## 6. HTML & Script Integration Strategy

To integrate `site/window_manager.js` into `site/index.html`:

1. **Add Script Reference in `index.html`**:
   Insert `<script src="window_manager.js"></script>` after `<script src="assets/audio_engine.js"></script>`.
2. **Remove Redundant Inline Window Drag Script**:
   Remove inline Window Manager functions (`bringToFront`, `openWindow`, `closeWindow`, `minimizeWindow`, `maximizeWindow`, `updateTaskbar`, and `windows.forEach` drag loop) from line 375 to line 525 of `index.html`.
3. **Global Compatibility**:
   Ensure `window.windowManager` exposes `.open(id)`, `.close(id)`, `.minimize(id)`, `.maximize(id)` for external command prompt commands (such as CLI `cook`, `cookbook`, `vntalk` commands).

---

## 7. Verification Method

1. **Mouse Drag Test**:
   - Click and drag `.window-header` on `ZundaCLI.exe`.
   - Drag to the far left (`x < 0`) -> Verify window clamps at `left = 0px`.
   - Drag to the top (`y < 0`) -> Verify window header clamps at `top = 0px`.
   - Drag to the bottom right -> Verify window bottom stops at `window.innerHeight - taskbarHeight` and right edge stops at `window.innerWidth - winWidth`.
2. **Touch Drag Test**:
   - Emulate touch device in Browser DevTools.
   - Touch and drag window titlebar -> Verify window moves smoothly without scrolling the background page.
3. **Sound Trigger Verification**:
   - Verify `playWindowSFX('drag')` fires on drag start, and `'focus'`, `'minimize'`, `'maximize'`, `'close'` fire on respective control button clicks.
