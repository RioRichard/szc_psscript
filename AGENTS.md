# Agent Guide: SZC PowerShell Scripts

This repository contains PowerShell scripts designed to automate the installation of common applications and network printers in the SZC office environment.

> **Agent Rule:** Always update this file at the end of every session to reflect the current state of the codebase, known issues, and deferred tasks.

---

## 🚀 How to Run

To run the main installation workflow, execute the entrypoint script in an **elevated (Administrator) PowerShell session**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
& ".\main.ps1"
```

---

## 📁 Repository Structure

*   `main.ps1`: The main entrypoint script. Imports and launches the TUI (`Start-Tui`).
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
        *   `install_app.ps1`: Generic helper function (`Install-App`) to install applications via `winget` or custom setup scripts.
        *   `install_commonapp.ps1`: Loads `apps.json` and iterates installs. *(Currently superseded by TUI coordinator — may be removed in future.)*
        *   `office_install/`: Files to deploy Microsoft 365:
            *   `install.ps1`: Custom script to download the Office Click-to-Run bootstrapper and configure it.
            *   `OfficeCustom.xml`: Custom ODT configuration file.
        *   `kes_install/`: Files to deploy Kaspersky Endpoint Security:
            *   `install.ps1`: Custom script to download and install Kaspersky silently.
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
*   Uses the Office Deployment Tool (ODT).
*   **XML Settings:** `OfficeCustom.xml` uses `O365BusinessRetail` (correct Product ID for Microsoft 365 Business Standard/Premium), `en-us` + `vi-vn` languages, excludes Teams, `Display Level="None" AcceptEULA="TRUE"` for fully silent install. Also includes `FORCEAPPSHUTDOWN` to close conflicting Office processes.
*   **Script behavior:** `install.ps1`:
    1. Removes any leftover partial/corrupt ODT download from a previous attempt.
    2. Downloads the **ODT self-extracting package** from `https://go.microsoft.com/fwlink/p/?LinkID=626065` using a two-method strategy:
       - **Method 1:** `Invoke-WebRequest` with `$ProgressPreference = 'SilentlyContinue'` and `-MaximumRedirection 10`. If the downloaded file is missing or < 100KB, falls back to Method 2.
       - **Method 2:** `System.Net.WebClient.DownloadFile()`, which handles fwlink redirects more reliably.
    3. Validates the download: checks if the file is < 500KB (real ODT is ~3.4 MB) and sniffs the file header for HTML content (redirect/error page detection). Throws a descriptive error if validation fails.
    4. Extracts `setup.exe` from it using `/quiet /extract:"<dir>"`.
    5. Copies `OfficeCustom.xml` to the cache dir (space-free path).
    6. Runs `setup.exe /configure "<xml path>"` for a fully silent, unattended install.
    7. Cleans up on success; leaves files for debugging on failure.
*   **Why not `OfficeSetup.exe`:** The consumer bootstrapper from the Microsoft 365 portal does NOT support `/configure <xml>`. It is UI-only and silently ignores the argument, giving a misleading success exit code. Always use `setup.exe` from the ODT package.
*   **Download gotchas (fwlink redirect):** The `go.microsoft.com/fwlink` URL is a redirector. `Invoke-WebRequest` can fail to follow the redirect (downloading an HTML page instead of the binary) or the progress bar can stall/corrupt the download stream. The script now disables `$ProgressPreference`, adds `-MaximumRedirection 10`, and falls back to `System.Net.WebClient` if Method 1 fails. It also sniffs the downloaded file for HTML content to give a clear error message.
*   **Path quoting:** `Start-Process -ArgumentList` joins array elements with spaces — paths are wrapped in escaped quotes `` `"$path`" `` and the XML is also copied to a space-free cache dir as double protection.
*   **Logs:** If the installer fails, ODT writes detailed logs to `%TEMP%`. Check those for the root cause.
*   **Status:** 🧪 Testing — download reliability fixes applied, pending user verification on Windows.

### 3. Kaspersky Deployment (`src/app/kes_install/`)
*   The Kaspersky installer (`keswin_*.exe`) is a Nullsoft Installer (NSIS) self-extracting archive that does **not** accept standard silent flags directly.
*   **Approach:** The script renames the downloaded `.exe` to `.7z`, then uses the **7-Zip CLI** (`7z.exe x ...`) to extract its contents. The real setup executable is then found inside the extracted folder and run with `/s /pEULA=1 /pPRIVACYPOLICY=1`.
*   **Prerequisite:** **7-Zip must be installed before KES.** All department profiles in `departments.json` are ordered so `7zip` comes before `kes`. Do not reorder them.
*   **Extracted files location:** `C:\ProgramData\SZC\InstallCache\kes_extracted\`. Left in place on failure for debugging.
*   **Status:** 🧪 Testing — fixes applied, pending user verification on Windows.

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
*   **Adding a new department:** Add a new entry to `src/config/departments.json` with `id`, `name`, `apps` (list of app ids from `apps.json`), and `printers` (list of printer ids from `printers.json`). No code changes needed — TUI picks it up automatically.
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
*   **Elevation Required:** Almost all commands (including `winget`, `Add-PrinterPort`, and installers) require elevated Administrator privileges.
*   **Testing & Execution Environment:** The target development and runtime environment is a Windows 11 system running inside Ultrabox. Because of this, agents should **NOT** attempt to execute or test the PowerShell scripts in the agent sandbox. The user will test and verify the code manually.

---

## 📋 Known Issues & Deferred Tasks

| Item | Status | Notes |
|------|--------|-------|
| Office 365 installer | 🧪 Testing | Two-method download (Invoke-WebRequest → WebClient fallback), disabled ProgressPreference, MaximumRedirection 10, HTML sniffing for corrupt/redirect pages, lowered size threshold to 500KB. Pending user verification. |
| Kaspersky installer | 🧪 Testing | Renamed to `.7z`, extracted with 7-Zip CLI, runs real setup silently. 7-Zip must be installed first. Pending user verification. |
| `Install-App` swallows errors | ✅ Fixed | Removed `try/catch/finally` wrapper; errors now propagate so TUI can detect failures correctly |
| `$Custom` array type check | ✅ Fixed | Replaced `[String]::IsNullOrWhiteSpace($Custom)` (broke on arrays) with `$Custom.Count -gt 0`; typed param as `[String[]]`; splatted with `@Command` |
| Custom scripts run in child `powershell.exe` | ✅ Fixed | Switched from spawning child process to dot-sourcing (`. $CustomScript`) so throws and output propagate correctly |
| Wrong Office installer URL | ✅ Fixed | Old URL (linkid=2264705) downloaded consumer `OfficeSetup.exe` which ignores `/configure`. Now uses ODT package (LinkID=626065) |
| Printer implementation | 🚧 Pending | Waiting on printer hardware info (IPs, models, drivers) |
