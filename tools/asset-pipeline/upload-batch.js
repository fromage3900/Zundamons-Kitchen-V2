#!/usr/bin/env node
/**
 * Batch-runs upload-asset.js over manifest.json (or a manifest passed as
 * argv[2]) and writes the resulting asset ids to upload-results.json.
 *
 * Usage: node upload-batch.js [manifest.json]
 *
 * Roblox rate-limits Open Cloud asset uploads, so this runs sequentially
 * with a short delay between uploads rather than in parallel.
 */

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const manifestPath = process.argv[2] || path.join(__dirname, "manifest.json");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));

const results = [];
const resultsPath = path.join(__dirname, "upload-results.json");

for (const entry of manifest) {
	console.log(`\n=== ${entry.displayName} ===`);
	try {
		const output = execFileSync(
			process.execPath,
			[path.join(__dirname, "upload-asset.js"), entry.filePath, entry.assetType, entry.displayName, entry.description || ""],
			{ encoding: "utf8", stdio: ["inherit", "pipe", "inherit"] }
		);
		process.stdout.write(output);
		const lastLine = output.trim().split("\n").pop();
		const parsed = JSON.parse(lastLine);
		results.push({ ...parsed, status: "success" });
	} catch (err) {
		console.error(`FAILED: ${entry.displayName} -- ${err.message}`);
		results.push({ ...entry, status: "failed", error: String(err.message) });
	}
	fs.writeFileSync(resultsPath, JSON.stringify(results, null, 2));
	// Be polite to the rate limiter between uploads.
	execFileSync(process.execPath, ["-e", "setTimeout(()=>{}, 3000)"]);
}

console.log(`\nDone. Results written to ${resultsPath}`);
const succeeded = results.filter((r) => r.status === "success").length;
console.log(`${succeeded}/${results.length} uploads succeeded.`);
