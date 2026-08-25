import { appendFile, mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, "..", "..");
const notesPath = path.join(repositoryRoot, "docs", "PLAYTEST_NOTES.md");
const runsDirectory = path.join(scriptDirectory, "runs");

function validateTrace(trace) {
	if (trace === null || typeof trace !== "object" || Array.isArray(trace)) {
		throw new Error("Trace root must be a JSON object.");
	}

	if (
		typeof trace.session_id !== "string" ||
		!/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/u.test(trace.session_id)
	) {
		throw new Error("session_id must be a filename-safe string (letters, numbers, dot, underscore, or hyphen).");
	}

	const windowsBaseName = trace.session_id.split(".", 1)[0];
	if (/^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$/iu.test(windowsBaseName)) {
		throw new Error("session_id cannot use a Windows reserved device name.");
	}

	const isoDatePattern =
		/^\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])(?:T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d))?$/u;
	if (typeof trace.started_at !== "string" || !isoDatePattern.test(trace.started_at)) {
		throw new Error("started_at must be a valid ISO date string.");
	}

	const [year, month, day] = trace.started_at.slice(0, 10).split("-").map(Number);
	const calendarDate = new Date(Date.UTC(year, month - 1, day));
	if (
		calendarDate.getUTCFullYear() !== year ||
		calendarDate.getUTCMonth() !== month - 1 ||
		calendarDate.getUTCDate() !== day ||
		Number.isNaN(Date.parse(trace.started_at))
	) {
		throw new Error("started_at must be a valid ISO date string.");
	}

	if (typeof trace.duration_s !== "number" || !Number.isFinite(trace.duration_s) || trace.duration_s < 0) {
		throw new Error("duration_s must be a finite, non-negative number.");
	}

	for (const field of ["errors", "warnings", "state_samples"]) {
		if (!Array.isArray(trace[field])) {
			throw new Error(`${field} must be an array.`);
		}
	}
}

function errorMessage(entry, index) {
	if (typeof entry === "string") {
		return entry;
	}
	if (entry !== null && typeof entry === "object" && typeof entry.message === "string") {
		return entry.message;
	}

	throw new Error(`errors[${index}] must be a string or an object with a string message.`);
}

function inferScript(message) {
	const firstLine = message.split(/\r\n|\r|\n/u, 1)[0];
	const directMatch = /^\s*(.+?):\d+(?::\d+)?:\s/u.exec(firstLine);
	if (directMatch) {
		return directMatch[1].trim();
	}

	const stackMatch = /Script ['"]([^'"]+)['"],? Line \d+/iu.exec(message);
	return stackMatch ? stackMatch[1].trim() : "Unknown";
}

function groupErrors(errors) {
	const groups = new Map();

	errors.forEach((entry, index) => {
		const message = errorMessage(entry, index).trim() || "(empty error message)";
		const explicitScript =
			entry !== null && typeof entry === "object" && typeof entry.script === "string"
				? entry.script.trim()
				: "";
		const script = explicitScript || inferScript(message);
		let group = groups.get(script);
		if (!group) {
			group = { count: 0, messages: [], seenMessages: new Set() };
			groups.set(script, group);
		}

		group.count += 1;
		if (!group.seenMessages.has(message)) {
			group.seenMessages.add(message);
			group.messages.push(message);
		}
	});

	return [...groups.entries()].sort((left, right) => {
		const countDifference = right[1].count - left[1].count;
		return countDifference || left[0].localeCompare(right[0]);
	});
}

function escapeMarkdownCell(value) {
	return String(value)
		.replace(/[\u0000-\u0009\u000B\u000C\u000E-\u001F\u007F]/gu, (character) => {
			return `\\u${character.charCodeAt(0).toString(16).padStart(4, "0")}`;
		})
		.replace(/&/gu, "&amp;")
		.replace(/</gu, "&lt;")
		.replace(/>/gu, "&gt;")
		.replace(/\|/gu, "&#124;")
		.replace(/\r\n|\r|\n/gu, "<br>");
}

function formatDuration(duration) {
	const rounded = Math.round(duration * 1000) / 1000;
	return Object.is(rounded, -0) ? "0" : String(rounded);
}

function sessionMarker(sessionId) {
	return `<!-- playtest-echo-session:${sessionId} -->`;
}

function buildSection(trace, previousRun) {
	const date = new Date(trace.started_at).toISOString().slice(0, 10);
	const groups = groupErrors(trace.errors);
	const archivePath = `tools/playtest-echo/runs/${trace.session_id}.json`;
	const lines = [
		`## Echo Run ${date} (${formatDuration(trace.duration_s)}s)`,
		"",
		"### Issues",
		"",
		"| Script | Error count | Unique error messages |",
		"| --- | --- | --- |",
	];

	if (groups.length === 0) {
		lines.push("| _None_ | 0 | No errors captured |");
	} else {
		for (const [script, group] of groups) {
			const messages = group.messages
				.map((message) => `<code>${escapeMarkdownCell(message)}</code>`)
				.join("<br>");
			lines.push(`| <code>${escapeMarkdownCell(script)}</code> | ${group.count} | ${messages} |`);
		}
	}

	const regressionBlock = buildRegressionSection(trace, previousRun);
	lines.push(
		"",
	);
	if (regressionBlock !== "") {
		lines.push(regressionBlock.replace(/\n+$/, ""), "");
	}
	lines.push(
		`Warnings captured: ${trace.warnings.length} · State samples: ${trace.state_samples.length}`,
		"",
		`Raw trace: [\`${archivePath}\`](../${archivePath})`,
		"",
		sessionMarker(trace.session_id),
		"",
	);

	return lines.join("\n");
}

function loadPreviousRunSummary(previous, entries, currentSessionId) {
	// Regression oracle (TITAN-style): find the most recent archived run before
	// this one and return its error-signature set + duration for comparison.
	let newest = null;
	for (const name of entries) {
		if (name === `${currentSessionId}.json`) continue;
		try {
			const parsed = JSON.parse(readFileSync(path.join(runsDirectory, name), "utf8"));
			const startedAt = Date.parse(parsed.started_at);
			if (Number.isNaN(startedAt)) continue;
			if (!newest || startedAt > newest.startedAt) {
				newest = { startedAt, trace: parsed };
			}
		} catch {
			continue;
		}
	}

	if (!newest) return previous;
	previous.duration_s = typeof newest.trace.duration_s === "number" ? newest.trace.duration_s : null;
	newest.trace.errors?.forEach((entry) => {
		const message = typeof entry === "string" ? entry : entry?.message;
		if (typeof message === "string") previous.signatures.add(message.trim());
	});
	return previous;
}

function buildRegressionSection(trace, previousRun) {
	const lines = [];
	if (previousRun.duration_s !== null && previousRun.duration_s > 0 && trace.duration_s > 0) {
		const ratio = trace.duration_s / previousRun.duration_s;
		if (ratio >= 2 || ratio <= 0.5) {
			lines.push(
				`- Duration anomaly: ${formatDuration(trace.duration_s)}s vs baseline ${formatDuration(previousRun.duration_s)}s (${ratio.toFixed(1)}x)`
			);
		}
	}

	const currentSignatures = new Set(
		trace.errors.map((entry) => errorMessage(entry, 0).trim())
	);
	const newErrors = [...currentSignatures].filter((message) => !previousSignaturesHas(previousRun, message));
	if (newErrors.length > 0) {
		lines.push("- New error signatures not in previous run:");
		for (const message of newErrors.slice(0, 10)) {
			lines.push(`  - <code>${escapeMarkdownCell(message)}</code>`);
		}
	}

	const resolved = [...previousRun.signatures].filter((signature) => !currentSignatures.has(signature));
	if (resolved.length > 0) {
		lines.push("- Previously-seen errors absent from this run (possible fixes):");
		for (const message of resolved.slice(0, 10)) {
			lines.push(`  - <code>${escapeMarkdownCell(message)}</code>`);
		}
	}

	if (lines.length === 0) return "";
	return ["### Regression vs previous run", "", ...lines].join("\n") + "\n";
}

function previousSignaturesHas(previousRun, message) {
	return previousRun.signatures.has(message);
}

async function main() {
	const arguments_ = process.argv.slice(2);
	if (arguments_.length !== 1) {
		throw new Error("Usage: node tools/playtest-echo/echo_to_notes.mjs <trace.json>");
	}

	const inputPath = path.resolve(process.cwd(), arguments_[0]);
	const input = await readFile(inputPath, "utf8");
	let trace;
	try {
		trace = JSON.parse(input);
	} catch (error) {
		throw new Error(`Could not parse ${inputPath}: ${error.message}`);
	}

	validateTrace(trace);
	let runEntries = [];
	try {
		runEntries = (await readdir(runsDirectory)).filter((name) => name.endsWith(".json"));
	} catch {
		runEntries = [];
	}
	const previousRun = loadPreviousRunSummary({ signatures: new Set(), duration_s: null }, runEntries, trace.session_id);
	const normalizedInput = input.replace(/\r\n?/gu, "\n");
	const archivedTrace = normalizedInput.endsWith("\n") ? normalizedInput : `${normalizedInput}\n`;
	const runPath = path.join(runsDirectory, `${trace.session_id}.json`);

	await mkdir(runsDirectory, { recursive: true });
	try {
		await writeFile(runPath, archivedTrace, { encoding: "utf8", flag: "wx" });
	} catch (error) {
		if (error.code !== "EEXIST") {
			throw error;
		}

		const existingTrace = await readFile(runPath, "utf8");
		if (existingTrace !== archivedTrace) {
			throw new Error(`Run ${trace.session_id} is already archived with different trace data.`);
		}
	}

	const existingNotes = await readFile(notesPath, "utf8");
	const archivePath = `tools/playtest-echo/runs/${trace.session_id}.json`;
	if (existingNotes.includes(sessionMarker(trace.session_id)) || existingNotes.includes(`Raw trace: [\`${archivePath}\`]`)) {
		console.log(`Echo Run ${trace.session_id} is already present in ${path.relative(repositoryRoot, notesPath)}`);
		console.log(`Raw trace remains at ${path.relative(repositoryRoot, runPath)}`);
		return;
	}

	const separator = existingNotes.endsWith("\n\n") ? "" : existingNotes.endsWith("\n") ? "\n" : "\n\n";
	await appendFile(notesPath, `${separator}${buildSection(trace, previousRun)}`, "utf8");

	console.log(`Appended Echo Run to ${path.relative(repositoryRoot, notesPath)}`);
	console.log(`Archived raw trace at ${path.relative(repositoryRoot, runPath)}`);
}

main().catch((error) => {
	console.error(`playtest-echo: ${error.message}`);
	process.exitCode = 1;
});
