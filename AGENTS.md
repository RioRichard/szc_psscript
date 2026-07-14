# Agent Guide: SZC PowerShell Scripts

This repository contains PowerShell scripts designed to automate the installation of common applications and network printers in the SZC office environment.

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
        *   `components/utils.ps1`: Shared UI components (headers, dividers).
        *   `app/app_ui.ps1`: Application selection interface.
        *   `printer/printer_ui.ps1`: Printer selection interface.
        *   `information/info_ui.ps1`: System information collection interface.
    *   `config/`: Directory containing configuration files:
        *   `apps.json`: Application definitions (id, name, package, packageManager, customScript).
        *   `printers.json`: Printer definitions (id, name, url, port, driver, urlDriver).
        *   `departments.json`: Department profiles — each references apps and printers by `id`.
    *   `app/`: Directory containing application installation logic:
        *   `install_app.ps1`: Generic helper function (`Install-App`) to install applications via `winget` or custom setup scripts.
        *   `install_commonapp.ps1`: Defines the array of applications to install (`$CommonApps`) and iterates through them.
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
*   **Winget Mode:** If no `$Custom` command is provided, it calls `winget install -e --id <PackageName>`.
*   **Custom Mode:** If `$Custom` is provided, it executes the command via the interpreter program defined in `$PackageManager`.
*   **Signature:**
    ```powershell
    Install-App -Name <String> -PackageName <String> -PackageManager <String> -Custom <Array/String>
    ```

### 2. Microsoft Office Deployment (`src/app/office_install/`)
*   Uses the Office Deployment Tool (ODT).
*   **XML Settings:** In `OfficeCustom.xml`, display level must be configured correctly. Use `<Display Level="None" AcceptEULA="TRUE"/>` for fully silent unattended installs. Avoid invalid values like `"True"`.

### 3. Kaspersky Deployment (`src/app/kes_install/`)
*   The Kaspersky installer (`keswin_*.exe`) is a Nullsoft Installer (NSIS) self-extracting archive.
*   **Parameters:** It accepts `/s` for silent installation, `/pEULA=1` to accept the license agreement, and `/pPRIVACYPOLICY=1` to accept the privacy policy.
*   **Execution:** Run the executable directly with arguments: `/s`, `/pEULA=1`, `/pPRIVACYPOLICY=1`. Do not attempt to unpack it using 7-Zip (since 7-Zip may not be installed yet).

### 4. Printer Installer (`src/printer/install_printer.ps1`)
*   **Automatic discovery:** If no port/driver is specified, it uses WS-Discovery/TCP-IP discovery to install printers automatically.
*   **Manual Port & Driver setup:** If `$Port` and `$Driver` are specified:
    1.  Checks if the port exists; creates a standard TCP/IP port if missing.
    2.  Checks if the printer driver is installed; if missing and `$UrlDriver` is provided, downloads and runs the driver installer.
    3.  Adds the local printer with the specified port and driver.
*   **Gotchas:**
    *   Ensure parameter binding matches: use `-UrlDriver` when calling `Install-LocalPrinter` (do not confuse with `$DriverUrl`).

### 5. TUI (`src/tui/`)
*   Entry point is `Start-Tui`, called from `main.ps1` via `src/tui/tui.ps1`.
*   **Department Profiles:** Loaded from `config/departments.json` at startup. Each department has a preset list of `Apps` and `Printers` referenced by `id`. The JSON ids are resolved to display names using `$CommonApps` and `$Printers` at load time. Selecting a department auto-checks the relevant items.
*   **Flow:**
    1. User selects a **Department Profile** (e.g., Ke Toan, Ky Thuat) which preloads a recommended set of apps and printers.
    2. User can optionally **customize** the app/printer selection manually.
    3. User can run **Collect System Information**, which gathers OS, CPU, RAM, disk, IP, MAC info and saves a report to `C:\ProgramData\SZC\`.
    4. User triggers **Start Deployment** to install selected apps and printers.
*   **Adding a new department:** Add a new entry to `src/config/departments.json` with `id`, `name`, `apps` (list of app ids from `apps.json`), and `printers` (list of printer ids from `printers.json`). No code changes needed — TUI picks it up automatically.

---

## 🗺️ Project Phases

The automation suite is organized into 4 distinct phases:

1.  **Install Application Phase:** Automating the installation of standard applications via Winget or custom silent setup scripts (e.g., Microsoft Office, Kaspersky, Chrome, UniKey).
2.  **Install Printer Phase:** Autodetecting and configuring network/local printers, creating printer ports, and downloading/installing printer drivers.
3.  **Collect Information Phase:** *(Planned)* Gathering system configuration, hardware inventory, and network environment info.
4.  **TUI (Text User Interface) Phase:** *(Active)* Interactive CLI menu driven by user department profiles. Allows selecting apps/printers per department, manual overrides, system information collection, and deployment.

---

## ⚠️ Important Gotchas for Future Agents

*   **PSScriptRoot Behavior:** `$PSScriptRoot` evaluates to the directory containing the file in which it is referenced. Be mindful of parent-child calling contexts.
*   **String Interpolation in Catch Blocks:** In error handling, ensure you use subexpression syntax `$($_...)` instead of `${$_...}` to interpolate properties of the current error object.
    *   *Correct:* `Write-Error "Reason: $($_.Exception.Message)"`
    *   *Incorrect:* `Write-Error "Reason: ${$_.Exception.Message}"`
*   **Elevation Required:** Almost all commands (including `winget`, `Add-PrinterPort`, and installers) require elevated Administrator privileges.
*   **Testing & Execution Environment:** The target development and runtime environment is a Windows 11 system running inside Ultrabox. Because of this, agents should **NOT** attempt to execute or test the PowerShell scripts in the agent sandbox. The user will test and verify the code manually.
