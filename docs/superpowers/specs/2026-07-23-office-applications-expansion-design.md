# Design Specification: Office Applications Expansion & Catalog Updates

**Date:** 2026-07-23  
**Status:** Approved  
**Author:** Antigravity & User  

---

## 1. Overview & Objective

This design expands the application catalog (`src/config/apps.json`) for the SZC office automation suite. The target groups catered for are:
- **IT / Developers**: Tools for coding, scripting, and runtime environments (VS Code, Python 3, Node.js LTS).
- **Designer Group**: Tools for CAD and GIS drafting (QGIS, BricsCAD, ZWCAD, AutoCAD custom setup).
- **Common Office / All Groups**: Centralized PDF tool access (Stirling PDF / standard readers) and core office suite applications.

Department profile updates in `src/config/departments.json` will be maintained directly by the user at a later stage.

---

## 2. Architecture & File Changes

### 2.1 Configuration Updates (`src/config/apps.json`)

The following new entries will be added to `src/config/apps.json`:

```json
[
  {
    "id": "vscode",
    "name": "Visual Studio Code",
    "package": "Microsoft.VisualStudioCode",
    "packageManager": "winget"
  },
  {
    "id": "python",
    "name": "Python 3",
    "package": "Python.Python.3.12",
    "packageManager": "winget"
  },
  {
    "id": "nodejs",
    "name": "Node.js LTS",
    "package": "OpenJS.NodeJS.LTS",
    "packageManager": "winget"
  },
  {
    "id": "qgis",
    "name": "QGIS",
    "package": "OSGeo.QGIS",
    "packageManager": "winget"
  },
  {
    "id": "zwcad",
    "name": "ZWCAD",
    "package": "ZWSoft.ZWCAD",
    "packageManager": "winget"
  },
  {
    "id": "autocad",
    "name": "AutoCAD LT",
    "package": "",
    "packageManager": "powershell",
    "customScript": "app/autocad_install/install.ps1"
  }
]
```

### 2.2 Custom AutoCAD Installer (`src/app/autocad_install/install.ps1`)

A custom deployment script will be created at `src/app/autocad_install/install.ps1`.
- **Purpose**: Installs AutoCAD silently if a deployment setup payload exists in `C:\ProgramData\SZC\InstallCache\autocad\`.
- **Behavior**:
  1. Checks for the local directory `C:\ProgramData\SZC\InstallCache\autocad\Setup.exe`.
  2. If present, executes `Setup.exe -q` (Autodesk quiet installation mode).
  3. If absent, logs an informative warning instructing the admin where to place Autodesk deployment files and exits gracefully (`exit 0`).

---

## 3. Installation Execution & Error Handling

- **Winget Packages**: `Install-App` executes `winget install -e --id <Package> --accept-package-agreements --accept-source-agreements -h`. Standard exit codes bubble up to the TUI caller.
- **Custom Scripts**: Custom scripts are dot-sourced in-process by `Install-App`. Any terminating exceptions propagate to the TUI retry/skip handler.

---

## 4. Verification Criteria

1. `apps.json` valid JSON syntax validation.
2. All new package IDs (`vscode`, `python`, `nodejs`, `qgis`, `bricscad`, `zwcad`, `autocad`) correctly recognized by TUI selection screen (`src/tui/app/app_ui.ps1`).
3. `autocad_install/install.ps1` executes gracefully when installer files are present or absent.
