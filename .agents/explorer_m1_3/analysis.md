# Analysis & Specification: Automated Dual Deployment Sync (`site/sync_site.js`)

**Author**: Explorer 3 (Milestone 1)  
**Target Requirement**: R4 - Automated Dual Deployment Sync  
**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\explorer_m1_3`  
**Date**: 2026-07-22  

---

## 1. Executive Summary

Zundamon's Kitchen V2 uses a dual-folder structure for web assets:
- `g:\Zundamons-kItchen-V2\site`: The active development source directory for the HTML5/Y2K Infinity Nikki web front.
- `g:\Zundamons-kItchen-V2\docs`: The target deployment directory for GitHub Pages hosting, which also contains project architectural & process documentation (Markdown files).

Requirement R4 dictates creating an automated Node.js synchronization runner (`site/sync_site.js`) that replicates all web assets from `site/` to `docs/` while strictly preserving all existing Markdown documentation files in `docs/`.

This specification provides the architectural design, file mapping rules, comparison algorithms, CLI interface, and complete zero-dependency Node.js reference implementation for `site/sync_site.js`.

---

## 2. Directory Structure & File Inventory Analysis

### 2.1 Source Directory (`site/`)
Current contents of `g:\Zundamons-kItchen-V2\site`:
- `.nojekyll` (Bypasses Jekyll processing on GitHub Pages)
- `index.html` (Main web showcase & desktop container)
- `style.css` (Y2K Infinity Nikki design tokens & layout rules)
- `app.js` (Interactive desktop application engines)
- `terminal.js` (Y2K Pastel Web Terminal `ZundaCLI.exe`)
- `window_manager.js` (Modular window management engine)
- `sync_site.js` (Dual deployment sync runner — to be added in M1)
- `assets/` (Directory)
  - `audio_engine.js` (Web Audio API synthesizer & sound effects)
  - `crt_monitor.svg` (SVG icon asset)
  - `disc_icon.svg` (SVG icon asset)
  - `pea_pod.svg` (SVG icon asset)
  - `zundamon_mochi.svg` (SVG icon asset)

### 2.2 Target Directory (`docs/`)
Current contents of `g:\Zundamons-kItchen-V2\docs`:
- Web Assets (mirror of `site/`): `.nojekyll`, `index.html`, `style.css`, `app.js`, `terminal.js`, `window_manager.js`, `assets/*`
- Repository Markdown Documentation (MUST BE PRESERVED):
  - `AGENT_HANDOFF.md`
  - `ASSET_MANAGEMENT.md`
  - `COLLABORATOR_PROMPTS.md`
  - `MCP_WORKFLOW.md`
  - `PHASE1_INVENTORY.md`
  - `PHASE1_RECOVERY.md`
  - `PHASE2_BOOT_RECOVERY.md`
  - `PHASE3_ACCEPTANCE_STATUS.md`
  - `PHASE3_RECOVERY_PLAN.md`
  - `PRODUCTION_AND_LEVEL_DESIGN_HANDOFF.md`
  - `RESOURCE_NODE_AUTHORING.md`
  - `UI_UX_OVERHAUL_PLAN.md`
  - `ZUNDAMON_CHEF_MASTER_IMPORT.md`
  - `ZUNDAROOMS_AUTHORING.md`

---

## 3. Specification & Architectural Requirements

### R4.1 Native Node.js & Zero External Dependencies
- **Constraint**: Must use only Node.js standard built-in modules (`fs`, `path`, `crypto`, `process`).
- **Rationale**: Ensures instant execution without requiring `npm install` or third-party packages, avoiding build-step failures in CI/CD or local environments.

### R4.2 Robust Path Resolution
- **Constraint**: Must calculate absolute paths using `__dirname`.
- **Source Path**: `path.resolve(__dirname)` -> resolves to absolute path of `site/`.
- **Target Path**: `path.resolve(__dirname, '..', 'docs')` -> resolves to absolute path of `docs/`.
- **Rationale**: Allows running `node site/sync_site.js` from the repository root, from inside `site/`, or from any current working directory.

### R4.3 Recursive Web Asset Copying
- **Constraint**: Recursively list all files in `site/` (including nested folders like `assets/` and hidden files like `.nojekyll`).
- **Target Directory Auto-Creation**: Ensure parent directories (e.g., `docs/assets/`) exist using `fs.mkdirSync(destDir, { recursive: true })` prior to copying.

### R4.4 Documentation Preservation
- **Constraint**: Documentation Markdown files (`*.md`) located in `docs/` must NEVER be deleted, overwritten, or modified by `sync_site.js`.
- **Mechanism**: The sync script only reads files present in `site/`. Since Markdown documentation files reside solely in `docs/` and not in `site/`, standard unidirectional copy (`site/` -> `docs/`) naturally preserves `docs/*.md`. Furthermore, an explicit audit log will list preserved `.md` files during execution.

### R4.5 Content Hashing & Smart Differential Sync
- **Constraint**: Use SHA-256 hashing via `crypto.createHash('sha256')` to compare source and destination file contents.
- **Rules**:
  - Destination file missing -> `[NEW]` (Copy file).
  - Destination file exists & SHA-256 matches -> `[UNCHANGED]` (Skip write to preserve file mtime & prevent unnecessary git diffs).
  - Destination file exists & SHA-256 differs -> `[UPDATE]` (Overwrite destination file).

### R4.6 CLI Flags & Execution Modes
- `--dry-run` / `-d`: Preview operations without making file system modifications.
- `--verbose` / `-v`: Output detailed file-by-file logs, including unchanged files and preserved markdown documentation files.
- `--help` / `-h`: Display CLI help documentation and exit.
- Default Mode: Executes actual synchronization and prints a clean summary table.

---

## 4. Complete Reference Implementation Specification (`site/sync_site.js`)

Below is the complete, production-ready code specification for `site/sync_site.js`:

```javascript
/**
 * site/sync_site.js
 * Zundamon's Kitchen V2 - Automated Dual Deployment Sync Runner
 * 
 * Synchronizes web assets from `site/` to `docs/` for GitHub Pages deployment.
 * Preserves existing markdown documentation files in `docs/`.
 * Native Node.js script — Zero external npm dependencies.
 * 
 * Usage:
 *   node site/sync_site.js [--dry-run|-d] [--verbose|-v] [--help|-h]
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Configuration
const SITE_DIR = path.resolve(__dirname);
const REPO_ROOT = path.resolve(__dirname, '..');
const DOCS_DIR = path.resolve(REPO_ROOT, 'docs');

// Parse CLI arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run') || args.includes('-d');
const isVerbose = args.includes('--verbose') || args.includes('-v');
const isHelp = args.includes('--help') || args.includes('-h');

if (isHelp) {
  console.log(`
Zundamon's Kitchen V2 - Dual Deployment Sync Utility
===================================================
Usage: node site/sync_site.js [options]

Options:
  --dry-run, -d   Preview files to copy/update without making disk changes
  --verbose, -v   Show detailed file-by-file status including skipped files
  --help, -h      Show this help message
  `);
  process.exit(0);
}

// Compute SHA-256 hash of a file buffer
function getFileHash(filePath) {
  try {
    const fileBuffer = fs.readFileSync(filePath);
    return crypto.createHash('sha256').update(fileBuffer).digest('hex');
  } catch (err) {
    return null;
  }
}

// Recursively list all files relative to base directory
function listFilesRecursively(dir, relativeTo = dir) {
  let results = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    const relPath = path.relative(relativeTo, fullPath);

    if (entry.isDirectory()) {
      results = results.concat(listFilesRecursively(fullPath, relativeTo));
    } else if (entry.isFile()) {
      results.push(relPath);
    }
  }

  return results;
}

function sync() {
  console.log(`\n==================================================`);
  console.log(` Zundamon's Kitchen V2 - Dual Deployment Sync`);
  console.log(` Mode: ${isDryRun ? '[DRY RUN - PREVIEW ONLY]' : '[LIVE SYNC]'}`);
  console.log(` Source: ${SITE_DIR}`);
  console.log(` Target: ${DOCS_DIR}`);
  console.log(`==================================================\n`);

  if (!fs.existsSync(SITE_DIR)) {
    console.error(`Error: Source directory does not exist: ${SITE_DIR}`);
    process.exit(1);
  }

  if (!fs.existsSync(DOCS_DIR)) {
    if (isDryRun) {
      console.log(`[DRY RUN] Would create target directory: ${DOCS_DIR}`);
    } else {
      fs.mkdirSync(DOCS_DIR, { recursive: true });
      console.log(`Created target directory: ${DOCS_DIR}`);
    }
  }

  // Get list of web assets from site/
  const siteFiles = listFilesRecursively(SITE_DIR);

  // Statistics
  const stats = {
    totalScanned: siteFiles.length,
    copiedNew: 0,
    updated: 0,
    unchanged: 0,
    preservedDocs: 0,
    errors: 0
  };

  for (const relPath of siteFiles) {
    const srcPath = path.join(SITE_DIR, relPath);
    const destPath = path.join(DOCS_DIR, relPath);
    const destDir = path.dirname(destPath);

    try {
      const srcHash = getFileHash(srcPath);
      const destExists = fs.existsSync(destPath);
      const destHash = destExists ? getFileHash(destPath) : null;

      if (!destExists) {
        stats.copiedNew++;
        console.log(`  [NEW]      ${relPath}`);
        if (!isDryRun) {
          if (!fs.existsSync(destDir)) {
            fs.mkdirSync(destDir, { recursive: true });
          }
          fs.copyFileSync(srcPath, destPath);
        }
      } else if (srcHash !== destHash) {
        stats.updated++;
        console.log(`  [UPDATE]   ${relPath}`);
        if (!isDryRun) {
          fs.copyFileSync(srcPath, destPath);
        }
      } else {
        stats.unchanged++;
        if (isVerbose) {
          console.log(`  [UNCHANGED] ${relPath}`);
        }
      }
    } catch (err) {
      stats.errors++;
      console.error(`  [ERROR]    ${relPath}: ${err.message}`);
    }
  }

  // Audit preserved markdown files in docs/
  if (fs.existsSync(DOCS_DIR)) {
    const docsEntries = fs.readdirSync(DOCS_DIR, { withFileTypes: true });
    const markdownDocs = docsEntries
      .filter(e => e.isFile() && e.name.endsWith('.md'))
      .map(e => e.name);
    
    stats.preservedDocs = markdownDocs.length;
    if (isVerbose && markdownDocs.length > 0) {
      console.log(`\nPreserved Markdown Documentation Files in docs/:`);
      for (const mdFile of markdownDocs) {
        console.log(`  [PRESERVED] ${mdFile}`);
      }
    }
  }

  console.log(`\n--------------------------------------------------`);
  console.log(` Sync Summary (${isDryRun ? 'DRY RUN' : 'COMPLETED'})`);
  console.log(`--------------------------------------------------`);
  console.log(` Total site assets scanned: ${stats.totalScanned}`);
  console.log(` New files to copy:         ${stats.copiedNew}`);
  console.log(` Updated files:             ${stats.updated}`);
  console.log(` Unchanged files skipped:   ${stats.unchanged}`);
  console.log(` Preserved docs files:      ${stats.preservedDocs}`);
  console.log(` Errors:                    ${stats.errors}`);
  console.log(`==================================================\n`);
  
  if (stats.errors > 0) {
    process.exit(1);
  }
}

sync();
```

---

## 5. Verification & Testing Procedures

To verify the dual sync runner once implemented:

1. **Dry-Run Mode Test**:
   ```powershell
   node site/sync_site.js --dry-run
   ```
   *Expected result*: Displays file scan status and summary without writing or modifying files in `docs/`.

2. **Live Sync Execution Test**:
   ```powershell
   node site/sync_site.js
   ```
   *Expected result*: Synchronizes modified/new assets to `docs/`. Unchanged files show skipped.

3. **Verbose Inspection Test**:
   ```powershell
   node site/sync_site.js --verbose
   ```
   *Expected result*: Lists all `[UNCHANGED]` assets and all `[PRESERVED]` markdown files (`AGENT_HANDOFF.md`, etc.).

4. **Documentation Preservation Audit**:
   Verify that all 14+ `.md` files in `docs/` retain their exact content, size, and modifications after running `sync_site.js`.

---

## 6. Conclusion & Recommendations

- The specification for `site/sync_site.js` satisfies all requirement criteria for R4.
- Zero npm package dependency ensures high portability and zero installation overhead.
- SHA-256 hash checking prevents unnecessary disk writes and keeps git working tree clean.
- Explicit path calculation via `__dirname` makes script execution resilient regardless of current working directory.
- Implementation can proceed immediately under Worker agent during Milestone 1 phase.
