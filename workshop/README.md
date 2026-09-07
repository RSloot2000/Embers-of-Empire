# Workshop Metadata

This directory stores public Steam Workshop snapshots and proposed upload text. It does not publish anything to Steam.

## Files

- `current-metadata.json` is a generated snapshot of the current public pages. Do not edit it manually.
- `descriptions/*.bbcode` contains proposed replacement descriptions.
- `change-notes/*.bbcode` contains proposed notes for runtime items that differ from the locally installed Workshop snapshots.
- `scripts/fetch-workshop-metadata.ps1` refreshes the public snapshot without authentication or publication access.

Run the fetcher from the repository root:

`./scripts/fetch-workshop-metadata.ps1`

Descriptions can be edited on Steam without uploading mod files. Tags, required items, preview images, visibility, and change notes are managed separately in the Steam Workshop interface. No online field should be changed without explicit user approval.

## Current Items

| Repository mod | Workshop ID | Current Steam compatibility tag | Proposed tag | Required items |
|---|---:|---|---|---|
| EoE main | `3679840613` | `1.19 'Scribe'` | unchanged | None declared |
| EoE + EPE | `3679849030` | `1.18 'Crane'` | `1.19 'Scribe'` | EoE `3679840613`; EPE `2507209632` |
| EoE + Immersive Toponyms | `3679849283` | `1.18 'Crane'` | `1.19 'Scribe'` | EoE `3679840613`; IT `2255229872` |
| EoE + Culture Expanded | `3679850009` | `1.18 'Crane'` | `1.19 'Scribe'` | EoE `3679840613`; CE `2829397295` |

All four descriptors declare `supported_version="1.19.0.6"`. The three compatibility descriptors also still contain the old `1.18 'Crane'` tag. Update both descriptor tags and Steam tags deliberately as part of a validated release, not as an isolated metadata edit.

## Local Workshop Delta Audit

Comparison source: repository files against the locally installed Workshop snapshots under Steam app `1158310`, using relative paths and SHA-256.

| Mod | Added in repo | Changed | Missing from repo | Status |
|---|---:|---:|---:|---|
| EoE main | 26 | 83 | 1,970 | Publication blocked pending asset review |
| EoE + EPE | 1 | 2 | 0 | Change-note draft prepared |
| EoE + Immersive Toponyms | 0 | 1 | 0 | Change-note draft prepared |
| EoE + Culture Expanded | 0 | 0 | 0 | No runtime change note required |

Of the 1,970 files present in the local main-mod Workshop snapshot but absent from the repository, 1,965 are under `gfx/`. Do not build or publish the main mod until this delta is explained and the resulting release archive is checked in CK3. It may represent intentional cleanup, incomplete migration, or Workshop-only assets; the counts alone cannot determine which.

The main repository also contains `.vscode/settings.json`, which is excluded by the release builder and must never be treated as shipped mod content.

## Pre-Publish Rules

1. Refresh `current-metadata.json` and review the public pages for changes made outside Git.
2. Read `docs/VERSIONING_AND_WORKSHOP.md` and `docs/DEVELOPMENT.md`.
3. Verify descriptors, versions, tags, Workshop IDs, required items, and load order.
4. Complete Toolkit, Tiger, DEV deployment, mount, and in-game validation.
5. Resolve the main-mod asset blocker before any main-mod upload.
6. Review descriptions and change notes as rendered BBCode.
7. Publish only the explicitly approved fields and items.
8. Refresh the snapshot after publication and commit the final public metadata separately.

Steam credentials, API keys, cookies, Steam Guard codes, and tokens must never be stored here or passed through chat.
