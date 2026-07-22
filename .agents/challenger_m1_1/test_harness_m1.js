const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const REPO_ROOT = path.resolve(__dirname, '..', '..');
const SITE_DIR = path.join(REPO_ROOT, 'site');
const DOCS_DIR = path.join(REPO_ROOT, 'docs');

console.log('=== STRESS-TEST HARNESS FOR MILESTONE 1 (V3) ===\n');

const results = {
  task1: { name: 'HTML Syntax & DOM Integrity', status: 'PENDING', findings: [] },
  task2: { name: 'sync_site.js Stress Testing', status: 'PENDING', findings: [] },
  task3: { name: 'style.css Safety & Responsiveness', status: 'PENDING', findings: [] }
};

// ==========================================
// TASK 1: HTML Syntax & DOM Integrity
// ==========================================
function testTask1() {
  console.log('--- TASK 1: HTML Syntax & DOM Integrity ---');
  const indexPath = path.join(SITE_DIR, 'index.html');
  if (!fs.existsSync(indexPath)) {
    results.task1.findings.push({ severity: 'CRITICAL', issue: 'site/index.html does not exist' });
    results.task1.status = 'FAIL';
    return;
  }

  const htmlContent = fs.readFileSync(indexPath, 'utf8');

  // 1. Check basic HTML structure
  if (!htmlContent.includes('<!DOCTYPE html>')) {
    results.task1.findings.push({ severity: 'MEDIUM', issue: 'Missing <!DOCTYPE html> declaration' });
  }

  // 2. Extract all element IDs and check duplicates
  const idRegex = /id=["']([^"']+)["']/g;
  let match;
  const ids = [];
  const duplicateIds = [];
  const idSet = new Set();

  while ((match = idRegex.exec(htmlContent)) !== null) {
    const idVal = match[1];
    if (idSet.has(idVal)) {
      duplicateIds.push(idVal);
    }
    idSet.add(idVal);
    ids.push(idVal);
  }

  console.log(`- Found ${ids.length} ID attributes in index.html, ${idSet.size} unique.`);
  if (duplicateIds.length > 0) {
    results.task1.findings.push({
      severity: 'HIGH',
      issue: `Duplicate element IDs found in index.html: ${duplicateIds.join(', ')}`
    });
  }

  // 3. Extract asset references (src and href) in index.html (strip ? query strings for file system check)
  const srcRegex = /(?:src|href)=["']([^"']+)["']/g;
  const brokenLinks = [];
  while ((match = srcRegex.exec(htmlContent)) !== null) {
    let href = match[1];
    if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('#') || href.startsWith('data:')) {
      continue;
    }
    // Strip query strings e.g. ?v=2.5.0
    const cleanHref = href.split('?')[0];
    const resolvedPath = path.resolve(SITE_DIR, cleanHref);
    if (!fs.existsSync(resolvedPath)) {
      brokenLinks.push({ href: cleanHref, resolvedPath });
    }
  }

  if (brokenLinks.length > 0) {
    results.task1.findings.push({
      severity: 'HIGH',
      issue: `Broken local link/src references in index.html: ${brokenLinks.map(b => b.href).join(', ')}`
    });
  } else {
    console.log('- All local script/stylesheet/image links in index.html resolve to existing files on disk.');
  }

  // 4. Node -c syntax check on all JS files in site/
  const jsFiles = ['app.js', 'window_manager.js', 'terminal.js', 'sync_site.js', 'assets/audio_engine.js'];
  for (const jsFile of jsFiles) {
    const jsPath = path.join(SITE_DIR, jsFile);
    try {
      execSync(`node -c "${jsPath}"`, { stdio: 'pipe' });
      console.log(`- Syntax check PASS: ${jsFile}`);
    } catch (err) {
      const errMsg = err.stderr ? err.stderr.toString() : err.message;
      results.task1.findings.push({
        severity: 'CRITICAL',
        issue: `Syntax error in ${jsFile}: ${errMsg.trim()}`
      });
      console.log(`- Syntax check FAIL: ${jsFile}`);
    }
  }

  // 5. Specific check for canvas ID mismatch in app.js vs index.html
  const appJsPath = path.join(SITE_DIR, 'app.js');
  if (fs.existsSync(appJsPath)) {
    const appJsContent = fs.readFileSync(appJsPath, 'utf8');
    if (appJsContent.includes("getElementById('star-sparkle-canvas')") && !idSet.has('star-sparkle-canvas')) {
      results.task1.findings.push({
        severity: 'HIGH',
        issue: "DOM ID Mismatch: app.js queries document.getElementById('star-sparkle-canvas'), but index.html defines <canvas id=\"star-canvas\">. Star particle animation fails to initialize."
      });
    }
  }

  if (results.task1.findings.filter(f => f.severity === 'CRITICAL' || f.severity === 'HIGH').length > 0) {
    results.task1.status = 'FAIL';
  } else if (results.task1.findings.length > 0) {
    results.task1.status = 'WARN';
  } else {
    results.task1.status = 'PASS';
  }
}

// ==========================================
// TASK 2: Stress-test sync_site.js
// ==========================================
function testTask2() {
  console.log('\n--- TASK 2: Stress-Testing sync_site.js ---');
  const syncScript = path.join(SITE_DIR, 'sync_site.js');

  if (!fs.existsSync(syncScript)) {
    results.task2.findings.push({ severity: 'CRITICAL', issue: 'site/sync_site.js does not exist' });
    results.task2.status = 'FAIL';
    return;
  }

  // 1. Test CLI options
  const cliTests = [
    { flag: '--help', expectedCode: 0, description: 'Help flag' },
    { flag: '--dry-run', expectedCode: 0, description: 'Dry run flag' },
    { flag: '-d', expectedCode: 0, description: 'Dry run short flag' },
    { flag: '--verbose', expectedCode: 0, description: 'Verbose flag' },
    { flag: '-v', expectedCode: 0, description: 'Verbose short flag' },
  ];

  for (const t of cliTests) {
    try {
      const out = execSync(`node "${syncScript}" ${t.flag}`, { stdio: 'pipe' }).toString();
      console.log(`- ${t.description} (${t.flag}): PASS (Exit code 0)`);
    } catch (err) {
      results.task2.findings.push({
        severity: 'HIGH',
        issue: `CLI test ${t.flag} failed with exit code ${err.status}`
      });
    }
  }

  // 2. Test Live Sync execution
  try {
    const out = execSync(`node "${syncScript}"`, { stdio: 'pipe' }).toString();
    console.log(`- Live sync execution: PASS`);
  } catch (err) {
    results.task2.findings.push({
      severity: 'HIGH',
      issue: `Live sync execution failed: ${err.message}`
    });
  }

  // 3. Stress-test Nested Assets Folder Creation & Hash Comparison
  const testSubDir = path.join(SITE_DIR, 'assets', 'stress_test_nested', 'sub');
  const testSubFile = path.join(testSubDir, 'nested_item.txt');
  const targetSubFile = path.join(DOCS_DIR, 'assets', 'stress_test_nested', 'sub', 'nested_item.txt');

  try {
    fs.mkdirSync(testSubDir, { recursive: true });
    fs.writeFileSync(testSubFile, 'Initial content v1', 'utf8');

    // Run --dry-run first to check preview behavior for new nested file
    const dryRunOut = execSync(`node "${syncScript}" --dry-run`, { stdio: 'pipe' }).toString();
    if (!dryRunOut.includes('[NEW]') || !dryRunOut.includes('stress_test_nested')) {
      results.task2.findings.push({
        severity: 'MEDIUM',
        issue: 'Dry run did not report new nested file in output preview'
      });
    }
    if (fs.existsSync(targetSubFile)) {
      results.task2.findings.push({
        severity: 'HIGH',
        issue: 'Dry run actually created file on disk when it should be preview only'
      });
    } else {
      console.log('- Dry run preview correctly avoided writing nested file to docs/');
    }

    // Run live sync to verify creation
    execSync(`node "${syncScript}"`, { stdio: 'pipe' });
    if (!fs.existsSync(targetSubFile) || fs.readFileSync(targetSubFile, 'utf8') !== 'Initial content v1') {
      results.task2.findings.push({
        severity: 'HIGH',
        issue: 'Live sync failed to recursively create nested directory and copy file to docs/'
      });
    } else {
      console.log('- Live sync successfully created nested directory structure and copied file.');
    }

    // Modify source file content to test hash comparison & update
    fs.writeFileSync(testSubFile, 'Updated content v2', 'utf8');

    const updateDryRun = execSync(`node "${syncScript}" --dry-run`, { stdio: 'pipe' }).toString();
    if (!updateDryRun.includes('[UPDATE]')) {
      results.task2.findings.push({
        severity: 'MEDIUM',
        issue: 'Sync script failed to detect modified file content via hash comparison'
      });
    } else {
      console.log('- Hash comparison correctly detected updated file content.');
    }

    // Perform sync update
    execSync(`node "${syncScript}"`, { stdio: 'pipe' });
    if (fs.readFileSync(targetSubFile, 'utf8') !== 'Updated content v2') {
      results.task2.findings.push({
        severity: 'HIGH',
        issue: 'Live sync did not update target file with new content'
      });
    } else {
      console.log('- Live sync successfully updated target file content in docs/.');
    }

    // Unchanged file check
    const unchangedOut = execSync(`node "${syncScript}" --verbose`, { stdio: 'pipe' }).toString();
    if (!unchangedOut.includes('[UNCHANGED]')) {
      results.task2.findings.push({
        severity: 'LOW',
        issue: 'Verbose mode did not output [UNCHANGED] for non-modified files'
      });
    } else {
      console.log('- Verbose mode correctly listed unchanged files.');
    }

  } catch (err) {
    results.task2.findings.push({
      severity: 'HIGH',
      issue: `Error during nested asset stress testing: ${err.message}`
    });
  } finally {
    // Cleanup temporary stress test files
    try {
      if (fs.existsSync(testSubFile)) fs.unlinkSync(testSubFile);
      const testParentDir = path.join(SITE_DIR, 'assets', 'stress_test_nested');
      if (fs.existsSync(testParentDir)) fs.rmSync(testParentDir, { recursive: true, force: true });

      if (fs.existsSync(targetSubFile)) fs.unlinkSync(targetSubFile);
      const targetParentDir = path.join(DOCS_DIR, 'assets', 'stress_test_nested');
      if (fs.existsSync(targetParentDir)) fs.rmSync(targetParentDir, { recursive: true, force: true });
    } catch (e) {
      console.error('Cleanup error:', e.message);
    }
  }

  // 4. Test Markdown Preservation in docs/
  const tempMdInDocs = path.join(DOCS_DIR, 'temp_preserve_test.md');
  const tempNestedMdInDocs = path.join(DOCS_DIR, 'sub_docs', 'nested_preserve.md');
  try {
    fs.writeFileSync(tempMdInDocs, '# Preserved Doc Test', 'utf8');
    fs.mkdirSync(path.dirname(tempNestedMdInDocs), { recursive: true });
    fs.writeFileSync(tempNestedMdInDocs, '# Nested Preserved Doc', 'utf8');

    execSync(`node "${syncScript}"`, { stdio: 'pipe' });

    if (!fs.existsSync(tempMdInDocs)) {
      results.task2.findings.push({
        severity: 'CRITICAL',
        issue: 'Sync script deleted existing root markdown file in docs/'
      });
    } else {
      console.log('- Sync script preserved root markdown file in docs/.');
    }

    if (!fs.existsSync(tempNestedMdInDocs)) {
      results.task2.findings.push({
        severity: 'CRITICAL',
        issue: 'Sync script deleted nested markdown file in docs/ subdirectories'
      });
    } else {
      console.log('- Sync script preserved nested markdown file in docs/ subdirectories.');
    }

    // Check limitation: sync_site.js readdirSync only lists root level *.md for verbose summary
    const verboseOut = execSync(`node "${syncScript}" --verbose`, { stdio: 'pipe' }).toString();
    if (!verboseOut.includes('nested_preserve.md')) {
      results.task2.findings.push({
        severity: 'LOW',
        issue: 'Sync script summary only lists root-level markdown files in docs/ during verbose reporting, omitting sub-directory markdown files.'
      });
    }
  } catch (err) {
    results.task2.findings.push({
      severity: 'HIGH',
      issue: `Markdown preservation test error: ${err.message}`
    });
  } finally {
    if (fs.existsSync(tempMdInDocs)) fs.unlinkSync(tempMdInDocs);
    const subDocsDir = path.join(DOCS_DIR, 'sub_docs');
    if (fs.existsSync(subDocsDir)) fs.rmSync(subDocsDir, { recursive: true, force: true });
  }

  if (results.task2.findings.filter(f => f.severity === 'CRITICAL' || f.severity === 'HIGH').length > 0) {
    results.task2.status = 'FAIL';
  } else if (results.task2.findings.length > 0) {
    results.task2.status = 'WARN';
  } else {
    results.task2.status = 'PASS';
  }
}

// ==========================================
// TASK 3: style.css Safety & Responsiveness
// ==========================================
function testTask3() {
  console.log('\n--- TASK 3: style.css Safety & Responsiveness ---');
  const cssPath = path.join(SITE_DIR, 'style.css');
  const indexPath = path.join(SITE_DIR, 'index.html');

  if (!fs.existsSync(cssPath)) {
    results.task3.findings.push({ severity: 'CRITICAL', issue: 'site/style.css does not exist' });
    results.task3.status = 'FAIL';
    return;
  }

  const cssContent = fs.readFileSync(cssPath, 'utf8');
  const htmlContent = fs.readFileSync(indexPath, 'utf8');

  // Check Media Queries in CSS
  const mediaQueryRegex = /@media\s+[^\{]+\{/g;
  let match;
  const mediaQueries = [];
  while ((match = mediaQueryRegex.exec(cssContent)) !== null) {
    mediaQueries.push(match[0].replace('{', '').trim());
  }

  console.log(`- Found ${mediaQueries.length} @media query breakpoints in style.css:`);
  mediaQueries.forEach(mq => console.log(`  * ${mq}`));

  if (mediaQueries.length === 0) {
    results.task3.findings.push({
      severity: 'HIGH',
      issue: 'No @media queries found in style.css for responsive design'
    });
  }

  // Check viewport meta tag in index.html
  if (!htmlContent.includes('name="viewport"') && !htmlContent.includes("name='viewport'")) {
    results.task3.findings.push({
      severity: 'HIGH',
      issue: 'Missing <meta name="viewport"> tag in index.html for mobile responsiveness'
    });
  } else {
    console.log('- Viewport meta tag verified in index.html.');
  }

  if (results.task3.findings.filter(f => f.severity === 'CRITICAL' || f.severity === 'HIGH').length > 0) {
    results.task3.status = 'FAIL';
  } else if (results.task3.findings.length > 0) {
    results.task3.status = 'WARN';
  } else {
    results.task3.status = 'PASS';
  }
}

// Run all tests
testTask1();
testTask2();
testTask3();

console.log('\n=== SUMMARY OF RESULTS ===');
console.log(JSON.stringify(results, null, 2));
