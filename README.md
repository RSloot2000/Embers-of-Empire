# Embers of Empire — CK3 Mod

Development repository for **Embers of Empire — A Roman Restoration**, a Crusader Kings III mod, plus compatibility patches for popular third-party mods.

> Target: **CK3 1.19.X**

## What's Here

- **`eoe-mods/`** — the main mod and all compatibility patches (editable)
- **`CE`, `EpE`, `IT`** — read-only source mods used as patch references (never edit)
- **`scripts/`** — build, deploy, and validation tooling
- **`workshop/`** — Steam Workshop metadata and upload text
- **`refs/`** — guides, handoffs, and reference material

## Quick Start

1. Open this folder as a VS Code workspace.
2. Deploy local DEV copies to your CK3 mod directory:

   ```powershell
   ./scripts/deploy-dev.ps1
   ```

3. Build release ZIPs:

   ```powershell
   ./scripts/build-release.ps1
   ```

## Useful Scripts

| Script | What it does |
|---|---|
| `deploy-dev.ps1` | Copies mods to your local CK3 `mod/` folder (never touches Steam) |
| `build-release.ps1` | Builds one clean release ZIP per mod under `dist/` |
| `validate-repository.ps1` | Checks repo structure, descriptors, and localization files |
| `fetch-workshop-metadata.ps1` | Refreshes the public Workshop metadata snapshot |
