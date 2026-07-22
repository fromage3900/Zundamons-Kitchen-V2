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
