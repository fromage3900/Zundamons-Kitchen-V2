#!/usr/bin/env node
/**
 * Roblox Open Cloud asset uploader.
 *
 * Uploads a local file (mesh/model/image/audio) via the Assets API so it's
 * owned by the correct creator from the start -- this is the actual fix for
 * the "you don't have authority to use this asset ID" wall that's been hit
 * repeatedly this project: InsertService/ContentProvider reject anything not
 * owned by the experience's creator, and manual Toolbox-imported assets
 * inherit the uploader's account by default. Uploading through this script
 * with the right creator context sidesteps that permanently.
 *
 * Requires:
 *   - ROBLOX_API_KEY env var (Open Cloud API key scoped to Asset:Read/Write
 *     for the creator below -- create at https://create.roblox.com/credentials)
 *   - Node 18+ (built-in fetch, FormData, Blob)
 *
 * Usage:
 *   node upload-asset.js <filePath> <assetType> <displayName> [description]
 *
 * assetType: one of Model, Decal (image), Audio, Animation
 *   (Roblox infers the concrete container from file extension + assetType;
 *   .fbx/.obj/.glb -> Model, .png/.jpg -> Decal, .mp3/.ogg -> Audio)
 *
 * Prints the resulting rbxassetid:// on success. Exits non-zero on failure.
 */

const fs = require("fs");
const path = require("path");

const CREATOR_USER_ID = "3930496852"; // game.CreatorId, confirmed live from the place (CreatorType=User)
const API_BASE = "https://apis.roblox.com/assets/v1";

const CONTENT_TYPES = {
	".fbx": "model/fbx",
	".obj": "model/obj",
	".glb": "model/gltf-binary",
	".gltf": "model/gltf+json",
	".png": "image/png",
	".jpg": "image/jpeg",
	".jpeg": "image/jpeg",
	".mp3": "audio/mpeg",
	".ogg": "audio/ogg",
};

async function main() {
	const apiKey = process.env.ROBLOX_API_KEY;
	if (!apiKey) {
		console.error("ERROR: ROBLOX_API_KEY environment variable is not set.");
		console.error("Set it with: export ROBLOX_API_KEY=\"your-key-here\"  (Git Bash)");
		console.error("         or: setx ROBLOX_API_KEY \"your-key-here\"    (new terminal, persists)");
		process.exit(1);
	}

	const [, , filePath, assetType, displayName, description] = process.argv;
	if (!filePath || !assetType || !displayName) {
		console.error("Usage: node upload-asset.js <filePath> <assetType> <displayName> [description]");
		console.error("  assetType: Model | Decal | Audio | Animation");
		process.exit(1);
	}

	if (!fs.existsSync(filePath)) {
		console.error(`ERROR: file not found: ${filePath}`);
		process.exit(1);
	}

	const ext = path.extname(filePath).toLowerCase();
	const contentType = CONTENT_TYPES[ext];
	if (!contentType) {
		console.error(`ERROR: unrecognized file extension "${ext}". Add it to CONTENT_TYPES in this script if it's a valid Roblox upload type.`);
		process.exit(1);
	}

	const fileBuffer = fs.readFileSync(filePath);
	const requestPayload = {
		assetType,
		displayName,
		description: description || `Uploaded via asset-pipeline for Zundamon's Kitchen (${new Date().toISOString().slice(0, 10)})`,
		creationContext: {
			creator: { userId: CREATOR_USER_ID },
		},
	};

	const form = new FormData();
	form.append("request", JSON.stringify(requestPayload));
	form.append("fileContent", new Blob([fileBuffer], { type: contentType }), path.basename(filePath));

	console.log(`Uploading ${filePath} as ${assetType} "${displayName}"...`);

	const uploadRes = await fetch(`${API_BASE}/assets`, {
		method: "POST",
		headers: { "x-api-key": apiKey },
		body: form,
	});

	const uploadBody = await uploadRes.text();
	if (!uploadRes.ok) {
		console.error(`ERROR: upload request failed (${uploadRes.status}): ${uploadBody}`);
		process.exit(1);
	}

	let operation;
	try {
		operation = JSON.parse(uploadBody);
	} catch (e) {
		console.error(`ERROR: could not parse upload response as JSON: ${uploadBody}`);
		process.exit(1);
	}

	if (!operation.path) {
		console.error(`ERROR: no operation path in response: ${uploadBody}`);
		process.exit(1);
	}

	// Poll the operation until it resolves (asset moderation/processing takes
	// a few seconds typically).
	const operationUrl = `https://apis.roblox.com/assets/v1/${operation.path}`;
	console.log("Polling operation for completion...");
	for (let attempt = 0; attempt < 30; attempt++) {
		await new Promise((r) => setTimeout(r, 2000));
		const pollRes = await fetch(operationUrl, {
			headers: { "x-api-key": apiKey },
		});
		const pollBody = await pollRes.json();
		if (pollBody.done) {
			if (pollBody.error) {
				console.error(`ERROR: operation failed: ${JSON.stringify(pollBody.error)}`);
				process.exit(1);
			}
			const assetId = pollBody.response && pollBody.response.assetId;
			if (!assetId) {
				console.error(`ERROR: operation completed with no assetId: ${JSON.stringify(pollBody)}`);
				process.exit(1);
			}
			console.log(`SUCCESS: rbxassetid://${assetId}`);
			console.log(JSON.stringify({ filePath, assetType, displayName, assetId: String(assetId) }));
			return;
		}
	}
	console.error("ERROR: operation did not complete after 60s of polling.");
	process.exit(1);
}

main().catch((err) => {
	console.error("ERROR:", err);
	process.exit(1);
});
