#!/usr/bin/env node
// compare_runs.mjs — regression comparison between Playtest Echo runs.
//
// Diffs two archived runs in tools/playtest-echo/runs/ and classifies every
// error as NEW / RESOLVED / RECURRING (keyed by script + message), so a playtest
// can answer "did we fix anything, and did we break anything?" without reading
// raw logs.
//
// Usage (from repository root):
//   node tools/playtest-echo/compare_runs.mjs                 # compare the two most recent runs
//   node tools/playtest-echo/compare_runs.mjs --from=<id> --to=<id>
//   node tools/playtest-echo/compare_runs.mjs --json          # machine-readable output
//
// Runs are ordered by started_at (the only trustworthy timestamp in a trace).

import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, "..", "..");
const runsDirectory = path.join(scriptDirectory, "runs");

function parseArgs(arguments_) {
	const flags = { from: null, to: null, json: false };
	for (const argument of arguments_) {
		if (argument === "--json") {
			flags.json = true;
		} else if (argument.startsWith("--from=")) {
			flags.from = argument.slice("--from=".length);
		} else if (argument.startsWith("--to=")) {
			flags.to = argument.slice("--to=".length);
		} else {
			throw new Error(`Unknown argument: ${argument}`);
		}
	}
	return flags;
}

async function loadRuns() {
	const entries = await readdir(runsDirectory, { withFileTypes: true });
	const runs = [];
	for (const entry of entries) {
		if (!entry.isFile() || !entry.name.endsWith(".json")) {
			continue;
		}
		const filePath = path.join(runsDirectory, entry.name);
		let trace;
		try {
			trace = JSON.parse(await readFile(filePath, "utf8"));
		} catch (error) {
			throw new Error(`Could not parse ${filePath}: ${error.message}`);
		}
		if (
			trace === null ||
			typeof trace !== "object" ||
			typeof trace.session_id !== "string" ||
			typeof trace.started_at !== "string" ||
			!Array.isArray(trace.errors)
		) {
			throw new Error(`Skipping ${filePath}: not a valid echo run (needs session_id, started_at, errors).`);
		}
		runs.push({
			session_id: trace.session_id,
			started_at: trace.started_at,
			file: filePath,
			errors: trace.errors,
		});
	}

	runs.sort((left, right) => Date.parse(left.started_at) - Date.parse(right.started_at));
	return runs;
}

function findRun(runs, sessionId) {
	const run = runs.find((candidate) => candidate.session_id === sessionId);
	if (!run) {
		throw new Error(`No archived run with session_id "${sessionId}".`);
	}
	return run;
}

function normalize(message) {
	return String(message).trim().replace(/\s+/gu, " ");
}

function errorKey(entry) {
	const message =
		typeof entry === "string"
			? entry
			: entry !== null && typeof entry === "object" && typeof entry.message === "string"
				? entry.message
				: "";
	const script =
		entry !== null && typeof entry === "object" && typeof entry.script === "string"
			? entry.script.trim()
			: "Unknown";
	return `${script}\u0000${normalize(message)}`;
}

function zrKey(ev) {
	const status = typeof ev.status === "string" ? ev.status : "?";
	const memories = Array.isArray(ev.memories) ? ev.memories.length : 0;
	return `ZundaroomsStatus\u0000${status}\u0000${memories}`;
}

function indexErrors(run) {
	const index = new Map();
	for (const entry of run.errors) {
		const key = errorKey(entry);
		const existing = index.get(key);
		if (existing) {
			existing.count += 1;
		} else {
			const script =
				entry !== null && typeof entry === "object" && typeof entry.script === "string"
					? entry.script.trim()
					: "Unknown";
			const message =
				typeof entry === "string"
					? entry
					: entry !== null && typeof entry === "object" && typeof entry.message === "string"
						? entry.message
						: "(empty error message)";
			index.set(key, { script, message: message.trim(), count: 1 });
		}
	}

	if (run.zundarooms_status_events) {
		for (const ev of run.zundarooms_status_events) {
			const key = zrKey(ev);
			const existing = index.get(key);
			if (existing) {
				existing.count += 1;
			} else {
				index.set(key, { script: "ZundaroomsStatus", message: "", count: 1 });
			}
		}
	}

	return index;
}

function classify(previous, current) {
	const previousErrors = indexErrors(previous);
	const currentErrors = indexErrors(current);

	const recurring = [];
	const regressed = [];
	const resolved = [];

	for (const [key, entry] of currentErrors) {
		if (previousErrors.has(key)) {
			recurring.push({ ...entry, previous_count: previousErrors.get(key).count });
		} else {
			regressed.push({ ...entry, previous_count: 0 });
		}
	}

	for (const [key, entry] of previousErrors) {
		if (!currentErrors.has(key)) {
			resolved.push({ ...entry, previous_count: entry.count });
		}
	}

	const byCountDescending = (left, right) =>
		right.count - left.count || left.script.localeCompare(right.script);

	recurring.sort(byCountDescending);
	regressed.sort(byCountDescending);
	resolved.sort(byCountDescending);

	return { recurring, regressed, resolved };
}

function summaryLine(run) {
	return `${run.session_id}  ${run.started_at}  (${run.errors.length} errors)`;
}

function printReport(previous, current, classification) {
	const { recurring, regressed, resolved } = classification;

	console.log("Playtest Echo — regression report");
	console.log("");
	console.log(`  previous  ${summaryLine(previous)}`);
	console.log(`  current   ${summaryLine(current)}`);
	console.log("");

	console.log(`REGRESSED (new in current): ${regressed.length}`);
	if (regressed.length === 0) {
		console.log("  none — no new errors introduced");
	} else {
		for (const entry of regressed) {
			console.log(`  + ${entry.script} (${entry.count}x)`);
			console.log(`      ${entry.message}`);
		}
	}

	console.log("");
	console.log(`RESOLVED (gone since previous): ${resolved.length}`);
	if (resolved.length === 0) {
		console.log("  none — nothing fixed");
	} else {
		for (const entry of resolved) {
			console.log(`  - ${entry.script} (was ${entry.count}x)`);
			console.log(`      ${entry.message}`);
		}
	}

	console.log("");
	console.log(`RECURRING (still present): ${recurring.length}`);
	if (recurring.length === 0) {
		console.log("  none");
	} else {
		for (const entry of recurring) {
			console.log(`  = ${entry.script} (${entry.count}x, was ${entry.previous_count}x)`);
			console.log(`      ${entry.message}`);
		}
	}
}

function jsonReport(previous, current, classification) {
	return {
		previous: { session_id: previous.session_id, started_at: previous.started_at },
		current: { session_id: current.session_id, started_at: current.started_at },
		regressed: classification.regressed,
		resolved: classification.resolved,
		recurring: classification.recurring,
	};
}

async function main() {
	const flags = parseArgs(process.argv.slice(2));
	const runs = await loadRuns();

	if (runs.length < 2) {
		throw new Error(
			`Need at least 2 archived runs to compare (found ${runs.length} in ${runsDirectory}).`,
		);
	}

	const previous = flags.from ? findRun(runs, flags.from) : runs[runs.length - 2];
	const current = flags.to ? findRun(runs, flags.to) : runs[runs.length - 1];

	if (previous.session_id === current.session_id) {
		throw new Error("Cannot compare a run against itself.");
	}

	const classification = classify(previous, current);

	if (flags.json) {
		console.log(JSON.stringify(jsonReport(previous, current, classification), null, 2));
	} else {
		printReport(previous, current, classification);
	}
}

main().catch((error) => {
	console.error(`compare_runs: ${error.message}`);
	process.exitCode = 1;
});
