# Office Applications Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the application catalog in `src/config/apps.json` to include IT development tools (VS Code, Python, Node.js), Designer CAD/GIS tools (QGIS, BricsCAD, ZWCAD, AutoCAD custom installer), and centralized Stirling PDF reader definitions.

**Architecture:** Add standard package IDs for Winget deployment via `Install-App` and add a custom installer script `src/app/autocad_install/install.ps1` for silent AutoCAD installation if local setup files are detected.

**Tech Stack:** PowerShell 5.1+, Winget, JSON.

## Global Constraints

- No Unicode non-ASCII characters in `.ps1` files.
- Number-only TUI navigation.
- No swallowed exceptions in installer scripts.
- Testing environment is Windows 11 in VirtualBox; agents perform code edits and syntax verification.

---

### Task 1: Update Application Catalog Schema (`src/config/apps.json`)

**Files:**
- Modify: `src/config/apps.json`

**Interfaces:**
- Consumes: Standard Winget package IDs (`Microsoft.VisualStudioCode`, `Python.Python.3.12`, `OpenJS.NodeJS.LTS`, `OSGeo.QGIS`, `Bricsys.BricsCAD`, `ZWSoft.ZWCAD`, `StrilingTools.StirlingPDF`).
- Produces: Application definitions readable by `src/tui/app/app_ui.ps1` and `src/app/install_app.ps1`.

- [ ] **Step 1: Validate existing JSON schema syntax**

Run JSON validation on `src/config/apps.json` using PowerShell in terminal:
```powershell
Get-Content -Raw src/config/apps.json | ConvertFrom-Json
```

- [ ] **Step 2: Add new application objects to `src/config/apps.json`**

Update `src/config/apps.json` to include `vscode`, `python`, `nodejs`, `qgis`, `bricscad`, `zwcad`, and `autocad`.

- [ ] **Step 3: Verify JSON formatting and validity**

Execute JSON conversion check:
```powershell
Get-Content -Raw src/config/apps.json | ConvertFrom-Json | Select-Object id, name, packageManager
```
Expected: List of all application objects including `vscode`, `python`, `nodejs`, `qgis`, `bricscad`, `zwcad`, `autocad`.

- [ ] **Step 4: Commit changes**

```bash
git add src/config/apps.json
git commit -m "feat(apps): add IT and Designer software packages to apps.json"
```

---

### Task 2: Create Custom AutoCAD Installer (`src/app/autocad_install/install.ps1`)

**Files:**
- Create: `src/app/autocad_install/install.ps1`

**Interfaces:**
- Consumes: Local installation directory `C:\ProgramData\SZC\InstallCache\autocad\`.
- Produces: Dot-sourceable installer script compatible with `Install-App`.

- [ ] **Step 1: Create `src/app/autocad_install/install.ps1`**

Write script logic to check for `C:\ProgramData\SZC\InstallCache\autocad\Setup.exe`, launch silent installation if present, or log an informative warning if absent.

- [ ] **Step 2: Test script syntax**

Run syntax check using PowerShell:
```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile("src/app/autocad_install/install.ps1", [ref]$null, [ref]$errors)
if ($errors) { $errors } else { "Syntax OK" }
```
Expected: `Syntax OK`

- [ ] **Step 3: Commit changes**

```bash
git add src/app/autocad_install/install.ps1
git commit -m "feat(autocad): add custom AutoCAD setup script"
```
