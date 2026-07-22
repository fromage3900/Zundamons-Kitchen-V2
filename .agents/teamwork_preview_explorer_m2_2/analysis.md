# Zunda-OS 95 Window Manager Architecture & Design Specification

**Module**: `site/window_manager.js`  
**Milestone**: Milestone 2 — Modular Desktop & Window Manager Engine  
**Author**: Explorer 2  
**Target Path**: `g:\Zundamons-kItchen-V2\site\window_manager.js`  

---

## Executive Summary

This document specifies the architecture, data structures, focus depth stacking algorithms, state engine transitions, taskbar synchronization logic, keyboard shortcut handling, and Roblox ScreenGui layout export hooks for `site/window_manager.js`.

The Window Manager transforms static HTML sections into a retro Windows 95 desktop windowing environment with Zunda edamame aesthetics (`#2e7d32`, `#4caf50`, `#8bc34a`, `#e8f5e9`). It manages floating app windows (`ZundaCLI.exe`, `Cookbook.app`, `VNTalk.app`, `QuickStart.txt`), handling active window depth focus, active focus fallback upon minimize/close, window state toggles (Minimize, Maximize/Restore, Close), Taskbar item sync, and global keyboard shortcuts (`Ctrl+Esc` and `Escape`).

---

## 1. Z-Index Depth Stack & Active Focus Management

### 1.1 Desktop Layering Hierarchy

To avoid z-index conflicts between floating windows, taskbar UI popups, and visual overlays, Zunda-OS 95 defines strict z-index ranges:

| Layer / Component | Z-Index Range | Description |
|---|---|---|
| Desktop Background & Canvas | `0` | `canvas#particle-canvas` (edamame particles) |
| Desktop Icons Grid | `1` | `#desktop-icons` shortcuts grid |
| Window Stack Container | `2` | `#window-container` parent wrapper |
| **Floating Windows Stack** | **`100` – `8999`** | **Managed dynamically by `WindowManager`** |
| Fixed Taskbar | `9000` | `#taskbar` container |
| Start Menu Popup | `9500` | `#start-menu` popover |
| CRT Scanline Overlay | `10000` | `#crt-overlay` (CRT glass glow & scanlines) |

### 1.2 Focus Stack Data Model & Re-stacking Algorithm

Instead of naively incrementing a global `zIndex` counter towards infinity (which causes numeric drift and risks breaching the `9000` taskbar threshold), `WindowManager` maintains an ordered **Focus Stack Array**:

```javascript
// Array of window DOM elements ordered from bottom-most (index 0) to top-most active (last index)
this.focusStack = [];
```

#### Focus Transfer Algorithm (`focusWindow(win)`):
1. **Validation**: Check if `win` exists, is registered, and is not minimized (`.window-minimized`).
2. **Stack Reordering**:
   - If `win` is already in `focusStack`, splice it out of its current position.
   - Push `win` to the end (top) of `focusStack`.
3. **Z-Index Re-assignment**:
   - Loop through `focusStack` from `i = 0` to `focusStack.length - 1`.
   - Set `winElement.style.zIndex = 100 + i`.
4. **CSS Active / Inactive Class Synchronization**:
   - For the top-most window (`i === focusStack.length - 1`):
     - Add `.window-active` AND `.active-window`.
     - Remove `.window-inactive` AND `.inactive-window`.
     - Remove aria attribute `aria-selected="false"`, set `aria-selected="true"`.
   - For all other windows (`i < focusStack.length - 1`):
     - Remove `.window-active` AND `.active-window`.
     - Add `.window-inactive` AND `.inactive-window`.
     - Set `aria-selected="false"`.
5. **Audio Trigger**: Fire `window.playWindowSFX('focus')` if audio synthesizer is present.
6. **Taskbar Synchronization**: Execute `syncTaskbar()` to highlight the active window button in `#taskbar-windows`.

### 1.3 Active Focus Fallback Mechanism

When an active window is closed or minimized, leaving no focused window produces a degraded user experience. `WindowManager` implements an automatic **Active Focus Fallback**:

```javascript
/**
 * Executes focus fallback when the active window is hidden, minimized, or closed.
 */
transferFocusToTopVisibleWindow() {
    // 1. Filter focusStack for windows that are currently visible
    const visibleWindows = this.focusStack.filter(win => {
        const isHidden = win.classList.contains('hidden');
        const isMinimized = win.classList.contains('window-minimized');
        return !isHidden && !isMinimized;
    });

    // 2. If at least one visible window remains, focus the top-most (last in array)
    if (visibleWindows.length > 0) {
        const topWindow = visibleWindows[visibleWindows.length - 1];
        this.focusWindow(topWindow, /* skipAudio */ false);
    } else {
        // 3. No visible windows left: deactivate all taskbar items
        this.clearTaskbarActiveState();
    }
}
```

---

## 2. Minimize, Maximize & Restore State Engine & Taskbar Sync

### 2.1 Window Lifecycle States & CSS Mapping

Each window instance transitions between 4 discrete states:

```
          [ CLOSED ] (hidden, no taskbar item)
              |
              | openWindow(winId)
              v
          [ NORMAL ] (visible, cascaded size, taskbar item active)
           /        \
minimizeWindow()     maximizeWindow() / restoreWindow()
         v            v
  [ MINIMIZED ]    [ MAXIMIZED ] (full viewport, restore icon)
  (content hidden,  (top:0, left:0, width:100%, height:calc(100%-38px))
   taskbar item retained)
```

| State | CSS Classes | Inline Style Properties | Taskbar Button State | Maximize Button Icon |
|---|---|---|---|---|
| **CLOSED** | `.hidden` | `display: none` | Removed from taskbar | `🗖` (`□`) |
| **NORMAL** | (no state class) | `top: Xpx; left: Ypx; width: Wpx; height: Hpx;` | Retained, `.active` if focused | `🗖` (`□`) |
| **MINIMIZED** | `.window-minimized`, `.hidden` | `display: none` | Retained, `.minimized` (dimmed) | `🗖` (`□`) |
| **MAXIMIZED** | `.maximized` | `top: 0; left: 0; width: 100%; height: 100%;` | Retained, `.active` if focused | `🗗` (`❐`) |

### 2.2 Maximize & Restore Cascading Memory

Before setting `.maximized`, `WindowManager` saves original window coordinates and dimensions into HTML5 `dataset` properties so they can be perfectly restored:

```javascript
maximizeWindow(win) {
    if (!win) return;
    if (win.classList.contains('maximized')) {
        // Restore to normal cascaded dimensions
        this.restoreWindow(win);
        return;
    }

    // Save current cascaded geometry into dataset
    win.dataset.prevTop = win.style.top || `${win.offsetTop}px`;
    win.dataset.prevLeft = win.style.left || `${win.offsetLeft}px`;
    win.dataset.prevWidth = win.style.width || `${win.offsetWidth}px`;
    win.dataset.prevHeight = win.style.height || `${win.offsetHeight}px`;

    // Apply maximized state
    win.classList.add('maximized');
    
    // Update Maximize/Restore control button icon and title
    const maxBtn = win.querySelector('.win-btn.win-maximize');
    if (maxBtn) {
        maxBtn.textContent = '🗗'; // Restore overlapping squares icon
        maxBtn.title = 'Restore Window';
        maxBtn.setAttribute('aria-label', 'Restore Window');
    }

    this.focusWindow(win);
    if (typeof window.playWindowSFX === 'function') window.playWindowSFX('maximize');
}

restoreWindow(win) {
    if (!win) return;
    win.classList.remove('maximized');

    // Restore saved geometry if available
    if (win.dataset.prevTop) win.style.top = win.dataset.prevTop;
    if (win.dataset.prevLeft) win.style.left = win.dataset.prevLeft;
    if (win.dataset.prevWidth) win.style.width = win.dataset.prevWidth;
    if (win.dataset.prevHeight) win.style.height = win.dataset.prevHeight;

    // Reset button icon to single square
    const maxBtn = win.querySelector('.win-btn.win-maximize');
    if (maxBtn) {
        maxBtn.textContent = '🗖';
        maxBtn.title = 'Maximize Window';
        maxBtn.setAttribute('aria-label', 'Maximize Window');
    }

    this.focusWindow(win);
}
```

### 2.3 Taskbar Sync Engine Architecture

Taskbar buttons in `#taskbar-windows` reflect open/minimized windows. **Crucially, minimized windows MUST retain their taskbar button** so users can restore them.

#### Taskbar Sync Logic (`syncTaskbar()`):
1. Clear existing items inside `#taskbar-windows`.
2. Iterate through all registered windows:
   - If window is **CLOSED** (`win.classList.contains('hidden')` WITHOUT `.window-minimized`), skip rendering taskbar button.
   - If window is **OPEN** or **MINIMIZED**:
     - Create standard Win95 taskbar button (`<button class="taskbar-item">`).
     - Set `data-window-target = win.id`.
     - Extract icon (`.window-icon`) and text (`.window-title-text`).
     - Determine state:
       - If `win` is `.window-active` (and not minimized): add class `.active`.
       - If `win` is `.window-minimized`: add class `.minimized`.
     - Attach click event listener.

#### Taskbar Button Click Interaction Matrix:

```javascript
onTaskbarItemClick(win) {
    const isActive = win.classList.contains('window-active') && !win.classList.contains('window-minimized');
    const isMinimized = win.classList.contains('window-minimized');

    if (isActive) {
        // Clicking taskbar item of currently ACTIVE window -> MINIMIZE IT
        this.minimizeWindow(win);
    } else if (isMinimized) {
        // Clicking taskbar item of MINIMIZED window -> RESTORE & FOCUS IT
        this.unminimizeWindow(win);
    } else {
        // Clicking taskbar item of INACTIVE visible window -> BRING TO FRONT & FOCUS IT
        this.focusWindow(win);
    }
}
```

---

## 3. Global Keyboard Shortcuts Architecture

`WindowManager` attaches a global keyboard handler to `document` listening for keydown events.

### 3.1 Shortcut Map & Interception Rules

| Shortcut | Action | Behavior Details |
|---|---|---|
| `Ctrl + Esc` | Toggle Start Menu | Prevent browser default, toggle `#start-menu` visibility, toggle `#start-btn` `.start-btn-active` class. |
| `Escape` | Close Start Menu | If `#start-menu` is visible, close it and deactivate `#start-btn`. |

### 3.2 Event Handler Specification

```javascript
handleKeyDown(e) {
    // 1. Ctrl + Esc -> Toggle Start Menu
    if (e.ctrlKey && (e.key === 'Escape' || e.code === 'Escape')) {
        e.preventDefault();
        this.toggleStartMenu();
        return;
    }

    // 2. Escape -> Close Start Menu if open
    if (e.key === 'Escape' || e.code === 'Escape') {
        const startMenu = document.getElementById('start-menu');
        if (startMenu && !startMenu.classList.contains('hidden')) {
            e.preventDefault();
            this.closeStartMenu();
            return;
        }
    }
}
```

---

## 4. Roblox ScreenGui Layout Export Hooks

In accordance with project scope (Zunda-OS 95 retro design mapping to Roblox Studio ScreenGui components), `WindowManager` includes a layout exporter:

```javascript
exportRobloxScreenGuiLayout() {
    const layoutData = {};
    const desktopEl = document.getElementById('desktop');
    const desktopWidth = desktopEl ? desktopEl.clientWidth : window.innerWidth;
    const desktopHeight = desktopEl ? desktopEl.clientHeight : window.innerHeight;

    this.focusStack.forEach((win) => {
        const winId = win.dataset.windowId || win.id;
        const rect = win.getBoundingClientRect();
        
        layoutData[winId] = {
            Size: `UDim2.new(0, ${Math.round(rect.width)}, 0, ${Math.round(rect.height)})`,
            Position: `UDim2.new(0, ${Math.round(win.offsetLeft)}, 0, ${Math.round(win.offsetTop)})`,
            RelativePosition: `UDim2.new(${ (win.offsetLeft / desktopWidth).toFixed(3) }, 0, ${ (win.offsetTop / desktopHeight).toFixed(3) }, 0)`,
            ZIndex: parseInt(win.style.zIndex || '100', 10),
            Visible: !win.classList.contains('hidden') && !win.classList.contains('window-minimized'),
            Maximized: win.classList.contains('maximized')
        };
    });

    return layoutData;
}
```

---

## 5. Complete Class API & Data Model for `site/window_manager.js`

```javascript
/**
 * Zunda-OS 95 Modular Window Manager Engine
 * File: site/window_manager.js
 */
class WindowManager {
    constructor() {
        this.windows = [];
        this.focusStack = [];
        this.taskbarContainer = null;
        this.startBtn = null;
        this.startMenu = null;
        this.initialized = false;
    }

    // --- Lifecycle Methods ---
    init() { ... }
    registerWindow(winElement) { ... }
    
    // --- Focus Stack Engine ---
    focusWindow(win, skipAudio = false) { ... }
    transferFocusToTopVisibleWindow() { ... }
    
    // --- Window Actions Engine ---
    openWindow(winId) { ... }
    closeWindow(win) { ... }
    minimizeWindow(win) { ... }
    unminimizeWindow(win) { ... }
    maximizeWindow(win) { ... }
    restoreWindow(win) { ... }
    
    // --- Taskbar & Start Menu Sync ---
    syncTaskbar() { ... }
    toggleStartMenu() { ... }
    openStartMenu() { ... }
    closeStartMenu() { ... }
    
    // --- Drag & Touch Interaction ---
    initWindowDragging(win) { ... }
    
    // --- Keyboard Shortcuts ---
    setupKeyboardShortcuts() { ... }
    handleKeyDown(e) { ... }
    
    // --- Roblox ScreenGui Export ---
    exportRobloxScreenGuiLayout() { ... }
}

// Export singleton instance to window object
window.ZundaWindowManager = new WindowManager();
```

---

## 6. Verification Strategy & Implementation Checklists

### Verification Checklist for Implementer (Worker):
1. **Focus Depth Stack**:
   - Verify clicking any part of window titlebar, menu, or body brings it to front and updates `.window-active` / `.window-inactive` CSS classes.
   - Verify `style.zIndex` remains within `100` to `8999`.
2. **Active Focus Fallback**:
   - Open 3 windows (`ZundaCLI`, `Cookbook`, `VNTalk`). Focus `VNTalk`.
   - Close or minimize `VNTalk`. Verify focus automatically transfers to `Cookbook` (top remaining visible window) and its taskbar button becomes `.active`.
3. **Minimize / Maximize / Taskbar Retention**:
   - Minimize a window. Verify window content hides (`display: none` / `.window-minimized`) BUT taskbar button remains in `#taskbar-windows`.
   - Click taskbar button of minimized window. Verify it restores and receives active focus.
   - Click taskbar button of active window. Verify it minimizes.
   - Click maximize button (`🗖`). Verify window fills viewport and button icon changes to restore (`🗗`). Click again to restore original cascade coordinates.
4. **Keyboard Shortcuts**:
   - Press `Ctrl+Esc`. Verify Start Menu toggles open/closed.
   - Open Start Menu, press `Escape`. Verify Start Menu closes.
