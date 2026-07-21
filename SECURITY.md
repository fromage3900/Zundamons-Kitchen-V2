# Security Policy

## Supported Versions

Security fixes apply to the latest commit on the `main` branch and the corresponding published Roblox place synced via Rojo.

## Reporting a Vulnerability

**Do not** open public GitHub issues for exploitable security bugs.

1. Contact the repository owner privately (GitHub security advisory or direct message).
2. Include steps to reproduce, impact, and affected scripts/remotes if known.
3. Allow reasonable time to patch before public disclosure.

**Never** paste API keys, DataStore dumps, or player PII in reports.

## Scope

**In scope:**
- Server remote validation bypasses (inventory, economy, LLM abuse, monetization)
- Secret leakage in git or published place
- Client-trusted gameplay state that affects other players

**Out of scope:**
- Social engineering of the experience owner
- Issues in Roblox platform itself (report to Roblox)
- Placeholder DevProduct IDs in a pre-release branch

## Secure Development

- Run `npm run lint` before merging to `main`
- Keep LLM API keys in Studio `ServerStorage` only
- Review `docs/security-audit.md` for applied hardening
- Run `rojo build` to verify project compiles

## Recognition

We appreciate responsible disclosure. Contributors may be credited in release notes by agreement.
