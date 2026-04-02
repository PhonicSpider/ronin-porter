# 🛡️ Windows Firewall Game Server Porter

A robust, automated PowerShell utility designed to manage inbound firewall rules for game servers. This script simplifies the process of opening and closing port ranges for both **TCP** and **UDP** protocols simultaneously, ensuring high-performance connectivity for servers like *Space Engineers*, *Minecraft*, *Valheim*, and more.

## 🚀 Key Features

* **Dual Protocol Support:** Automatically creates separate, synchronized rules for TCP and UDP.
* **Intelligent Cleanup:** A "RemoveOnly" mode allows you to decommission server ports instantly without leaving "ghost" rules in your firewall.
* **Auto-Elevation:** Automatically detects if it is running with Administrator privileges and requests them if necessary.
* **Developer Debug Mode:** Toggleable verbose logging to troubleshoot Windows API errors or port conflicts.
* **Input Sanitization:** Automatically handles whitespace and formatting in port strings (e.g., `27015, 27016` vs `27015-27020`).

---

## 🛠️ Configuration

Open the `.ps1` file in any text editor and modify the top section:

| Variable | Description | Example |
| :--- | :--- | :--- |
| `$Mode` | `Update` to apply rules; `RemoveOnly` to delete them. | `"Update"` |
| `$RuleName` | The display name for the rule in Windows Firewall. | `"Minecraft Server"` |
| `$Ports` | Single port, comma-separated list, or range. | `"25565, 25570"` |
| `$Protocols` | The protocols to enable. | `@("TCP", "UDP")` |
| `$DebugMode` | Enable for detailed console logs and error traces. | `$true` |

---

## 📖 How to Use

1.  **Download/Copy** the script into your server directory.
2.  **Configure** your desired ports and server name in the `$RuleName` and `$Ports` variables.
3.  **Execute** the script:
    * **Right-click** and select `Run with PowerShell`.
    * *Note: The script will automatically prompt for Administrator access.*
4.  **Verify:** Once the summary box displays **"STATUS: SUCCESS"**, your ports are active.

---

## 💻 Integration for Developers

If you are integrating this script into a management tool (like **Ronin Server Manager**), you can execute it via the CLI:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "FirewallScript.ps1"
```
---

### Log Levels
The script outputs standardized logs that can be parsed by external applications:
* `[INFO]` - General progress updates.
* `[WARNING]` - Cleanup actions or elevation requests.
* `[ERROR]` - Critical failures (invalid ports, access denied).
* `[DEBUG]` - Raw technical data (visible only when `$DebugMode = $true`).

---

## ⚠️ Requirements
* **OS:** Windows 10 / 11 or Windows Server 2016+
* **Environment:** PowerShell 5.1 or PowerShell Core (pwsh)
* **Permissions:** Local Administrator rights are required to modify the Windows Filtering Platform.

---

> **Note:** This tool was developed for use with the RSM Project and community game server hosting. Use responsibly and only open ports that are strictly necessary for your application.
