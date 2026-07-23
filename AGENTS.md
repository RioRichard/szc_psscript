# Agent Guide: SZC PowerShell Scripts

This repository contains PowerShell scripts designed to automate the installation of common applications and network printers in the SZC office environment.

> **Agent Rule:** Always update this file at the end of every session to reflect the current state of the codebase, known issues, and deferred tasks.

---

## 🚀 How to Run

To run the main installation workflow, execute the entrypoint script in PowerShell:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
& ".\main.ps1"
```

**Note:** `main.ps1` automatically detects if it is not running as Administrator and re-launches itself elevated via a UAC prompt. You do not need to manually right-click "Run as Administrator".

---

## 📁 Repository Structure

*   `main.ps1`: The main entrypoint script. Checks for Administrator privileges (auto-elevates via UAC if needed), then imports and launches the TUI (`Start-Tui`).
*   `src/`: Core script directory:
    *   `tui/`: Directory containing the split Text User Interface:
        *   `tui.ps1`: The TUI coordinator entrypoint.
        *   `components/utils.ps1`: Shared UI components (headers, dividers, press-enter prompt).
        *   `app/app_ui.ps1`: Application selection interface.
        *   `printer/printer_ui.ps1`: Printer selection interface.
        *   `information/info_ui.ps1`: System information collection interface.
    *   `config/`: Directory containing configuration files:
        *   `apps.json`: Application definitions (id, name, package, packageManager, customScript).
        *   `printers.json`: Printer definitions (id, name, url, port, driver, urlDriver).
        *   `departments.json`: Department profiles — each references apps and printers by `id`.
    *   `app/`: Directory containing application installation logic:
        *   `install_app.ps1`: Generic helper function (`Install-App`) to install applications via `winget` or custom setup scripts. Dot-sources `download_helper.ps1`.
        *   `download_helper.ps1`: Standalone multi-connection parallel downloader (`Start-MultiDownload`) using HTTP Range requests, PowerShell runspaces, real-time `Write-Progress` monitoring (MB/s speed & % completion), and BITS/WebClient fallbacks.
        *   `install_commonapp.ps1`: Loads `apps.json` and iterates installs. *(Currently superseded by TUI coordinator — may be removed in future.)*
        *   `office_install/`: Files to deploy Microsoft 365:
            *   `install.ps1`: Custom script to download `setup.exe` from the Office CDN and run `/configure`.
            *   `OfficeCustom.xml`: Custom ODT configuration file.
        *   `kes_install/`: Files to deploy Kaspersky Endpoint Security:
            *   `install.ps1`: Custom script to download and install Kaspersky silently using `Start-MultiDownload`.
        *   `autocad_install/`: Files to deploy AutoCAD:
            *   `install.ps1`: Custom script to run silent installation if `C:\ProgramData\SZC\InstallCache\autocad\Setup.exe` exists, or skip gracefully with an informative message if absent.
    *   `printer/`: Directory containing printer installation logic:
        *   `install_printer.ps1`: Core function (`Install-LocalPrinter`) to add printer ports, download/install drivers, and configure printers.
        *   `printers_dn.ps1`: Defines local/network printer profiles and triggers installation.

---

## 🛠️ Architecture & Core Components

### 1. Common Application Installer (`src/app/install_app.ps1`)
The `Install-App` function handles generic installations.
*   **Winget Mode:** If `$Custom` is empty/null, it calls `winget install -e --id <PackageName> --accept-package-agreements --accept-source-agreements -h`.
*   **Custom Mode:** If `$Custom` is a non-empty `[String[]]` array, it splats the array as arguments to `$PackageManager` (e.g. `powershell -ExecutionPolicy ByPass <scriptPath>`).
*   **Error propagation:** The function does **not** catch exceptions — it lets them bubble up to the caller (the TUI's `Start-Deployment`). It also checks `$LASTEXITCODE` and throws if the process exited non-zero.
*   **Signature:**
    ```powershell
    Install-App -Name <String> -PackageName <String> -PackageManager <String> -Custom <String[]>
    ```

### 2. Microsoft Office Deployment (`src/app/office_install/`)
*   Uses the Office Deployment Tool (ODT) `setup.exe`.
*   **XML Settings:** `OfficeCustom.xml` uses `O365BusinessRetail` (correct Product ID for Microsoft 365 Business Standard/Premium), `en-us` + `vi-vn` languages, excludes Teams, `Display Level="Full" AcceptEULA="TRUE"` for installation with a visible progress bar. Also includes `FORCEAPPSHUTDOWN` to close conflicting Office processes.
*   **Script behavior:** `install.ps1`:
    1. Removes any leftover partial/corrupt download from a previous attempt.
    2. Downloads `setup.exe` directly from the **Office CDN** (`https://officecdn.microsoft.com/pr/wsus/setup.exe`) using a three-method fallback strategy:
       - **Method 1:** `curl.exe -L` (ships with Windows 10 1803+ / Windows 11). Most reliable, handles redirects natively, retries 3 times.
       - **Method 2:** `Invoke-WebRequest` with `$ProgressPreference = 'SilentlyContinue'` and `-MaximumRedirection 10`.
       - **Method 3:** `System.Net.WebClient.DownloadFile()`.
    3. Validates the download: checks if the file is < 10KB and sniffs the file header for HTML content (error page detection). The CDN `setup.exe` is a small bootstrapper, so only very tiny files (HTML error pages) are rejected. Throws a descriptive error if validation fails.
    4. Copies `OfficeCustom.xml` to the same directory as `setup.exe`.
    5. Runs `setup.exe /configure OfficeCustom.xml` for an unattended install with a visible progress UI (uses `-WorkingDirectory` to avoid path issues).
*   **Why Office CDN, not fwlink:** The old fwlink URL (`go.microsoft.com/fwlink/p/?LinkID=626065`) redirects to the **Microsoft Download Center HTML page** (not a direct binary). Both `Invoke-WebRequest` and `WebClient` download the HTML page instead of the executable, resulting in a ~5KB file that fails validation. The Office CDN URL (`officecdn.microsoft.com/pr/wsus/setup.exe`) is a **direct binary link** — no redirects, no HTML pages.
*   **Why not `OfficeSetup.exe`:** The consumer bootstrapper from the Microsoft 365 portal does NOT support `/configure <xml>`. It is UI-only and silently ignores the argument, giving a misleading success exit code. Always use `setup.exe` from the ODT / Office CDN.
*   **Logs:** If the installer fails, ODT writes detailed logs to `%TEMP%`. Check those for the root cause.
*   **Status:** 🧪 Testing — switched from fwlink to Office CDN direct URL, pending user verification on Windows.

### 3. Kaspersky Deployment (`src/app/kes_install/`)
*   The Kaspersky installer (`keswin_*.exe`) is a Nullsoft Installer (NSIS) self-extracting archive that does **not** accept standard silent flags directly.
*   **Approach:** The script renames the downloaded `.exe` to `.7z`, then uses the **7-Zip CLI** (`7z.exe x ...`) to extract its contents.
*   **Installer discovery:** The script prioritizes finding `*.msi` first in the extracted folder.
    *   **If `.msi` is found:** Runs `msiexec.exe /i "<msi>" /passive EULA=1 PRIVACYPOLICY=1 KSN=0`. `/passive` displays an unattended progress bar (no user clicks required), while `EULA=1 PRIVACYPOLICY=1 KSN=0` satisfies all agreements automatically.
    *   **If `.exe` is found:** Runs `$installer.FullName` with `@("/s", "/pEULA=1", "/pPRIVACYPOLICY=1", "/pKSN=0", "/v""/passive EULA=1 PRIVACYPOLICY=1 KSN=0""")`.
*   **Prerequisite:** **7-Zip must be installed before KES.** This is enforced via the `"dependencies": ["7zip"]` field in `apps.json`. The TUI's `Start-Deployment` function automatically adds missing dependencies and reorders the install list so dependencies install first. Do not remove this dependency.
*   **Extracted files location:** `C:\ProgramData\SZC\InstallCache\kes_extracted\`. Left in place on failure for debugging.
*   **Status:** ✅ Working — extracts with 7-Zip CLI and runs `.msi` directly with `/passive EULA=1 PRIVACYPOLICY=1 KSN=0` for an unattended installation with progress bar.

### 4. Printer Installer (`src/printer/install_printer.ps1`)
*   **Automatic discovery:** If no port/driver is specified, it uses WS-Discovery/TCP-IP discovery to install printers automatically.
*   **Manual Port & Driver setup:** If `$Port` and `$Driver` are specified:
    1.  Checks if the port exists; creates a standard TCP/IP port if missing.
    2.  Checks if the printer driver is installed; if missing and `$UrlDriver` is provided, downloads and runs the driver installer.
    3.  Adds the local printer with the specified port and driver.
*   **Gotchas:**
    *   Ensure parameter binding matches: use `-UrlDriver` when calling `Install-LocalPrinter` (do not confuse with `$DriverUrl`).
*   **Status:** 🚧 Implementation deferred. Printer information (IPs, drivers, models) not yet collected. The TUI option is marked **Coming Soon**.

### 5. TUI (`src/tui/`)
*   Entry point is `Start-Tui`, called from `main.ps1` via `src/tui/tui.ps1`.
*   **Department Profiles:** Loaded from `config/departments.json` at startup. Each department has a preset list of `Apps` and `Printers` referenced by `id`. The JSON ids are resolved to display names using `$CommonApps` and `$Printers` at load time. Selecting a department auto-checks the relevant items.
*   **Navigation rule:** All menus use **numbers only** for input. Letter-based shortcuts (A/N/Q/C) are not used anywhere. Extra options (Select All, Deselect All, Back) are appended as numbered items after the list.
*   **Flow:**
    1. User selects a **Department Profile** (e.g., Ke Toan, Ky Thuat) which preloads a recommended set of apps and printers.
    2. User can optionally **customize** the app/printer selection manually.
    3. User can run **Collect System Information**, which gathers OS, CPU, RAM, disk, IP, MAC info and saves a report to `C:\ProgramData\SZC\`.
    4. User triggers **Start Deployment** to install selected apps and printers.
*   **Adding a new department:** Add a new entry to `src/config/departments.json` with `id`, `name`, `apps` (list of app ids from `apps.json`), and `printers` (list of printer ids from `printers.json`). No code changes needed -- TUI picks it up automatically.
*   **App Dependencies:** Apps in `apps.json` can declare a `"dependencies"` array listing other app `id`s that must be installed first (e.g., KES depends on 7-Zip). At deployment time, `Start-Deployment` automatically adds any missing dependencies to the install list and reorders so dependencies install before dependents. This is purely data-driven -- adding a dependency only requires editing `apps.json`.
*   **Empty printer list:** If `printers.json` has no entries, the printer selection screen shows a friendly "No printers configured yet" message instead of an empty menu.

---

## 🗺️ Project Phases

The automation suite is organized into 4 distinct phases:

1.  **Install Application Phase:** *(Active)* Automating the installation of standard applications via Winget or custom silent setup scripts (e.g., Microsoft Office, Kaspersky, Chrome, UniKey). Core installer bugs fixed — pending user verification.
2.  **Install Printer Phase:** *(Deferred)* Waiting on printer hardware information (IPs, models, drivers). TUI menu option shows "Coming Soon".
3.  **Collect Information Phase:** *(Implemented)* Gathers OS, CPU, RAM, disk, IP, MAC info and saves a report to `C:\ProgramData\SZC\SystemInfo_<ComputerName>.txt`.
4.  **TUI (Text User Interface) Phase:** *(Active)* Interactive CLI menu driven by user department profiles. Allows selecting apps/printers per department, manual overrides, system information collection, and deployment.

---

## ⚠️ Important Gotchas for Future Agents

*   **Always update `AGENTS.md`** at the end of every session. This is the memory for the next agent.
*   **Number-only navigation:** All TUI menus use numbers exclusively. Do NOT introduce letter-based shortcuts (A, N, Q, C, etc.) into any menu. Extra actions (Select All, Back, etc.) are always appended as the next numbered item after the list.
*   **`$PSScriptRoot` vs dot-source:** `$PSScriptRoot` resolves to the **caller's** directory when a script is dot-sourced. Custom install scripts (`office_install/install.ps1`, `kes_install/install.ps1`) must use `Split-Path $MyInvocation.MyCommand.Path -Parent` to reliably find their own directory.
*   **Custom scripts are dot-sourced, not subprocess:** `Install-App` dot-sources custom scripts (`. $CustomScript`) directly in the current process. This means `throw` inside a custom script propagates straight up to the TUI's `try/catch`, and all `Write-Host` output appears in the TUI console. Do NOT change this back to spawning a child `powershell.exe` — that approach hid errors and output.
*   **String Interpolation in Catch Blocks:** In error handling, ensure you use subexpression syntax `$($_...)` instead of `${$_...}` to interpolate properties of the current error object.
    *   *Correct:* `Write-Error "Reason: $($_.Exception.Message)"`
    *   *Incorrect:* `Write-Error "Reason: ${$_.Exception.Message}"`
*   **`$Custom` is a `[String[]]` array, not a string:** `Install-App`'s `$Custom` parameter is typed `[String[]]`. Splat it with `@Command` (not `$Command`) when calling the interpreter. Do NOT pass it to `[String]::IsNullOrWhiteSpace()` — use `$Custom.Count -gt 0` to check for content.
*   **`Install-App` must NOT swallow errors:** The function must let exceptions propagate to the caller so the TUI's `try/catch` in `Start-Deployment` can correctly mark installs as FAILED. Never wrap the entire function body in a `try/catch` that only writes a non-terminating error.
*   **Elevation Required:** Almost all commands (including `winget`, `Add-PrinterPort`, and installers) require elevated Administrator privileges. `main.ps1` auto-elevates via UAC if not already running as Administrator -- do NOT remove this check.
*   **Do NOT use the fwlink URL for ODT:** `go.microsoft.com/fwlink/p/?LinkID=626065` redirects to an HTML Download Center page, not a binary. Always use the Office CDN direct URL `https://officecdn.microsoft.com/pr/wsus/setup.exe`.
*   **No Unicode special characters in .ps1 files:** Never use em-dash, en-dash, curly quotes, or any non-ASCII character in PowerShell scripts. They cause parse errors depending on system encoding. Use only plain ASCII: `--` instead of em-dash, straight quotes `"` instead of curly quotes, etc.
*   **Testing & Execution Environment:** The target development and runtime environment is a Windows 11 system running inside VirtualBox. Because of this, agents should **NOT** attempt to execute or test the PowerShell scripts in the agent sandbox. The user will test and verify the code manually.

---

## 📋 Known Issues & Deferred Tasks

| Item | Status | Notes |
|------|--------|-------|
| Office 365 installer | ✅ Fixed | Office CDN direct URL, three-method download fallback (curl.exe -> Invoke-WebRequest -> WebClient). Size threshold lowered to 10KB (CDN setup.exe is a small bootstrapper). HTML sniffing. All Unicode chars removed from script. Display Level set to "Full" to show progress UI. |
| Auto-elevation in main.ps1 | ✅ Done | `main.ps1` checks for Administrator role and re-launches elevated via `-Verb RunAs` UAC prompt if needed. |
| Kaspersky installer | ✅ Working | Prioritizes `.msi` directly with `/passive EULA=1 PRIVACYPOLICY=1 KSN=0` for unattended installation with progress bar (no user interaction required). Verified working on VirtualBox. |
| `Install-App` swallows errors | ✅ Fixed | Removed `try/catch/finally` wrapper; errors now propagate so TUI can detect failures correctly |
| `$Custom` array type check | ✅ Fixed | Replaced `[String]::IsNullOrWhiteSpace($Custom)` (broke on arrays) with `$Custom.Count -gt 0`; typed param as `[String[]]`; splatted with `@Command` |
| Custom scripts run in child `powershell.exe` | ✅ Fixed | Switched from spawning child process to dot-sourcing (`. $CustomScript`) so throws and output propagate correctly |
| fwlink ODT URL broken | ✅ Fixed | `go.microsoft.com/fwlink/p/?LinkID=626065` redirects to Download Center HTML page, not binary. Replaced with Office CDN direct URL. |
| Printer implementation | 🚧 Pending | Waiting on printer hardware info (IPs, models, drivers). Temporarily removed from Start-Deployment script entirely as it's on hold. |
| Office App Expansion | 🧪 Ready for VirtualBox Testing | Added `vscode`, `python`, `nodejs`, `qgis`, `zwcad`, and `autocad` (AutoCAD LT via `src/app/autocad_install/install.ps1`) to `apps.json`. Ready for verification on Windows 11. |
