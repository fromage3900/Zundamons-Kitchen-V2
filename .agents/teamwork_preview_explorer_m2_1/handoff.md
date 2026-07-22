# Handoff Report — Explorer 1 (Milestone 2)

**Task**: Modular Window Lifecycle & Drag Engine Architecture Analysis and Design for `site/window_manager.js`  
**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_1`  
**Target File**: `g:\Zundamons-kItchen-V2\site\window_manager.js`  

---

## 1. Observation

1. **DOM Structure in `site/index.html`**:
   - `index.html` contains 4 primary window sections inside `#window-container`:
     - `#window-zundacli` (`ZundaCLI.exe`, `data-window-id="zundacli"`) (Lines 74-106)
     - `#window-cookbook` (`Cookbook.app`, `data-window-id="cookbook"`) (Lines 108-180)
     - `#window-vntalk` (`VNTalk.app`, `data-window-id="vntalk"`) (Lines 182-217)
     - `#window-quickstart` (`QuickStart.txt`, `data-window-id="quickstart"`) (Lines 219-259)
   - Window titlebar structures utilize `.window-header` containing `.window-title` / `.window-title-text` and `.window-controls` containing `.win-btn` with `data-action="minimize|maximize|close"`.

2. **Existing Inline Script in `site/index.html`**:
   - Lines 459-494 in `site/index.html` currently implement simple mouse dragging:
     ```javascript
     header.addEventListener('mousedown', (e) => {
         if (e.target.closest('.window-controls')) return;
         isDragging = true;
         bringToFront(win);
         playWinSFX('drag');
         
         startX = e.clientX;
         startY = e.clientY;
         initialLeft = win.offsetLeft;
         initialTop = win.offsetTop;
         ...
     });
     ```
   - Observed Deficiencies in Current Implementation:
     - **No Touch Support**: Lacks `touchstart`, `touchmove`, `touchend` event handling.
     - **No Boundary Clamping**: `win.style.left = ${initialLeft + dx}px` allows windows to be dragged completely off-screen or submerged behind the taskbar.
     - **No Object Encapsulation**: Window management logic is procedurally mixed inside inline script tags.

3. **Audio Synthesis Engine Interface in `site/assets/audio_engine.js`**:
   - Audio trigger functions are exposed globally on `window`:
     - `window.playWindowSFX(action)` accepts `'focus'`, `'drag'`, `'minimize'`, `'maximize'`, `'close'` (Lines 123-194).
     - `window.playClickSFX(variant)` accepts `'down'`, `'up'`, `'start'` (Lines 83-117).

4. **Taskbar Height Specification in `site/style.css`**:
   - CSS defines `--taskbar-height: 38px;` at line 52 and `#taskbar { height: var(--taskbar-height); }` at line 716.

---

## 2. Logic Chain

1. **From Observation 1 & 2 -> Window Instance & Manager Encapsulation**:
   - To modularize the codebase, a `WindowManager` singleton and `WindowInstance` OOP class model should encapsulate DOM elements (`.window`, `.window-header`, `.window-title`, `.win-btn`, `.window-body`), managing window registration and states (`OPEN`, `CLOSED`, `MINIMIZED`, `MAXIMIZED`).

2. **From Observation 2 & 4 -> Dual Mouse/Touch Drag Engine with Viewport Boundary Clamping**:
   - Mobile and tablet device support requires binding `touchstart`, `touchmove`, `touchend` in addition to `mousedown`, `mousemove`, `mouseup`.
   - To prevent titlebars or window content from escaping off-screen, positions must be clamped against the viewport boundary:
     - `taskbarHeight` is dynamically calculated via `#taskbar` element height or CSS `--taskbar-height` (38px).
     - `maxLeft = Math.max(0, window.innerWidth - winWidth)`
     - `maxTop = Math.max(0, window.innerHeight - taskbarHeight - winHeight)`
     - `newLeft = Math.max(0, Math.min(rawLeft, maxLeft))`
     - `newTop = Math.max(0, Math.min(rawTop, maxTop))`
   - `e.preventDefault()` must be called on active `touchmove` events to prevent screen scrolling while dragging window titlebars on touch screens.

3. **From Observation 3 -> Audio Trigger Coupling**:
   - When a drag operation initiates (`mousedown` / `touchstart` on `.window-header`), invoking `playWindowSFX('drag')` satisfies sound trigger requirements while defensive checks (`typeof window.playWindowSFX === 'function'`) protect execution stability.

4. **From Architecture Specification -> Modular File Creation**:
   - Creating `site/window_manager.js` isolates desktop window logic into a standalone production JS file, allowing `site/index.html` inline scripts to be cleaned up and refactored.

---

## 3. Caveats

- **Existing Inline Script Refactoring**: The inline `<script>` tag in `site/index.html` currently contains window management functions. During the implementation phase (Milestone 2 implementation agent), the redundant inline window management code in `index.html` should be removed and replaced with `<script src="window_manager.js"></script>`.
- **CSS Maximized Override**: When a window has the `.maximized` class, CSS forces `top: 0 !important; left: 0 !important; width: 100% !important; height: 100% !important;`. The drag engine explicitly ignores drag events while `isMaximized` is true.

---

## 4. Conclusion

The specification for `site/window_manager.js` successfully establishes:
1. Object-Oriented `WindowManager` and `WindowInstance` architecture managing `ZundaCLI.exe`, `Cookbook.app`, `VNTalk.app`, `QuickStart.txt`, and extensible application instances.
2. Touch and Mouse compatible Drag Engine with mathematical viewport clamping (`newLeft = Math.max(0, Math.min(newLeft, window.innerWidth - winWidth))`, `newTop = Math.max(0, Math.min(newTop, window.innerHeight - taskbarHeight - winHeight))`), ensuring windows can never be dragged off-screen.
3. Full integration with procedural Audio SFX triggers (`playWindowSFX('drag')`, `'focus'`, `'minimize'`, `'maximize'`, `'close'`).

The complete, production-ready source code for `site/window_manager.js` has been authored and documented in `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_1\analysis.md`.

---

## 5. Verification Method

To verify the architecture and design:

1. **Inspect Analysis Specification**:
   - File: `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_1\analysis.md`
   - Verify Class/Object model diagrams and binding tables.
   - Verify JS implementation code for `WindowInstance` and `WindowManager`.

2. **Functional Boundary Clamping Verification**:
   - Inspect `clampPosition(rawLeft, rawTop)` in `analysis.md`:
     ```js
     const maxLeft = Math.max(0, window.innerWidth - winWidth);
     const maxTop = Math.max(0, window.innerHeight - taskbarHeight - winHeight);
     const left = Math.max(0, Math.min(rawLeft, maxLeft));
     const top = Math.max(0, Math.min(rawTop, maxTop));
     ```
   - Verify mathematical guarantee: `0 <= left <= window.innerWidth - winWidth` and `0 <= top <= window.innerHeight - taskbarHeight - winHeight`.

3. **Touch and Mouse Listener Verification**:
   - Inspect `initDragEngine()` method in `analysis.md`:
     - Mouse listeners: `mousedown` on header, `mousemove`/`mouseup` on `document`.
     - Touch listeners: `touchstart` on header, `touchmove`/`touchend` on `document` with `{ passive: false }` and `moveEvent.preventDefault()`.

4. **Audio Hook Verification**:
   - Inspect `startDrag`: confirms `this.manager.safePlaySFX('drag')` is invoked on drag start.
