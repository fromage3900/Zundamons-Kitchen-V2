/**
 * WindowManager — Zunda-OS 95 Window Manager & GUI State Engine
 * Zundamon's Kitchen V2 (Zunda-OS 95 CLI Launch Page & Creative Hub)
 * ES6 Modular Window Manager Class with Zero External Dependencies.
 */

class WindowManager {
  constructor(options = {}) {
    this.container = options.container || (typeof document !== 'undefined' ? document.getElementById('window-container') || document.body : null);
    this.taskbarWindows = options.taskbarWindows || (typeof document !== 'undefined' ? document.getElementById('taskbar-windows') : null);
    this.startMenu = options.startMenu || (typeof document !== 'undefined' ? document.getElementById('start-menu') : null);
    this.startBtn = options.startBtn || (typeof document !== 'undefined' ? document.getElementById('start-btn') : null);

    this.baseZIndex = options.baseZIndex || 100;
    this.maxZIndex = options.maxZIndex || 8999;
    this.currentZIndex = this.baseZIndex;

    this.windows = new Map(); // id -> window DOM element
    this.activeWindow = null;

    WindowManager.instance = this;
  }

  init() {
    if (typeof document === 'undefined') return;
    this.registerWindows();
    this.bindWindowEvents();
    this.bindKeyboardShortcuts();
    this.updateTaskbar();
    this.transferFocusToTopVisibleWindow();
  }

  registerWindows() {
    if (typeof document === 'undefined') return;

    const managedIds = ['window-zundacli', 'window-cookbook', 'window-vntalk', 'window-quickstart'];

    // Discover any elements with .window class
    const foundElements = document.querySelectorAll('.window');
    foundElements.forEach(winEl => {
      const id = winEl.id || winEl.dataset.windowId || `window-${Math.random().toString(36).substr(2, 6)}`;
      this.windows.set(id, winEl);
    });

    // Ensure standard managed window IDs are registered
    managedIds.forEach(id => {
      const el = document.getElementById(id);
      if (el && !this.windows.has(id)) {
        this.windows.set(id, el);
      }
    });
  }

  bringToFront(winTarget) {
    const winEl = typeof winTarget === 'string' ? this.getWindow(winTarget) : winTarget;
    if (!winEl) return;

    this.currentZIndex = Math.min(this.maxZIndex, this.currentZIndex + 1);
    winEl.style.zIndex = this.currentZIndex;

    this.windows.forEach(w => {
      if (w === winEl) {
        w.classList.add('active-window', 'window-active');
        w.classList.remove('inactive-window', 'window-inactive');
        this.activeWindow = w;
      } else {
        w.classList.remove('active-window', 'window-active');
        w.classList.add('inactive-window', 'window-inactive');
      }
    });

    this.updateTaskbar();
  }

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

  openWindow(winTarget) {
    const win = typeof winTarget === 'string' ? this.getWindow(winTarget) : winTarget;
    if (!win) return;

    win.classList.remove('hidden');
    if (win.style.display === 'none') {
      win.style.display = '';
    }

    this.bringToFront(win);
    if (typeof window !== 'undefined' && typeof window.playWindowSFX === 'function') {
      window.playWindowSFX('focus');
    }
  }

  closeWindow(winTarget) {
    const win = typeof winTarget === 'string' ? this.getWindow(winTarget) : winTarget;
    if (!win) return;

    win.classList.add('hidden');
    if (typeof window !== 'undefined' && typeof window.playWindowSFX === 'function') {
      window.playWindowSFX('close');
    }
    this.transferFocusToTopVisibleWindow();
  }

  minimizeWindow(winTarget) {
    const win = typeof winTarget === 'string' ? this.getWindow(winTarget) : winTarget;
    if (!win) return;

    win.classList.add('hidden');
    if (typeof window !== 'undefined' && typeof window.playWindowSFX === 'function') {
      window.playWindowSFX('minimize');
    }
    this.transferFocusToTopVisibleWindow();
  }

  maximizeWindow(winTarget) {
    const win = typeof winTarget === 'string' ? this.getWindow(winTarget) : winTarget;
    if (!win) return;

    const isMaximized = win.classList.contains('maximized') || win.classList.contains('window-maximized');

    if (!isMaximized) {
      // Geometry Memory: save dataset properties
      win.dataset.prevLeft = win.style.left || `${win.offsetLeft}px`;
      win.dataset.prevTop = win.style.top || `${win.offsetTop}px`;
      win.dataset.prevWidth = win.style.width || `${win.offsetWidth}px`;
      win.dataset.prevHeight = win.style.height || `${win.offsetHeight}px`;

      win.classList.add('maximized', 'window-maximized');
      win.style.left = '0px';
      win.style.top = '0px';
      win.style.width = '100%';
      win.style.height = 'calc(100vh - 36px)';

      if (typeof window !== 'undefined' && typeof window.playWindowSFX === 'function') {
        window.playWindowSFX('maximize');
      }
      this.bringToFront(win);
    } else {
      // Restore geometry memory
      win.classList.remove('maximized', 'window-maximized');
      win.style.left = win.dataset.prevLeft || '60px';
      win.style.top = win.dataset.prevTop || '40px';
      win.style.width = win.dataset.prevWidth || '680px';
      win.style.height = win.dataset.prevHeight || '440px';

      if (typeof window !== 'undefined' && typeof window.playWindowSFX === 'function') {
        window.playWindowSFX('maximize');
      }
      this.bringToFront(win);
    }
  }

  restoreWindow(winTarget) {
    const win = typeof winTarget === 'string' ? this.getWindow(winTarget) : winTarget;
    if (!win) return;

    win.classList.remove('hidden');
    if (win.style.display === 'none') {
      win.style.display = '';
    }
    this.bringToFront(win);
  }

  getWindow(idOrSelector) {
    if (typeof document === 'undefined') return null;
    if (this.windows.has(idOrSelector)) {
      return this.windows.get(idOrSelector);
    }
    const cleanId = idOrSelector.replace(/^#/, '');
    if (this.windows.has(cleanId)) {
      return this.windows.get(cleanId);
    }

    // Try matching data-window-id attribute
    let el = document.getElementById(cleanId);
    if (!el) {
      el = document.querySelector(`[data-window-id="${cleanId}"]`) || document.querySelector(idOrSelector);
    }
    if (el) {
      this.windows.set(cleanId, el);
    }
    return el;
  }

  updateTaskbar() {
    if (typeof document === 'undefined') return;
    if (!this.taskbarWindows) {
      this.taskbarWindows = document.getElementById('taskbar-windows');
    }
    if (!this.taskbarWindows) return;

    this.taskbarWindows.innerHTML = '';

    const managedOrder = ['window-zundacli', 'window-cookbook', 'window-vntalk', 'window-quickstart'];

    const winsToRender = [];
    managedOrder.forEach(id => {
      const win = this.getWindow(id);
      if (win && !winsToRender.includes(win)) {
        winsToRender.push(win);
      }
    });

    this.windows.forEach(win => {
      if (!winsToRender.includes(win)) {
        winsToRender.push(win);
      }
    });

    winsToRender.forEach(win => {
      const winId = win.id || win.dataset.windowId;
      const titleText = win.querySelector('.window-title-text')?.textContent || winId;
      const iconHTML = win.querySelector('.window-icon')?.innerHTML || '🫛';
      const isHidden = win.classList.contains('hidden') || win.style.display === 'none';
      const isActive = !isHidden && (win === this.activeWindow || win.classList.contains('window-active'));

      const btn = document.createElement('button');
      btn.className = `taskbar-item ${isActive ? 'active' : ''} ${isHidden ? 'minimized' : ''}`;
      btn.dataset.windowTarget = winId;
      btn.innerHTML = `<span class="tb-icon">${iconHTML}</span> <span class="tb-title">${titleText}</span>`;

      btn.addEventListener('click', () => {
        if (typeof window !== 'undefined' && typeof window.playClickSFX === 'function') {
          window.playClickSFX('down');
        }

        if (isActive) {
          // Active window -> minimizes
          this.minimizeWindow(win);
        } else {
          // Inactive or minimized window -> restores & focuses
          this.restoreWindow(win);
        }
      });

      this.taskbarWindows.appendChild(btn);
    });
  }

  bindWindowEvents() {
    if (typeof document === 'undefined') return;

    this.windows.forEach(win => {
      const header = win.querySelector('.window-header') || win.querySelector('.window-titlebar');
      if (header) {
        this.setupDragEngine(win, header);
      }

      win.querySelectorAll('.win-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
          e.stopPropagation();
          const action = btn.dataset.action;
          if (action === 'minimize') this.minimizeWindow(win);
          else if (action === 'maximize') this.maximizeWindow(win);
          else if (action === 'close') this.closeWindow(win);
        });
      });

      ['mousedown', 'touchstart'].forEach(evtType => {
        win.addEventListener(evtType, () => {
          this.bringToFront(win);
        });
      });
    });
  }

  setupDragEngine(win, header) {
    if (typeof document === 'undefined') return;

    let isDragging = false;
    let startX = 0;
    let startY = 0;
    let initialLeft = 0;
    let initialTop = 0;

    const startDrag = (e) => {
      if (e.target.closest('.window-controls') || e.target.closest('.win-btn')) {
        return;
      }

      isDragging = true;
      this.bringToFront(win);

      if (typeof window !== 'undefined' && typeof window.playWindowSFX === 'function') {
        window.playWindowSFX('drag');
      }

      const point = e.touches ? e.touches[0] : e;
      startX = point.clientX;
      startY = point.clientY;
      initialLeft = win.offsetLeft;
      initialTop = win.offsetTop;

      const moveDrag = (moveEvent) => {
        if (!isDragging) return;

        const movePoint = moveEvent.touches ? moveEvent.touches[0] : moveEvent;
        const dx = movePoint.clientX - startX;
        const dy = movePoint.clientY - startY;

        const rawLeft = initialLeft + dx;
        const rawTop = initialTop + dy;

        // Viewport boundary clamping engine: Math.max(0, Math.min(pos, max))
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

        if (moveEvent.cancelable && moveEvent.touches) {
          moveEvent.preventDefault();
        }
      };

      const stopDrag = () => {
        if (!isDragging) return;
        isDragging = false;

        document.removeEventListener('mousemove', moveDrag);
        document.removeEventListener('mouseup', stopDrag);
        document.removeEventListener('touchmove', moveDrag);
        document.removeEventListener('touchend', stopDrag);
        document.removeEventListener('touchcancel', stopDrag);
      };

      document.addEventListener('mousemove', moveDrag);
      document.addEventListener('mouseup', stopDrag);
      document.addEventListener('touchmove', moveDrag, { passive: false });
      document.addEventListener('touchend', stopDrag);
      document.addEventListener('touchcancel', stopDrag);
    };

    header.addEventListener('mousedown', startDrag);
    header.addEventListener('touchstart', startDrag, { passive: true });
  }

  bindKeyboardShortcuts() {
    if (typeof window === 'undefined') return;

    window.addEventListener('keydown', (e) => {
      const startMenu = this.startMenu || document.getElementById('start-menu');
      const startBtn = this.startBtn || document.getElementById('start-btn');

      // Ctrl+Esc toggles Start Menu
      if (e.ctrlKey && e.key === 'Escape') {
        e.preventDefault();
        if (startMenu) {
          const isHidden = startMenu.classList.contains('hidden') || startMenu.style.display === 'none';
          if (isHidden) {
            startMenu.classList.remove('hidden');
            startMenu.style.display = '';
            if (startBtn) startBtn.classList.add('start-btn-active');
            if (typeof window.playClickSFX === 'function') window.playClickSFX('start');
          } else {
            startMenu.classList.add('hidden');
            if (startBtn) startBtn.classList.remove('start-btn-active');
          }
        }
      } else if (e.key === 'Escape') {
        // Escape alone closes Start Menu if visible
        if (startMenu && !startMenu.classList.contains('hidden') && startMenu.style.display !== 'none') {
          startMenu.classList.add('hidden');
          if (startBtn) startBtn.classList.remove('start-btn-active');
        }
      }
    });
  }

  /**
   * Roblox UI Export Hook
   * Exposes JSON layout structure mapping windows directly to Roblox ScreenGui frame hierarchies.
   */
  exportScreenGuiLayout() {
    const layout = {
      ScreenGui: {
        Name: "ZundaOS95ScreenGui",
        ResetOnSpawn: false,
        ZIndexBehavior: "Sibling",
        Children: []
      }
    };

    const targetIds = ['window-zundacli', 'window-cookbook', 'window-vntalk', 'window-quickstart'];
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
          Position: {
            X: { Scale: 0, Offset: left },
            Y: { Scale: 0, Offset: top }
          },
          Size: {
            X: { Scale: 0, Offset: width },
            Y: { Scale: 0, Offset: height }
          },
          ZIndex: zIndex,
          Visible: isVisible,
          Children: [
            {
              ClassName: "Frame",
              Name: "Header",
              Size: { X: { Scale: 1, Offset: 0 }, Y: { Scale: 0, Offset: 28 } }
            },
            {
              ClassName: "Frame",
              Name: "Body",
              Position: { X: { Scale: 0, Offset: 0 }, Y: { Scale: 0, Offset: 28 } },
              Size: { X: { Scale: 1, Offset: 0 }, Y: { Scale: 1, Offset: -28 } }
            }
          ]
        });
      }
    });

    return layout;
  }

  static exportScreenGuiLayout() {
    if (WindowManager.instance) {
      return WindowManager.instance.exportScreenGuiLayout();
    }
    const tempManager = new WindowManager();
    tempManager.registerWindows();
    return tempManager.exportScreenGuiLayout();
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = WindowManager;
}
if (typeof window !== 'undefined') {
  window.WindowManager = WindowManager;
}
