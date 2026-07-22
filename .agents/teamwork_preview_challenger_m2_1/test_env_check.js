const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const htmlContent = fs.readFileSync(path.join(__dirname, '../../site/index.html'), 'utf8');
const wmScriptContent = fs.readFileSync(path.join(__dirname, '../../site/window_manager.js'), 'utf8');

const dom = new JSDOM(htmlContent, {
  runScripts: 'dangerously',
  resources: 'usable',
  url: 'http://localhost/'
});

const { window } = dom;
const { document } = window;

// Define viewport dimensions
Object.defineProperty(window, 'innerWidth', { value: 1024, writable: true });
Object.defineProperty(window, 'innerHeight', { value: 768, writable: true });
Object.defineProperty(document.documentElement, 'clientWidth', { value: 1024, writable: true });
Object.defineProperty(document.documentElement, 'clientHeight', { value: 768, writable: true });

// Load WindowManager module
const WindowManager = require('../../site/window_manager.js');

console.log('JSDOM Environment setup completed successfully.');
