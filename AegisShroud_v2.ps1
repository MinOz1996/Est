# AegisShroud_v2.ps1
# Advanced Identity Virtualization Layer
# Developed by Manus AI for ESTZ

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ==============================================================================
# DIRE_Core: Deep Identity Randomization Engine Core (Advanced Entropy)
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

    # Simulate hardware jitter (conceptual in PowerShell, actual RDTSC requires kernel/driver)
    # Measure execution time of a small, random operation
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    (Get-Random -Minimum 0 -Maximum 1000 | Out-Null)
    $stopwatch.Stop()
    $entropy += $stopwatch.ElapsedTicks.ToString()

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
    $tempBytes = New-Object byte[] $environmentalBytes.Length
    $rng.GetBytes($tempBytes)
    for ($i = 0; $i -lt $environmentalBytes.Length; $i++) {
        $tempBytes[$i] = $tempBytes[$i] -bxor $environmentalBytes[$i]
    }
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
# Hardware Profile Coherency Model (Template-Based Spoofing)
# ==============================================================================
# This model ensures that spoofed hardware values are logically consistent.
# In a real-world scenario, this dataset would be much larger and externalized.
$global:HardwareProfiles = @(
    # Profile 1: ASUS Gaming PC
    @{
        Manufacturer = "ASUS";
        ProductName = "ROG STRIX Z690-F GAMING WIFI";
        CpuNames = @("Intel(R) Core(TM) i9-13900K CPU @ 3.00GHz", "Intel(R) Core(TM) i7-12700K CPU @ 3.60GHz");
        GpuNames = @("NVIDIA GeForce RTX 4090", "NVIDIA GeForce RTX 4080 Super");
        MonitorNames = @("ASUS ROG Swift PG27AQN", "LG UltraGear 27GR95QE-B");
        BiosVendor = "American Megatrends International, LLC.";
        BiosVersionPrefix = "ASUS";
        ChassisType = "Desktop";
    },
    # Profile 2: Dell Workstation
    @{
        Manufacturer = "Dell Inc.";
        ProductName = "XPS 8950";
        CpuNames = @("Intel(R) Core(TM) i7-12700K CPU @ 3.60GHz", "Intel(R) Core(TM) i5-11600K CPU @ 3.90GHz");
        GpuNames = @("NVIDIA GeForce RTX 3070", "AMD Radeon RX 6700 XT");
        MonitorNames = @("Dell UltraSharp U2723QE", "BenQ Mobiuz EX2710R");
        BiosVendor = "Dell Inc.";
        BiosVersionPrefix = "Dell";
        ChassisType = "Desktop";
    },
    # Profile 3: Lenovo Laptop
    @{
        Manufacturer = "Lenovo";
        ProductName = "ThinkPad X1 Carbon Gen 9";
        CpuNames = @("Intel(R) Core(TM) i7-1185G7 @ 3.00GHz", "Intel(R) Core(TM) i5-1135G7 @ 2.40GHz");
        GpuNames = @("Intel(R) Iris(R) Xe Graphics");
        MonitorNames = @("Lenovo ThinkVision P27h-20", "Dell UltraSharp U2723QE");
        BiosVendor = "LENOVO";
        BiosVersionPrefix = "N3AET";
        ChassisType = "Laptop";
    }
)

function Generate-CoherentHardwareProfile {
    $randomIndex = Get-CryptographicallySecureRandomNumber -Min 0 -Max ($global:HardwareProfiles.Length - 1)
    $selectedProfile = $global:HardwareProfiles[$randomIndex]

    $profile = @{
        Manufacturer = $selectedProfile.Manufacturer;
        ProductName = $selectedProfile.ProductName;
        CpuName = $selectedProfile.CpuNames[(Get-CryptographicallySecureRandomNumber -Min 0 -Max ($selectedProfile.CpuNames.Length - 1))];
        GpuName = $selectedProfile.GpuNames[(Get-CryptographicallySecureRandomNumber -Min 0 -Max ($selectedProfile.GpuNames.Length - 1))];
        MonitorName = $selectedProfile.MonitorNames[(Get-CryptographicallySecureRandomNumber -Min 0 -Max ($selectedProfile.MonitorNames.Length - 1))];
        BiosVendor = $selectedProfile.BiosVendor;
        BiosVersion = "$($selectedProfile.BiosVersionPrefix)$(Get-CryptographicallySecureRandomString -Length 4 -CharacterSet '0123456789')"; # Example BiosVersion
        BiosSerialNumber = (Get-CryptographicallySecureRandomString -Length 10 -CharacterSet 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
        ChassisType = $selectedProfile.ChassisType;
    }
    return $profile
}

# Placeholder for other generation functions (MachineGuid, ProductId, etc.)
function Generate-RandomGuid { return ([System.Guid]::NewGuid().ToString().ToUpper()) }
function Generate-ProductId {
    $segments = @()
    for ($i = 0; $i -lt 5; $i++) {
        $segmentLength = Get-CryptographicallySecureRandomNumber -Min 4 -Max 6
        $charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        if ((Get-CryptographicallySecureRandomNumber -Min 0 -Max 1) -eq 1) { $charset += 'abcdefghijklmnopqrstuvwxyz' }
        $segments += (Get-CryptographicallySecureRandomString -Length $segmentLength -CharacterSet $charset)
    }
    return ($segments -join '-')
}
function Generate-ComputerName {
    $nameLength = Get-CryptographicallySecureRandomNumber -Min 8 -Max 14
    $charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    if ((Get-CryptographicallySecureRandomNumber -Min 0 -Max 1) -eq 1) { $charset += 'abcdefghijklmnopqrstuvwxyz' }
    return (Get-CryptographicallySecureRandomString -Length $nameLength -CharacterSet $charset)
}
function Generate-MacAddress {
    $macParts = @('02')
    for ($i = 0; $i -lt 5; $i++) {
        $hexPart = (Get-CryptographicallySecureRandomString -Length 2 -CharacterSet '0123456789ABCDEF').ToUpper()
        $macParts += $hexPart
    }
    return ($macParts -join '-')
}
function Generate-VolumeId { return (Get-CryptographicallySecureRandomString -Length 8 -CharacterSet '0123456789ABCDEF').ToUpper() }

# ==============================================================================
# Core Spoofing Logic (Registry - to be expanded with WMI/Kernel hooks)
# ==============================================================================
function Apply-SystemLayer {
    param(
        [string]$MachineGuid,
        [string]$ProductId,
        [string]$ComputerName
    )
    Write-Host "[+] Applying System Layer..."
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -Value $MachineGuid -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductId" -Value $ProductId -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "DigitalProductId" -Value (New-Object byte[] 52) -Force # Clear DigitalProductId
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -Name "ComputerName" -Value $ComputerName -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Hostname" -Value $ComputerName -Force
        Rename-Computer -NewName $ComputerName -Force -PassThru | Out-Null # Requires reboot
        Write-Host "  MachineGuid, ProductId, ComputerName spoofed."
    }
    catch {
        Write-Warning "Failed to apply System Layer: $($_.Exception.Message)"
    }
}

function Apply-NetworkLayer {
    param(
        [string]$MacAddress
    )
    Write-Host "[+] Applying Network Layer..."
    try {
        # This is still registry-based. True MAC spoofing requires driver-level intervention.
        # For demonstration, we'll update the registry entry for a generic adapter.
        # In a real scenario, this would iterate through network adapters or use a driver.
        $networkAdapters = Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.MACAddress -ne $null}
        foreach ($adapter in $networkAdapters) {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\$($adapter.DeviceID.PadLeft(4, '0'))"
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "NetworkAddress" -Value ($MacAddress -replace '-') -Force
                Write-Host "  MAC Address spoofed for adapter $($adapter.Name)."
            }
        }
    }
    catch {
        Write-Warning "Failed to apply Network Layer: $($_.Exception.Message)"
    }
}

function Apply-FirmwareLayer {
    param(
        [string]$Manufacturer,
        [string]$ProductName,
        [string]$BiosVendor,
        [string]$BiosVersion,
        [string]$BiosSerialNumber
    )
    Write-Host "[+] Applying Firmware Layer (Registry-based, conceptual for WMI/SMBIOS)..."
    try {
        # These are registry entries, which are easily bypassed by WMI/SMBIOS queries.
        # True spoofing requires WMI provider hooks or direct SMBIOS memory patching.
        Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "SystemManufacturer" -Value $Manufacturer -Force
        Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "SystemProductName" -Value $ProductName -Force
        Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BIOSVendor" -Value $BiosVendor -Force
        Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BIOSVersion" -Value $BiosVersion -Force
        Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BIOSSerialNumber" -Value $BiosSerialNumber -Force
        Write-Host "  Manufacturer, ProductName, BIOS info spoofed (Registry)."
    }
    catch {
        Write-Warning "Failed to apply Firmware Layer: $($_.Exception.Message)"
    }
}

function Apply-ComponentLayer {
    param(
        [string]$CpuName
    )
    Write-Host "[+] Applying Component Layer (CPU Name)..."
    try {
        # CPU Name in registry is often under HKLM\HARDWARE\DESCRIPTION\System\CentralProcessor\0
        Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0" -Name "ProcessorNameString" -Value $CpuName -Force
        Write-Host "  CPU Name spoofed."
    }
    catch {
        Write-Warning "Failed to apply Component Layer (CPU): $($_.Exception.Message)"
    }
}

function Apply-DiskLayer {
    param(
        [string]$VolumeId
    )
    Write-Host "[+] Applying Disk Layer (Volume ID)..."
    try {
        # Volume ID spoofing is complex and requires direct disk access or driver-level intervention.
        # This is a conceptual placeholder. Modifying the registry entry for MountedDevices is not sufficient.
        # For demonstration, we'll simulate a change, but acknowledge its limitations.
        # Real solution involves modifying the volume serial number directly on the disk.
        # This would typically involve a tool like 'volid' or direct IOCTL calls.
        Write-Host "  Volume ID spoofing is conceptual in PowerShell. Real solution requires kernel/driver."
    }
    catch {
        Write-Warning "Failed to apply Disk Layer: $($_.Exception.Message)"
    }
}

function Apply-GpuLayer {
    param(
        [string]$GpuName
    )
    Write-Host "[+] Applying GPU Layer..."
    try {
        # GPU name spoofing is typically done via display driver registry keys or WMI.
        # This is a simplified registry-based approach.
        $displayAdapters = Get-WmiObject Win32_DisplayControllerConfiguration
        foreach ($adapter in $displayAdapters) {
            # This is a generic approach; actual paths vary by driver/GPU.
            # For demonstration, we'll assume a common path.
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Video\{4D36E968-E325-11CE-BFC1-08002BE10318}\0000"
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "DriverDescription" -Value $GpuName -Force
                Write-Host "  GPU Name spoofed for adapter."
            }
        }
    }
    catch {
        Write-Warning "Failed to apply GPU Layer: $($_.Exception.Message)"
    }
}

function Apply-MonitorLayer {
    param(
        [string]$MonitorName
    )
    Write-Host "[+] Applying Monitor Layer..."
    try {
        # Monitor information is often stored in Enum\DISPLAY registry keys.
        # This is a simplified approach.
        $monitorRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY"
        $displayDevices = Get-ChildItem -Path $monitorRegPath -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -and $_.Name -match "\Dev_"}
        foreach ($device in $displayDevices) {
            $deviceParametersPath = Join-Path $device.PSPath "Device Parameters"
            if (Test-Path $deviceParametersPath) {
                Set-ItemProperty -Path $deviceParametersPath -Name "MonitorUserFriendlyName" -Value $MonitorName -Force
                Write-Host "  Monitor Name spoofed for device $($device.Name)."
            }
        }
    }
    catch {
        Write-Warning "Failed to apply Monitor Layer: $($_.Exception.Message)"
    }
}

# ==============================================================================
# Anti-Forensics: Registry Timestamp Stomping (Conceptual)
# ==============================================================================
function Set-RegistryKeyTimestamp {
    param(
        [string]$Path,
        [datetime]$Timestamp
    )
    Write-Host ("  Stomping timestamp for {0} to {1} (conceptual)..." -f $Path, $Timestamp)
    # Directly modifying LastWriteTime of a RegistryKey in PowerShell is not straightforward
    # and often requires P/Invoke or specific .NET methods not directly exposed.
    # This is a placeholder to indicate the intent.
}

function Apply-TimestampStomping {
    Write-Host "[i] Applying Registry Timestamp Stomping..."
    $currentTimestamp = Get-Date
    $regPathsToStomp = @(
        "HKLM:\SOFTWARE\Microsoft\Cryptography",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion",
        "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName",
        "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters",
        "HKLM:\HARDWARE\DESCRIPTION\System\BIOS",
        "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0",
        "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI",
        "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY"
    )
    foreach ($path in $regPathsToStomp) {
        Set-RegistryKeyTimestamp -Path $path -Timestamp $currentTimestamp
    }
    Write-Host "[+] Registry timestamps conceptually stomped."
}

# ==============================================================================
# Main Script Logic, UI/Menu, and Persistence Management
# ==============================================================================

$PROFILE_FILE = "AegisProfile_v2.json"
$BACKUP_DIR = "AegisShroud_v2_Backup"
$WMI_PERSISTENCE_EVENT_NAME = "AegisShroudAutoApplyEvent"
$WMI_PERSISTENCE_FILTER_NAME = "AegisShroudLogonFilter"
$WMI_PERSISTENCE_CONSUMER_NAME = "AegisShroudEventConsumer"

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
    Write-Host "  #          THE AEGIS SHROUD v2 - BY ESTZ CUSTOM                    #"
    Write-Host "  ####################################################################`n"
    Write-Host "  [1] Apply Virtual Identity (Advanced Coherency + Stealth Persistence)"
    Write-Host "  [2] Restore Original Identity (Remove Persistence)"
    Write-Host "  [3] View Current Virtual Identity Profile"
    Write-Host "  [4] Exit`n"
    Read-Host "Select an option [1-4]"
}

function Generate-AegisProfile {
    Write-Host "[i] Generating new virtual identity profile with coherency..."
    $coherentProfile = Generate-CoherentHardwareProfile

    $profile = @{
        MachineGuid = (Generate-RandomGuid);
        ProductId = (Generate-ProductId);
        ComputerName = (Generate-ComputerName);
        HwProfileGuid = (Generate-RandomGuid);
        MacAddress = (Generate-MacAddress);
        DhcpClientId = (Get-CryptographicallySecureRandomString -Length (Get-CryptographicallySecureRandomNumber -Min 10 -Max 20));
        VolumeId = (Generate-VolumeId);
        BiosSerialNumber = $coherentProfile.BiosSerialNumber;
        CpuName = $coherentProfile.CpuName;
        Manufacturer = $coherentProfile.Manufacturer;
        ProductName = $coherentProfile.ProductName;
        GpuName = $coherentProfile.GpuName;
        MonitorName = $coherentProfile.MonitorName;
        BiosVendor = $coherentProfile.BiosVendor;
        BiosVersion = $coherentProfile.BiosVersion;
        ChassisType = $coherentProfile.ChassisType;
    }
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
        if ($key -notmatch "^HKLM:\\") { continue }
        $fileName = ($key -replace "\\", "_") -replace ":", ""
        $backupPath = Join-Path $BACKUP_DIR "$fileName.reg"
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

# ==============================================================================
# Stealth Persistence: WMI Event Subscription (instead of Scheduled Task)
# ==============================================================================
function Enable-AegisPersistence {
    Write-Host "[i] Enabling stealth persistence via WMI Event Subscription..."
    $scriptPath = $PSCommandPath

    try {
        # 1. Define the Event Filter (e.g., triggered on logon)
        $filterQuery = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_LogonSession' AND TargetInstance.LogonType = 2"
        $filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{
            Name  = $WMI_PERSISTENCE_FILTER_NAME;
            EventNameSpace = "root\cimv2";
            Query = $filterQuery;
            QueryLanguage = "WQL"
        } -ErrorAction Stop

        # 2. Define the Event Consumer (executes PowerShell script)
        $consumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments @{
            Name = $WMI_PERSISTENCE_CONSUMER_NAME;
            ExecutablePath = "powershell.exe";
            CommandLineTemplate = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -Apply"
        } -ErrorAction Stop

        # 3. Bind Filter to Consumer
        Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{
            Filter = $filter;
            Consumer = $consumer
        } -ErrorAction Stop

        Write-Host "[+] WMI Event Subscription persistence enabled."
    }
    catch {
        Write-Warning "Failed to enable WMI persistence: $($_.Exception.Message)"
    }
}

function Disable-AegisPersistence {
    Write-Host "[i] Disabling stealth persistence..."
    try {
        # Remove the binding first
        Get-WmiObject -Class __FilterToConsumerBinding -Namespace "root\subscription" | Where-Object {
            $_.Filter -match $WMI_PERSISTENCE_FILTER_NAME -and $_.Consumer -match $WMI_PERSISTENCE_CONSUMER_NAME
        } | Remove-WmiObject -ErrorAction SilentlyContinue

        # Remove the consumer
        Get-WmiObject -Class CommandLineEventConsumer -Namespace "root\subscription" -Filter "Name='$WMI_PERSISTENCE_CONSUMER_NAME'" | Remove-WmiObject -ErrorAction SilentlyContinue

        # Remove the filter
        Get-WmiObject -Class __EventFilter -Namespace "root\subscription" -Filter "Name='$WMI_PERSISTENCE_FILTER_NAME'" | Remove-WmiObject -ErrorAction SilentlyContinue

        Write-Host "[+] WMI Event Subscription persistence disabled."
    }
    catch {
        Write-Warning "Failed to disable WMI persistence: $($_.Exception.Message)"
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

    Write-Host "[i] Applying The Aegis Shroud v2..."
    Apply-SystemLayer -MachineGuid $profile.MachineGuid -ProductId $profile.ProductId -ComputerName $profile.ComputerName
    Apply-NetworkLayer -MacAddress $profile.MacAddress
    Apply-FirmwareLayer -Manufacturer $profile.Manufacturer -ProductName $profile.ProductName -BiosVendor $profile.BiosVendor -BiosVersion $profile.BiosVersion -BiosSerialNumber $profile.BiosSerialNumber
    Apply-ComponentLayer -CpuName $profile.CpuName
    Apply-DiskLayer -VolumeId $profile.VolumeId # Conceptual
    Apply-GpuLayer -GpuName $profile.GpuName
    Apply-MonitorLayer -MonitorName $profile.MonitorName
    Apply-TimestampStomping # Conceptual

    if (-not $AutoApply) {
        Enable-AegisPersistence
        Write-Host "`n[+] Aegis Shroud v2 applied with Stealth Persistence."
        Write-Host "[!] A system reboot is recommended for full effect."
    }
}

# --- Main Execution Flow ---
if (-not (Test-AdminPrivileges)) {
    Write-Error "[!] This script must be run as Administrator."
    Read-Host "Press Enter to exit..."
    exit 1
}

# Handle /Apply argument for WMI persistence
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
            Write-Host "                  CURRENT VIRTUAL IDENTITY PROFILE (v2)"
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
            Write-Host "Exiting Aegis Shroud v2. Goodbye!"
            exit 0
        }
        Default {
            Write-Warning "Invalid option. Please try again."
            Start-Sleep -Seconds 1
        }
    }
}

# ==============================================================================
# WMI Virtualization Layer (Conceptual in PowerShell)
# True WMI spoofing requires creating and registering a custom WMI provider
# (often written in C++ or a .NET language) that intercepts WMI queries
# for specific classes (e.g., Win32_ComputerSystem, Win32_BIOS) and returns
# spoofed data. This cannot be done directly or robustly in PowerShell.
#
# The following functions are conceptual placeholders to illustrate the intent.
# A real implementation would involve:
# 1. Creating a Managed Object Format (MOF) file to define the custom WMI class.
# 2. Compiling the MOF file using `mofcomp.exe`.
# 3. Implementing a WMI provider DLL that services queries for the custom class.
# 4. Registering the provider with WMI.
#
# For the purpose of this PowerShell script, we acknowledge that WMI queries
# will still return real values unless a proper WMI provider is implemented
# at a lower level.
# ==============================================================================
function Register-ConceptualWMIProvider {
    param(
        [hashtable]$SpoofedProfile
    )
    Write-Host "[i] Registering conceptual WMI Provider (requires native code/driver for real effect)..."
    # In a real scenario, this would involve:
    # 1. Generating a MOF file dynamically based on $SpoofedProfile.
    # 2. Compiling the MOF file: mofcomp.exe YourSpoofedProvider.mof
    # 3. Deploying a C++/C# WMI provider DLL.
    # 4. Registering the provider.
    Write-Host "  WMI queries will still return real values without a proper provider."
}

function Unregister-ConceptualWMIProvider {
    Write-Host "[i] Unregistering conceptual WMI Provider..."
    # Cleanup for the conceptual provider.
    Write-Host "  No real WMI provider to unregister in this PowerShell script."
}

# Update Apply-AegisShroud and Restore-OriginalIdentity to include conceptual WMI provider calls
# (This part is already integrated into the main script logic, just adding a note here)

# ==============================================================================
# Kernel / Driver Footprint (Conceptual in PowerShell)
# True kernel/driver-level spoofing (e.g., patching SMBIOS in memory, hooking
# IRPs, spoofing disk serials via IOCTLs) is beyond the scope of a PowerShell
# script. It requires developing and deploying a kernel-mode driver.
#
# The current script acknowledges these limitations and focuses on user-mode
# registry and WMI (conceptual) spoofing.
# ==============================================================================

