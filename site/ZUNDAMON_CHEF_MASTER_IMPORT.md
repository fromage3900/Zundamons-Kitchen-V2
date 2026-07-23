# Zundamon Chef Master NPC Import Contract

The future gamewide Zundamon NPC is the emotional home base for chef progression. Players should return after earning XP to celebrate rank milestones, preview the next unlock, and receive a short scripted VN moment. Keep `RewardCore` authoritative for XP and levels.

## Studio model contract

1. Import the model as `ZundamonChefMaster` under `Workspace/NPCs`.
2. Give it a `PrimaryPart`; keep visual mesh parts inside the model.
3. Add CollectionService tag `ChefMasterNPC`.
4. Add attributes `NPCId = "zundamon_chef_master"`, `SpeakerKey = "chef_master"`, `InteractionDistance = 12`, and `PromptText = "Review Chef Journey"`.
5. Do not embed LocalScripts, remotes, or progression logic in the mesh.

## Intended promotion flow

`Interact → validate player/profile/distance → show tier and next requirement → confirm promotion → RewardCore validates banked XP → apply once → project HUD → play VN celebration`.

Levels currently advance automatically in `RewardCore`, so the first imported NPC should be informational. Moving to banked-XP promotions requires an explicit schema/migration decision and parity tests; do not silently change it during mesh import.

Place the NPC beside a recognizable kitchen landmark with a calm return path, warm green/gold glow, a chef-rank pennant, and one clear prompt. Dialogue should recognize the current tier, celebrate effort, preview one attainable goal, and never shame slow progress.

## Companion mesh variants

Repository-authored companion models override asset-ID fallbacks. Add each model under `src/shared/Models/Companions` using the exact key: `zundamon`, `zundacat`, `zundabunny`, `tantanmon`, `ankomon`, `cardamon`, `antimon`, or `sakuradamon`. Each must be a Model with a PrimaryPart (or at least one BasePart). Do not embed scripts; follow behavior, dialogue, VFX, ownership, and buffs remain keyed by the model name.
