/**
 * Empirical UI/UX Test Suite for Milestone 1
 * Location: g:\Zundamons-kItchen-V2\.agents\challenger_m1_2\test_m1_ui.js
 */

const fs = require('fs');
const path = require('path');

const siteDir = path.join(__dirname, '..', '..', 'site');
const htmlPath = path.join(siteDir, 'index.html');
const jsPath = path.join(siteDir, 'app.js');
const cssPath = path.join(siteDir, 'style.css');

const htmlContent = fs.readFileSync(htmlPath, 'utf8');
const jsContent = fs.readFileSync(jsPath, 'utf8');
const cssContent = fs.readFileSync(cssPath, 'utf8');

console.log("=================================================");
console.log("   EMPIRICAL TEST SUITE — MILESTONE 1 UI/UX");
console.log("=================================================\n");

let passed = 0;
let failed = 0;

function assert(condition, message, details = '') {
  if (condition) {
    console.log(`[PASS] ${message}`);
    passed++;
  } else {
    console.log(`[FAIL] ${message}`);
    if (details) console.log(`       Details: ${details}`);
    failed++;
  }
}

// ----------------------------------------------------------------------------
// 1. Anchor links & CTA targets
// ----------------------------------------------------------------------------
console.log("--- 1. Anchor Links & CTA Button Target Checks ---");

const anchorMatches = Array.from(htmlContent.matchAll(/<a\s+[^>]*href=["'](#[\w-]+)["'][^>]*>/gi));
const anchorTargets = anchorMatches.map(m => m[1]);

console.log(`Found ${anchorTargets.length} internal anchor links: ${anchorTargets.join(', ')}`);

anchorTargets.forEach(target => {
  const id = target.substring(1);
  const idRegex = new RegExp(`id=["']${id}["']`, 'i');
  const exists = idRegex.test(htmlContent);
  assert(exists, `Anchor target '${target}' exists in index.html`, exists ? `Found element with id="${id}"` : `No element with id="${id}" in index.html!`);
});

// Check specific anchor targets required: #hero, #features, #desktop, #promos, #recipes
const requiredAnchors = ['#hero', '#features', '#desktop', '#promos', '#recipes'];
requiredAnchors.forEach(anc => {
  const id = anc.substring(1);
  const exists = new RegExp(`id=["']${id}["']`, 'i').test(htmlContent);
  assert(exists, `Required anchor target '${anc}' exists`, exists ? `Element #${id} present` : `MISSING #${id} in index.html`);
});

// Check CTA Buttons
const ctaMatches = Array.from(htmlContent.matchAll(/class=["'][^"']*cta-btn[^"']*["']/gi));
assert(ctaMatches.length >= 3, `Hero banner contains CTA buttons (Found: ${ctaMatches.length})`);

// ----------------------------------------------------------------------------
// 2. Promo Code Copy Buttons & Toast Notification Logic
// ----------------------------------------------------------------------------
console.log("\n--- 2. Promo Code Copy Buttons & Toast Notification Logic ---");

const copyButtons = Array.from(htmlContent.matchAll(/<button\s+[^>]*class=["'][^"']*copy-code-btn[^"']*["'][^>]*>/gi));
assert(copyButtons.length >= 3, `Promo copy buttons exist in index.html (Found: ${copyButtons.length})`);

copyButtons.forEach((btnMatch, idx) => {
  const btnTag = btnMatch[0];
  const hasDataCode = /data-code=["']([^"']+)["']/i.test(btnTag);
  const codeVal = hasDataCode ? btnTag.match(/data-code=["']([^"']+)["']/i)[1] : null;
  assert(hasDataCode && codeVal && codeVal.trim().length > 0, `Copy button #${idx + 1} has non-empty data-code attribute`, `data-code="${codeVal}"`);
});

// Check #toast-container in HTML
const toastContainerExists = /id=["']toast-container["']/i.test(htmlContent);
assert(toastContainerExists, `id="toast-container" exists in index.html`);

// Check toast trigger logic in app.js
const appJsHasToastLogic = /document\.getElementById\(['"]toast-container['"]\)/.test(jsContent);
assert(appJsHasToastLogic, `app.js references id="toast-container" for toast notifications`);

const appJsHasCopyCodeBtnListener = /querySelectorAll\(['"]\.copy-code-btn['"]\)/.test(jsContent);
assert(appJsHasCopyCodeBtnListener, `app.js binds event listeners to '.copy-code-btn'`);

// ----------------------------------------------------------------------------
// 3. Responsive CSS Breakpoint Rules (1024px, 768px, 480px)
// ----------------------------------------------------------------------------
console.log("\n--- 3. Responsive CSS Breakpoint Rules ---");

const has1024 = /@media[^{]*max-width:\s*1024px[^{]*\{/i.test(cssContent);
const has768 = /@media[^{]*max-width:\s*768px[^{]*\{/i.test(cssContent);
const has480 = /@media[^{]*max-width:\s*480px[^{]*\{/i.test(cssContent);

assert(has1024, `CSS includes @media (max-width: 1024px) breakpoint`);
assert(has768, `CSS includes @media (max-width: 768px) breakpoint`);
assert(has480, `CSS includes @media (max-width: 480px) breakpoint`);

// Check rules inside breakpoints
if (has768) {
  const hidesNavLinks = /@media[^{]*max-width:\s*768px[^{]*\{[^}]*\.nav-links/s.test(cssContent);
  assert(hidesNavLinks, `768px media query handles mobile navbar link overflow`);
}

// ----------------------------------------------------------------------------
// 4. Zero Dark Green Matrix Blood Cell Scanlines & Clean #star-canvas
// ----------------------------------------------------------------------------
console.log("\n--- 4. Scanlines, Matrix Effects & Canvas Configuration ---");

const scanlinesInCss = /scanline/i.test(cssContent);
const bloodInCss = /blood/i.test(cssContent);
const matrixInCssBg = /background[^;]*matrix/i.test(cssContent);

assert(!scanlinesInCss, `Zero scanline rules in style.css`);
assert(!bloodInCss, `Zero blood cell references in style.css`);
assert(!matrixInCssBg, `Zero dark green matrix background rules in style.css`);

// Check #star-canvas HTML vs JS binding
const htmlCanvasId = htmlContent.match(/<canvas\s+[^>]*id=["']([^"']+)["']/i);
const jsCanvasId = jsContent.match(/document\.getElementById\(['"](star-[^'"]+)['"]\)/i);

const canvasHtmlStr = htmlCanvasId ? htmlCanvasId[1] : null;
const canvasJsStr = jsCanvasId ? jsCanvasId[1] : null;

console.log(`Canvas ID in index.html: '${canvasHtmlStr}'`);
console.log(`Canvas ID in app.js:     '${canvasJsStr}'`);

const canvasIdsMatch = (canvasHtmlStr === canvasJsStr);
assert(canvasIdsMatch, `#star-canvas ID in index.html matches ID in app.js`, 
  canvasIdsMatch ? `Both use '${canvasHtmlStr}'` : `DISCREPANCY: index.html has '${canvasHtmlStr}' but app.js seeks '${canvasJsStr}'!`);

console.log("\n=================================================");
console.log(` SUMMARY: ${passed} PASSED, ${failed} FAILED`);
console.log("=================================================");
