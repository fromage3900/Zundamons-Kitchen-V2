const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const htmlContent = fs.readFileSync(path.join(__dirname, '../../site/index.html'), 'utf8');

const dom = new JSDOM(htmlContent, {
  url: 'http://localhost/'
});

const { window } = dom;
const { document } = window;

global.window = window;
global.document = document;

Object.defineProperty(window, 'innerWidth', { value: 1024, writable: true });
Object.defineProperty(window, 'innerHeight', { value: 768, writable: true });
Object.defineProperty(document.documentElement, 'clientWidth', { value: 1024, writable: true });
Object.defineProperty(document.documentElement, 'clientHeight', { value: 768, writable: true });

const WindowManager = require('../../site/window_manager.js');

const wm = new WindowManager({
  container: document.getElementById('window-container'),
  taskbarWindows: document.getElementById('taskbar-windows'),
  startMenu: document.getElementById('start-menu'),
  startBtn: document.getElementById('start-btn')
});

wm.init();

console.log('WindowManager initialized, registered windows:', Array.from(wm.windows.keys()));
