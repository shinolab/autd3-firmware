﻿Param(
    [string]$version = "12.1.0",
    [string]$vivado_dir = "NULL"
)

function ColorEcho($color, $PREFIX, $message) {
    Write-Host $PREFIX -ForegroundColor $color -NoNewline
    Write-Host ":", $message
}

function TestCommand($command) {
    return -not -not (Get-Command $command -ea SilentlyContinue);
}

function GetInstallLocation($displayNamePattern) {
    $prog_reg = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object DisplayName -match $displayNamePattern | Select-Object -first 1
    if ($prog_reg) {
        return $prog_reg.InstallLocation
    }
    else {
        return "NULL"
    }
}

function UpdateCPU([string]$cpuFirmwareFile) {
    $jlink_path = GetInstallLocation 'J-Link'
    if ($jlink_path -eq "NULL") {
        ColorEcho "Red" "Error" "J-Link is not found. PLease install J-Link."
        Stop-Transcript | Out-Null
        exit -1
    }
    else {
        $env:Path = $jlink_path + ";" + $env:Path
    }
    ColorEcho "Green" "INFO" "Find J-Link"

    Copy-Item -Path $cpuFirmwareFile -Destination "tmp.bin" -Force
    & jlink -device R7S910018_R4F -if JTAG -speed 4000 -jtagconf -1,-1 -autoconnect 1 -ExitOnError 1 -CommanderScript ./scripts/cpu_flash.jlink
    $Success = $?
    Remove-Item -Path "tmp.bin"
    if ($Success) {
        ColorEcho "Green" "INFO" "Update CPU done."
    } else {
        ColorEcho "Red" "ERROR" "Failed to update CPU. Make sure that AUTD is connected and power on."
        Stop-Transcript | Out-Null
        exit -1
    }
}

function FindXilinxPath() {
    $xilinx_path = GetInstallLocation 'Vivado|Vitis|(Xilinx Design Tools FPGAs)'
    if (($xilinx_path -eq "NULL")) {
        ColorEcho "Red" "Error" "Vivado is not found. Install Vivado."
        Stop-Transcript | Out-Null
        exit -1
    }
    ColorEcho "Green" "INFO" "Found Xilinx path", $xilinx_path
    return $xilinx_path
}

function AddVivadoToPATH_2024_or_older($vivado_dir, $xilinx_path, $edition) {
    if ($vivado_dir -eq "NULL") {
        $vivado_path = Join-Path $xilinx_path $edition
        if (-not (Test-Path $vivado_path)) {
            return
        }
        
        $vivados = Get-ChildItem $vivado_path
        if ($vivados.Length -eq 0) {
            return
        }

        $vivado_ver = $vivados | Select-Object -first 1
        ColorEcho "Green" "INFO" "Find", $edition, $vivado_ver.Name
        $vivado_dir = $vivado_ver.FullName
    }

    $vivado_bin = Join-Path $vivado_dir "bin"
    $vivado_lib = Join-Path $vivado_dir "lib" | Join-Path -ChildPath "win64.o" 
    $env:Path = $env:Path + ";" + $vivado_bin + ";" + $vivado_lib
}

function AddVivadoToPATH_2025($vivado_dir, $xilinx_path, $edition) {
    if ($vivado_dir -eq "NULL") {
        $vivados = Get-ChildItem -Path $xilinx_path -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq $edition }
        if ($vivados.Length -eq 0) {
            return
        }

        $vivado = $vivados | Select-Object -first 1
        $vivado_dir = $vivado.FullName
        ColorEcho "Green" "INFO" "Find", $edition, "at", $vivado_dir
    }

    $vivado_bin = Join-Path $vivado_dir "bin"
    $vivado_lib = Join-Path $vivado_dir "lib" | Join-Path -ChildPath "win64.o" 
    $env:Path = $env:Path + ";" + $vivado_bin + ";" + $vivado_lib
}

function UpdateFPGA([string]$fpgaFirmwareFile, [string]$vivado_dir) {
    $can_use_vivado = TestCommand vivado
    $can_use_vivado_lab = TestCommand vivado_lab

    $xilinx_path = ""

    if ((-not $can_use_vivado) -and (-not $can_use_vivado_lab)) {
        ColorEcho "Green" "INFO" "Vivado is not found in PATH. Looking for Vivado..."
        $xilinx_path = FindXilinxPath
        
        AddVivadoToPATH_2024_or_older $vivado_dir $xilinx_path "Vivado"
        $can_use_vivado = TestCommand vivado
    }

    if ((-not $can_use_vivado) -and (-not $can_use_vivado_lab)) {
        AddVivadoToPATH_2024_or_older $vivado_dir $xilinx_path "Vivado_Lab"
        $can_use_vivado_lab = TestCommand vivado_lab
    }
    
    # if ((-not $can_use_vivado) -and (-not $can_use_vivado_lab)) {
    #     AddVivadoToPATH_2025 $vivado_dir $xilinx_path "Vivado"
    #     $can_use_vivado = TestCommand vivado
    # }

    if ((-not $can_use_vivado) -and (-not $can_use_vivado_lab)) {
        AddVivadoToPATH_2025 $vivado_dir $xilinx_path "Vivado_Lab"
        $can_use_vivado_lab = TestCommand vivado_lab
    }

    if ((-not $can_use_vivado) -and (-not $can_use_vivado_lab)) {
        ColorEcho "Red" "Error" "Vivado is not found. Install Vivado or add Vivado install folder to PATH."
        Stop-Transcript | Out-Null
        exit -1
    }

    Copy-Item -Path $fpgaFirmwareFile -Destination "./scripts/tmp.mcs" -Force
    ColorEcho "Green" "INFO" "Invoking Vivado..."

    if ($can_use_vivado) {
        & vivado -mode batch -nojournal -nolog -notrace -source ./scripts/fpga_configuration_script.tcl
    } elseif ($can_use_vivado_lab) {
        & vivado_lab -mode batch -nojournal -nolog -notrace -source ./scripts/fpga_configuration_script.tcl
    }
    $Success = $?
    Remove-Item -Path "./scripts/tmp.mcs"
    if ($Success) {
        ColorEcho "Green" "INFO" "Update FPGA done."
    } else {
        ColorEcho "Red" "ERROR" "Failed to update FPGA. Make sure that AUTD is connected and power on."
        Stop-Transcript | Out-Null
        exit -1
    }
}

Start-Transcript "autd_firmware_writer.log" | Out-Null
Write-Host "AUTD3 Firmware Writer"

if (-not (Test-Path "tmp")) {
    New-Item -ItemType directory -Path "tmp" | Out-Null
}
if (-not (Test-Path "tmp/v$version")) {
  ColorEcho "Green" "INFO" "Downloading firmware files..."
  ColorEcho "Green" "INFO" "https://github.com/shinolab/autd3-firmware/releases/download/v$version/firmware-v$version.zip"
  Invoke-WebRequest "https://github.com/shinolab/autd3-firmware/releases/download/v$version/firmware-v$version.zip" -OutFile "tmp.zip" | Out-Null
  Expand-Archive -Path "tmp.zip" -DestinationPath "tmp/v$version" -Force
  Remove-Item -Path "tmp.zip"
}
$firmwares = Get-ChildItem "tmp/v$version"
if ($firmwares.Length -eq 0) {
    ColorEcho "Red" "ERROR" "Firmware files are not found."
    Stop-Transcript | Out-Null
    exit -1
}
ColorEcho "Green" "INFO" "Found firmwares are..."
$fpga_firmware = ""
$cpu_firmware = ""
foreach ($firmware in $firmwares) {
    $ext = $firmware.Name.Split('.') | Select-Object -last 1
    if ($ext -eq "bin") {
        $cpu_firmware = $firmware.FullName
        ColorEcho "Blue" "CPU " $firmware.Name
    }
    if ($ext -eq "mcs") {
        $fpga_firmware = $firmware.FullName
        ColorEcho "Blue" "FPGA" $firmware.Name
    }
}

ColorEcho "Green" "INFO" "Make sure that you connected configuration cabels and AUTD's power is on."
ColorEcho "Green" "INFO" "Select which firmware to be updated."
Write-Host "[0]: Both (Default)"
Write-Host "[1]: FPGA"
Write-Host "[2]: CPU"
do {
    try {
        $is_num = $true
        [int]$select = Read-host "Select"
    }
    catch { $is_num = $false }
}
until (($select -ge 0 -and $select -le 2) -and $is_num)

if ($select -eq 0) {
    UpdateCPU $cpu_firmware
    UpdateFPGA $fpga_firmware $vivado_dir
}
if ($select -eq 1) {
    UpdateFPGA $fpga_firmware $vivado_dir
}
if ($select -eq 2) {
    UpdateCPU $cpu_firmware
}

ColorEcho "Green" "INFO" "Please turn AUTD's power off and on again to load new firmware."
Stop-Transcript | Out-Null
exit
