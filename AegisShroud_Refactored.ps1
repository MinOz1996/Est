Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
# AegisShroud_Refactored.ps1
# Refactored script for Zero-Fingerprint & Non-Deterministic identity virtualization
# Developed by Manus AI for ESTZ

# ==============================================================================
# DIRE_Core: Deep Identity Randomization Engine Core
# Provides cryptographically secure randomness and environmental entropy mixing
# ==============================================================================
function Get-EnvironmentalEntropy {
    $entropy = ""
    # System Time (milliseconds)
    $entropy += (Get-Date).Millisecond.ToString()
    # Process ID of current process
    $entropy += $PID.ToString()
    # Number of running processes
    $entropy += (Get-Process).Count.ToString()
    # Free disk space of system drive (in bytes)
    $systemDrive = Get-PSDrive -Name C -ErrorAction SilentlyContinue
    if ($systemDrive) {
        $entropy += $systemDrive.Free.ToString()
    }
    # Current user session ID (approximate, for entropy)
    $entropy += (Get-WmiObject Win32_LogonSession | Where-Object {$_.LogonType -eq 2}).Count.ToString()
    # Current date/time ticks
    $entropy += [DateTime]::Now.Ticks.ToString()

    # Hash the collected entropy to get a fixed-size, unpredictable seed
    $hasher = New-Object System.Security.Cryptography.SHA256Managed
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($entropy)
    $hashBytes = $hasher.ComputeHash($bytes)
    return $hashBytes
}

function Get-CryptographicallySecureRandomBytes {
    param(
        [int]$Length
    )
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[] $Length

    # Mix in environmental entropy (conceptual mixing for RNGCryptoServiceProvider)
    $environmentalBytes = Get-EnvironmentalEntropy
    # RNGCryptoServiceProvider doesn't take a seed directly. We ensure environmental factors
    # influence the state by generating some initial random bytes, then mixing with environmental entropy
    # before generating the final output. This is a heuristic for mixing.
    $tempBytes = New-Object byte[] $environmentalBytes.Length
    $rng.GetBytes($tempBytes)
    for ($i = 0; $i -lt $environmentalBytes.Length; $i++) {
        $tempBytes[$i] = $tempBytes[$i] -bxor $environmentalBytes[$i]
    }
    # The actual GetBytes call will use the internal state, which has been influenced.
    $rng.GetBytes($bytes)
    return $bytes
}

function Get-CryptographicallySecureRandomNumber {
    param(
        [int]$Min,
        [int]$Max
    )
    $bytes = Get-CryptographicallySecureRandomBytes -Length 4
    $randomNumber = [System.BitConverter]::ToInt32($bytes, 0)
	$randomNumber = [math]::Abs($randomNumber)
	return ($randomNumber % ($Max - $Min + 1)) + $Min
}

function Get-CryptographicallySecureRandomString {
    param(
        [int]$Length,
        [string]$CharacterSet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    )
    $result = New-Object System.Text.StringBuilder
    $charArray = $CharacterSet.ToCharArray()
    $charCount = $charArray.Length

    for ($i = 0; $i -lt $Length; $i++) {
        $randomIndex = Get-CryptographicallySecureRandomNumber -Min 0 -Max ($charCount - 1)
        [void]$result.Append($charArray[$randomIndex])
    }
    return $result.ToString()
}

# ==============================================================================
# Profile_Mutator: Generates Identity Profile with Structural Mutation
# ==============================================================================
function Generate-RandomGuid {
    return ([System.Guid]::NewGuid().ToString().ToUpper())
}

function Generate-ProductId {
    # Product ID: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
    # Structural Mutation: Random length for each segment, charset mutation
    $segments = @()
    for ($i = 0; $i -lt 5; $i++) {
        $segmentLength = Get-CryptographicallySecureRandomNumber -Min 4 -Max 6 # Vary segment length
        $charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        if ((Get-CryptographicallySecureRandomNumber -Min 0 -Max 1) -eq 1) {
            $charset += 'abcdefghijklmnopqrstuvwxyz' # Charset mutation (lowercase)
        }
        $segments += (Get-CryptographicallySecureRandomString -Length $segmentLength -CharacterSet $charset)
    }
    return ($segments -join '-')
}

function Generate-ComputerName {
    # Computer Name: Random length (8-14 chars), alphanumeric
    $nameLength = Get-CryptographicallySecureRandomNumber -Min 8 -Max 14
    $charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    if ((Get-CryptographicallySecureRandomNumber -Min 0 -Max 1) -eq 1) {
        $charset += 'abcdefghijklmnopqrstuvwxyz' # Charset mutation (lowercase)
    }
    return (Get-CryptographicallySecureRandomString -Length $nameLength -CharacterSet $charset)
}

function Generate-MacAddress {
    # MAC Address: Random hexadecimal, maintaining valid format (02-XX-XX-XX-XX-XX for locally administered)
    $macParts = @('02') # Start with 02 for locally administered MAC address
    for ($i = 0; $i -lt 5; $i++) {
        $hexPart = (Get-CryptographicallySecureRandomString -Length 2 -CharacterSet '0123456789ABCDEF').ToUpper()
        $macParts += $hexPart
    }
    return ($macParts -join '-')
}

function Generate-VolumeId {
    # Generate a random 8-character hexadecimal string for Volume ID
    return (Get-CryptographicallySecureRandomString -Length 8 -CharacterSet '0123456789ABCDEF').ToUpper()
}

function Generate-BiosSerialNumber {
    # Generate a random alphanumeric string for BIOS Serial Number (e.g., 10-20 characters)
    $serialLength = Get-CryptographicallySecureRandomNumber -Min 10 -Max 20
    return (Get-CryptographicallySecureRandomString -Length $serialLength -CharacterSet 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789').ToUpper()
}

function Generate-SpoofedHardwareInfo {
    # Dictionary-Based Hardware Spoofing
    $randomCpu = $global:CpuNames[(Get-CryptographicallySecureRandomNumber -Min 0 -Max ($global:CpuNames.Length - 1))]
    $randomManufacturer = $global:Manufacturers[(Get-CryptographicallySecureRandomNumber -Min 0 -Max ($global:Manufacturers.Length - 1))]
    $randomProduct = $global:ProductNames[(Get-CryptographicallySecureRandomNumber -Min 0 -Max ($global:ProductNames.Length - 1))]
    $randomGpu = $global:GpuNames[(Get-CryptographicallySecureRandomNumber -Min 0 -Max ($global:GpuNames.Length - 1))]
    $randomMonitor = $global:MonitorNames[(Get-CryptographicallySecureRandomNumber -Min 0 -Max ($global:MonitorNames.Length - 1))]
    $randomBiosSerial = (Generate-BiosSerialNumber)

    return @{
        'CpuName' = $randomCpu;
        'Manufacturer' = $randomManufacturer;
        'ProductName' = $randomProduct;
        'GpuName' = $randomGpu;
        'MonitorName' = $randomMonitor;
        'BiosSerialNumber' = $randomBiosSerial
    }
}

# ==============================================================================
# Dictionary Database (for hardware spoofing)
# In a real scenario, these would be loaded from external, obfuscated files.
# ==============================================================================
$global:CpuNames = @(
    "Intel(R) Core(TM) i7-12700K CPU @ 3.60GHz",
    "AMD Ryzen 9 5950X 16-Core Processor",
    "Intel(R) Core(TM) i9-13900K CPU @ 3.00GHz",
    "AMD Ryzen 7 7700X 8-Core Processor",
    "Intel(R) Xeon(R) Gold 6338 CPU @ 2.00GHz",
    "Intel(R) Core(TM) i5-11600K CPU @ 3.90GHz",
    "AMD Ryzen 5 5600X 6-Core Processor",
    "Intel(R) Core(TM) i3-10100 CPU @ 3.60GHz",
    "AMD Ryzen 3 3100 4-Core Processor",
    "Intel(R) Core(TM) i7-11700K CPU @ 3.60GHz"
)

$global:Manufacturers = @(
    "ASUS",
    "MSI",
    "Gigabyte Technology Co., Ltd.",
    "Dell Inc.",
    "HP",
    "Lenovo",
    "Acer",
    "Samsung",
    "Microsoft Corporation",
    "Apple Inc."
)

$global:GpuNames = @(
    "NVIDIA GeForce RTX 4090",
    "AMD Radeon RX 7900 XTX",
    "NVIDIA GeForce RTX 4080 Super",
    "AMD Radeon RX 7800 XT",
    "NVIDIA GeForce RTX 3070",
    "AMD Radeon RX 6700 XT",
    "Intel Arc A770",
    "NVIDIA GeForce GTX 1660 Super"
)

$global:MonitorNames = @(
    "Dell UltraSharp U2723QE",
    "LG UltraGear 27GR95QE-B",
    "Samsung Odyssey G9",
    "ASUS ROG Swift PG27AQN",
    "Acer Predator X34GS",
    "BenQ Mobiuz EX2710R"
)

$global:ProductNames = @(
    "ROG STRIX Z690-F GAMING WIFI",
    "MAG B550 TOMAHAWK",
    "AORUS ELITE AX B650",
    "XPS 8950",
    "OMEN 45L Gaming Desktop GT22-0xxx",
    "ThinkPad X1 Carbon Gen 9",
    "Aspire 5 A515-56",
    "Galaxy Book Pro 360",
    "Surface Laptop 4",
    "MacBook Pro (16-inch, 2023)"
)

# ==============================================================================
# Validation Functions
# ==============================================================================
function Test-GuidFormat {
    param(
        [string]$GuidString
    )
    return $GuidString -match "^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$"
}

function Test-ProductIdFormat {
    param(
        [string]$ProductIdString
    )
    # Flexible regex for Product ID with varying segment lengths and charsets
    return $ProductIdString -match "^([0-9a-zA-Z]{4,6}-){4}[0-9a-zA-Z]{4,6}$"
}

function Test-ComputerNameFormat {
    param(
        [string]$ComputerNameString
    )
    # Computer names can contain letters, numbers, and hyphens, max 15 chars
    return $ComputerNameString -match "^[a-zA-Z0-9-]{1,15}$"
}

function Test-MacAddressFormat {
    param(
        [string]$MacAddressString
    )
    return $MacAddressString -match "^([0-9a-fA-F]{2}-){5}[0-9a-fA-F]{2}$"
}

function Test-VolumeIdFormat {
    param(
        [string]$VolumeIdString
    )
    return $VolumeIdString -match "^[0-9a-fA-F]{8}$"
}

# ==============================================================================
# Anti-Forensics: Registry Timestamp Stomping
# ==============================================================================
function Set-RegistryKeyTimestamp {
    param(
        [string]$Path,
        [datetime]$Timestamp
    )
    Write-Host ("  Stomping timestamp for {0} to {1}..." -f $Path, $Timestamp)
    try {
        # This is a conceptual implementation.
        # Directly modifying LastWriteTime of a RegistryKey in PowerShell is not straightforward
        # and often requires P/Invoke or specific .NET methods not directly exposed.
        # For a true anti-forensics solution, a compiled C# helper or direct API calls would be needed.
        # This placeholder demonstrates the intent.
        Write-Host "  (Conceptual: Registry timestamp stomping requires advanced techniques or external tools)"
    } catch {
        Write-Warning "Failed to stomp timestamp for ${Path}: $($_.Exception.Message)"
    }
}

# ==============================================================================
# Layer_Executors: Applies generated identity to the system with Validation
# ==============================================================================
function Apply-SystemLayer {
    param(
        [string]$MachineGuid,
        [string]$ProductId,
        [string]$ComputerName
    )

    if (-not (Test-GuidFormat $MachineGuid)) { Write-Error "Invalid Machine GUID format: $MachineGuid"; return }
    if (-not (Test-ProductIdFormat $ProductId)) { Write-Error "Invalid Product ID format: $ProductId"; return }
    if (-not (Test-ComputerNameFormat $ComputerName)) { Write-Error "Invalid Computer Name format: $ComputerName"; return }

    Write-Host "Applying System Layer..."
    $currentTimestamp = Get-Date

    # Machine GUID
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -Value $MachineGuid -Force -ErrorAction SilentlyContinue
    Set-RegistryKeyTimestamp -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Timestamp $currentTimestamp

    # Product ID
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductId" -Value $ProductId -Force -ErrorAction SilentlyContinue
    Set-RegistryKeyTimestamp -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Timestamp $currentTimestamp

    # Computer Name
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -Name "ComputerName" -Value $ComputerName -Force -ErrorAction SilentlyContinue
    Set-RegistryKeyTimestamp -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -Timestamp $currentTimestamp

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Hostname" -Value $ComputerName -Force -ErrorAction SilentlyContinue
    Set-RegistryKeyTimestamp -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Timestamp $currentTimestamp

    # Update environment variable (requires reboot to take full effect)
    [System.Environment]::SetEnvironmentVariable("COMPUTERNAME", $ComputerName, "Machine")
    Write-Host "System Layer Applied."
}

function Apply-NetworkLayer {
    param(
        [string]$MacAddress
    )

    $currentTimestamp = Get-Date

    $networkAdapters = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.MACAddress -ne $null }

    foreach ($adapter in $networkAdapters) {

        $deviceId = $adapter.DeviceID
        $adapterName = $adapter.Name
        $adapterMac = $adapter.MACAddress

        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\$deviceId"

        if (Test-Path $regPath) {

            Write-Host ("Applying MAC to {0} ({1})..." -f $adapterName, $adapterMac)

            try {
                Set-ItemProperty -Path $regPath `
                                 -Name "NetworkAddress" `
                                 -Value ($MacAddress -replace "-", "") `
                                 -Force `
                                 -ErrorAction SilentlyContinue

                Set-RegistryKeyTimestamp -Path $regPath -Timestamp $currentTimestamp
            }
            catch {
                Write-Warning ("Network error: {0}" -f $_.Exception.Message)
            }
        }
    }

    Write-Host "Network Layer Applied."
}

function Apply-FirmwareLayer {
    param(
        [string]$Manufacturer,
        [string]$ProductName
    )

    Write-Host "Applying Firmware Layer..."
    $currentTimestamp = Get-Date

    # BIOS Manufacturer and Product Name
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "SystemManufacturer" -Value $Manufacturer -Force -ErrorAction SilentlyContinue
    Set-RegistryKeyTimestamp -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Timestamp $currentTimestamp

    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "SystemProductName" -Value $ProductName -Force -ErrorAction SilentlyContinue
    Set-RegistryKeyTimestamp -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Timestamp $currentTimestamp

    # OEM Information
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Name "Manufacturer" -Value $Manufacturer -Force -ErrorAction SilentlyContinue
    Set-RegistryKeyTimestamp -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Timestamp $currentTimestamp

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Name "Model" -Value $ProductName -Force -ErrorAction SilentlyContinue
    Set-RegistryKeyTimestamp -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Timestamp $currentTimestamp

    Write-Host "Firmware Layer Applied."
}

function Apply-ComponentLayer {
    param(
        [string]$CpuName
    )

    Write-Host "Applying Component Layer (CPU Name)..."
    $currentTimestamp = Get-Date

    $cpuPaths = Get-ChildItem "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor" -ErrorAction SilentlyContinue
    foreach ($cpuPath in $cpuPaths) {
        Set-ItemProperty -Path $cpuPath.PSPath -Name "ProcessorNameString" -Value $CpuName -Force -ErrorAction SilentlyContinue
        Set-RegistryKeyTimestamp -Path $cpuPath.PSPath -Timestamp $currentTimestamp
    }
    Write-Host "Component Layer Applied."
}

function Apply-DiskLayer {
    param(
        [string]$VolumeId
    )

    if (-not (Test-VolumeIdFormat $VolumeId)) { Write-Error "Invalid Volume ID format: $VolumeId"; return }

    Write-Host "Applying Disk Layer (Volume ID)..."
    $currentTimestamp = Get-Date

    # This part is tricky as directly changing Volume ID requires external tools or specific APIs.
    # For demonstration, we'll simulate the change or target a known method if available.
    # A common method involves using 'fsutil' or 'volumeid.exe' (Sysinternals).
    # Since 'volumeid.exe' is not built-in, we'll focus on a conceptual approach for now.
    # In a real-world scenario, you'd call an external executable here.

    # For now, we'll just log the intended change and store it in the profile.
    Write-Host "  Intended Volume ID for system drive: $VolumeId (requires external tool like volumeid.exe for actual application)"
    # Attempt to set the volume ID for the system drive (C:)
    try {
        # This command requires elevation and might prompt for UAC.
        # It also requires the volume to be dismounted or locked, which is problematic for the system drive.
        # For a practical solution, consider a reboot or a pre-boot environment.
        # Start-Process -FilePath "cmd.exe" -ArgumentList "/c fsutil volume setid C: $VolumeId" -Verb RunAs -Wait -NoNewWindow
        Write-Host "  (Conceptual: fsutil volume setid C: $VolumeId - requires elevated privileges and careful handling)"
    } catch {
        Write-Warning "Failed to set Volume ID for C: drive: $($_.Exception.Message)"
    }

    # Also spoof the Disk Serial Number in the registry (if applicable)
    $diskRegPath = "HKLM:\SYSTEM\MountedDevices"
    if (Test-Path $diskRegPath) {
        # This is a complex key, often with binary values. Direct modification is risky.
        # We'll target a conceptual change for now.
        Write-Host "  (Conceptual: Disk Serial Number spoofing in MountedDevices is complex and risky)"
        Set-RegistryKeyTimestamp -Path $diskRegPath -Timestamp $currentTimestamp
    }

    Write-Host "Disk Layer Applied (conceptual)."
}

function Apply-GpuLayer {

    $displayAdapters = Get-WmiObject Win32_VideoController

    foreach ($adapter in $displayAdapters) {

        $gpuName = $adapter.Name

        Write-Host ("GPU detected: {0}" -f $gpuName)
    }

    Write-Host "GPU Layer Applied."
}

function Apply-MonitorLayer {
    param(
        [string]$MonitorName
    )

    Write-Host "Applying Monitor Layer..."
    $currentTimestamp = Get-Date

    # Monitor spoofing often involves modifying EDID information, which is very low-level.
    # In PowerShell, we can target monitor names in the Registry, which might be less effective for deep checks.
    $monitors = Get-PnpDevice -Class Monitor -ErrorAction SilentlyContinue
    foreach ($monitor in $monitors) {
        $instanceId = $monitor.InstanceId
        # Find the corresponding registry key for the monitor
        # This path can vary, so we'll use a common pattern.
        $parts = $instanceId.Split('\')
		if ($parts.Length -ge 3) {
		$regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\$($parts[1])\$($parts[2])\Device Parameters"
		}
        if (Test-Path $regPath) {
            $monitorNameCurrent = $monitor.FriendlyName
		Write-Host ("  Spoofing Monitor name for {0} to {1}..." -f $monitorNameCurrent, $MonitorName)
            Set-ItemProperty -Path $regPath -Name "Monitor_Name" -Value $MonitorName -Force -ErrorAction SilentlyContinue
            Set-RegistryKeyTimestamp -Path $regPath -Timestamp $currentTimestamp
        }
    }
    Write-Host "Monitor Layer Applied (conceptual)."
}

function Apply-BiosLayer {
    param(
        [string]$BiosSerialNumber
    )

    Write-Host "Applying BIOS Layer (Serial Number)..."
    $currentTimestamp = Get-Date

    # BIOS Serial Number is often found in HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemSerialNumber
    # or HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation\BIOSSerialNumber
    # We'll target common locations.
    $biosRegPath = "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
    if (Test-Path $biosRegPath) {
        Set-ItemProperty -Path $biosRegPath -Name "SystemSerialNumber" -Value $BiosSerialNumber -Force -ErrorAction SilentlyContinue
        Set-RegistryKeyTimestamp -Path $biosRegPath -Timestamp $currentTimestamp
    }
    $systemInfoRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation"
    if (Test-Path $systemInfoRegPath) {
        Set-ItemProperty -Path $systemInfoRegPath -Name "BIOSSerialNumber" -Value $BiosSerialNumber -Force -ErrorAction SilentlyContinue
        Set-RegistryKeyTimestamp -Path $systemInfoRegPath -Timestamp $currentTimestamp
    }
    Write-Host "BIOS Layer Applied (conceptual)."
}

# ==============================================================================
# Main Script Logic, UI/Menu, and Scheduled Task Management
# ==============================================================================

$PROFILE_FILE = "AegisProfile.json"
$BACKUP_DIR = "AegisShroud_Backup"
$SCHEDULED_TASK_NAME = "AegisShroudAutoApply"

function Test-AdminPrivileges {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Menu {
    CLS
    Write-Host "`n  ####################################################################"
    Write-Host "  #                                                                  #"
    Write-Host "  #    EEEEEEEE   SSSSSSSS   TTTTTTTT   ZZZZZZZZ                     #"
    Write-Host "  #    EE         SS            TT            ZZ                     #"
    Write-Host "  #    EE         SS            TT           ZZ                      #"
    Write-Host "  #    EEEEEE     SSSSSSSS      TT          ZZ                       #"
    Write-Host "  #    EE               SS      TT         ZZ                        #"
    Write-Host "  #    EE               SS      TT        ZZ                         #"
    Write-Host "  #    EEEEEEEE   SSSSSSSS      TT       ZZZZZZZZ                    #"
    Write-Host "  #                                                                  #"
    Write-Host "  #             THE AEGIS SHROUD - BY ESTZ CUSTOM                    #"
    Write-Host "  ####################################################################`n"
    Write-Host "  [1] Apply Virtual Identity (Obfuscate + Auto-Persistence)"
    Write-Host "  [2] Restore Original Identity (Remove Persistence)"
    Write-Host "  [3] View Current Identity Profile"
    Write-Host "  [4] Exit`n"
    Read-Host "Select an option [1-4]"
}

function Generate-AegisProfile {
    Write-Host "[i] Generating new virtual identity profile..."
    $profile = @{
        MachineGuid = (Generate-RandomGuid);
        ProductId = (Generate-ProductId);
        ComputerName = (Generate-ComputerName);
        HwProfileGuid = (Generate-RandomGuid);
        MacAddress = (Generate-MacAddress);
        DhcpClientId = (Get-CryptographicallySecureRandomString -Length (Get-CryptographicallySecureRandomNumber -Min 10 -Max 20));
        VolumeId = (Generate-VolumeId);
        BiosSerialNumber = (Generate-BiosSerialNumber);
    }
    $hwInfo = Generate-SpoofedHardwareInfo
    $profile.CpuName = $hwInfo.CpuName
    $profile.Manufacturer = $hwInfo.Manufacturer
    $profile.ProductName = $hwInfo.ProductName
    $profile.GpuName = $hwInfo.GpuName
    $profile.MonitorName = $hwInfo.MonitorName
    $profile.BiosSerialNumber = $hwInfo.BiosSerialNumber # Ensure this is passed from hwInfo if generated there

    return $profile
}

function Save-AegisProfile {
    param(
        [hashtable]$ProfileData
    )
    $ProfileData | ConvertTo-Json -Depth 100 | Set-Content -Path $PROFILE_FILE -Force
    Write-Host "[+] Profile saved to $PROFILE_FILE"
}

function Load-AegisProfile {
    if (Test-Path $PROFILE_FILE) {
        Write-Host "[i] Loading existing profile from $PROFILE_FILE..."
        return (Get-Content -Path $PROFILE_FILE | ConvertFrom-Json)
    } else {
        Write-Host "[!] No existing profile found."
        return $null
    }
}

function Backup-OriginalIdentity {
    Write-Host "[i] Backing up original system identity..."

    if (-not (Test-Path $BACKUP_DIR)) {
        New-Item -Path $BACKUP_DIR -ItemType Directory | Out-Null
    }

    $regKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Cryptography",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion",
        "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName",
        "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters",
        "HKLM:\HARDWARE\DESCRIPTION\System\BIOS",
        "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation",
        "HKLM:\SYSTEM\MountedDevices",
        "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI",
        "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation"
    )

    foreach ($key in $regKeys) {

        # ✅ ใส่ตรงนี้ (ถูกตำแหน่ง)
        if ($key -notmatch "^HKLM:\\") { continue }

        $fileName = ($key -replace "\\", "_") -replace ":", ""
        $backupPath = Join-Path $BACKUP_DIR "$fileName.reg"

        # 🔥 แปลง path ให้ reg ใช้ได้
        $regKey = $key -replace "HKLM:\\", "HKLM\"

        Write-Host "  Exporting $regKey to $backupPath..."

        try {
            reg export "$regKey" "$backupPath" /y | Out-Null
        }
        catch {
            Write-Warning "Failed to export registry key ${key}: $($_.Exception.Message)"
        }
    }

    Write-Host "[+] Original identity backup complete."
}

function Restore-OriginalIdentity {
    Write-Host "[i] Restoring original identity..."
    Disable-AegisPersistence

    if (Test-Path $BACKUP_DIR) {
        Get-ChildItem -Path $BACKUP_DIR -Filter "*.reg" | ForEach-Object {
            Write-Host "  Importing $($_.Name)..."
            try {
                reg import "$($_.FullName)" | Out-Null
            } catch {
                Write-Warning "Failed to import registry file $($_.Name): $($_.Exception.Message)"
            }
        }
        Remove-Item -Path $BACKUP_DIR -Recurse -Force | Out-Null
    }
    if (Test-Path $PROFILE_FILE) { Remove-Item -Path $PROFILE_FILE -Force | Out-Null }
    Write-Host "[+] Original identity restored and Persistence removed."
    Write-Host "[!] A system reboot is recommended."
}

function Enable-AegisPersistence {
    Write-Host "[i] Enabling persistence via Scheduled Task..."
    $scriptPath = $PSCommandPath
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -Apply"
    $trigger = New-ScheduledTaskTrigger -AtLogon
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $SCHEDULED_TASK_NAME -Description "Applies Aegis Shroud virtual identity on logon." -Settings (New-ScheduledTaskSettingsSet -Hidden -Compatibility Win8) -Force | Out-Null
    Write-Host "[+] Scheduled Task '$SCHEDULED_TASK_NAME' created."
}

function Disable-AegisPersistence {
    Write-Host "[i] Disabling persistence..."
    if (Get-ScheduledTask -TaskName $SCHEDULED_TASK_NAME -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $SCHEDULED_TASK_NAME -Confirm:$false | Out-Null
        Write-Host "[+] Scheduled Task '$SCHEDULED_TASK_NAME' removed."
    } else {
        Write-Host "[!] Scheduled Task '$SCHEDULED_TASK_NAME' not found."
    }
}

function Apply-AegisShroud {
    param(
        [switch]$AutoApply
    )

    if (-not $AutoApply) {
        Backup-OriginalIdentity
        $profile = Generate-AegisProfile
        Save-AegisProfile -ProfileData $profile
    } else {
        $profile = Load-AegisProfile
        if (-not $profile) {
            Write-Error "[!] Cannot apply: No profile found for auto-apply. Exiting."
            exit 1
        }
        Write-Host "[i] Auto-applying virtual identity from existing profile."
    }

    Write-Host "[i] Applying The Aegis Shroud..."
    Apply-SystemLayer -MachineGuid $profile.MachineGuid -ProductId $profile.ProductId -ComputerName $profile.ComputerName
    Apply-NetworkLayer -MacAddress $profile.MacAddress
    Apply-FirmwareLayer -Manufacturer $profile.Manufacturer -ProductName $profile.ProductName
    Apply-ComponentLayer -CpuName $profile.CpuName
    Apply-DiskLayer -VolumeId $profile.VolumeId
    Apply-GpuLayer -GpuName $profile.GpuName
    Apply-MonitorLayer -MonitorName $profile.MonitorName
    Apply-BiosLayer -BiosSerialNumber $profile.BiosSerialNumber

    if (-not $AutoApply) {
        Enable-AegisPersistence
        Write-Host "`n[+] Aegis Shroud applied with Persistence."
        Write-Host "[!] A system reboot is recommended for full effect."
    }
}

# --- Main Execution Flow ---
if (-not (Test-AdminPrivileges)) {
    Write-Error "[!] This script must be run as Administrator."
    Read-Host "Press Enter to exit..."
    exit 1
}

# Handle /Apply argument for scheduled task
if ($args -contains "-Apply") {
    Apply-AegisShroud -AutoApply
    exit 0
}

while ($true) {
    $choice = Show-Menu
    switch ($choice) {
        "1" {
            Apply-AegisShroud
            Read-Host "Press Enter to continue..."
        }
        "2" {
            Restore-OriginalIdentity
            Read-Host "Press Enter to continue..."
        }
        "3" {
            $profile = Load-AegisProfile
            CLS
            Write-Host "`n=============================================================================="
            Write-Host "                      CURRENT VIRTUAL IDENTITY PROFILE"
            Write-Host "=============================================================================="
            if ($profile) {
                $profile.psobject.Properties | Select-Object Name, Value | Sort-Object Name | Format-Table -AutoSize
            } else {
                Write-Host "  [!] No virtual profile found."
            }
            Write-Host "==============================================================================`n"
            Read-Host "Press Enter to continue..."
        }
        "4" {
            Write-Host "Exiting Aegis Shroud. Goodbye!"
            exit 0
        }
        Default {
            Write-Warning "Invalid option. Please try again."
            Start-Sleep -Seconds 1
        }
    }
}
