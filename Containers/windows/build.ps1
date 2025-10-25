[CmdletBinding()]
param(
    [string]$BuildDir = "$PSScriptRoot/../../build/windows",
    [ValidateSet('Release', 'Debug', 'RelWithDebInfo', 'MinSizeRel')]
    [string]$Config = 'Release',
    [string]$Triplet = 'x64-windows'
)

$ErrorActionPreference = 'Stop'

function Get-VsDevCmdPath {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (-not (Test-Path $vswhere)) {
        throw 'vswhere.exe not found. Install Visual Studio Build Tools.'
    }

    $installationPath = & $vswhere -latest -requires Microsoft.Component.MSBuild -property installationPath
    if (-not $installationPath) {
        throw 'Visual Studio installation not found. Install Visual Studio Build Tools.'
    }

    $devCmd = Join-Path $installationPath 'Common7/Tools/VsDevCmd.bat'
    if (-not (Test-Path $devCmd)) {
        throw "VsDevCmd.bat not found under $installationPath"
    }

    return $devCmd
}

function Invoke-CheckedCommand {
    param(
        [string]$Command,
        [string]$ErrorMessage
    )

    Write-Host "==> $Command"
    & cmd.exe /c $Command
    if ($LASTEXITCODE -ne 0) {
        throw $ErrorMessage
    }
}

$sourceDir = Resolve-Path "$PSScriptRoot/../.."
$buildDirResolved = Resolve-Path -ErrorAction SilentlyContinue $BuildDir
if (-not $buildDirResolved) {
    New-Item -ItemType Directory -Path $BuildDir | Out-Null
    $buildDirResolved = Resolve-Path $BuildDir
}

if (-not $env:VCPKG_ROOT) {
    throw 'VCPKG_ROOT environment variable not set. Run install-deps.ps1 first.'
}

$toolchainFile = Join-Path $env:VCPKG_ROOT 'scripts/buildsystems/vcpkg.cmake'
if (-not (Test-Path $toolchainFile)) {
    throw "vcpkg toolchain file not found at $toolchainFile"
}

$devCmd = Get-VsDevCmdPath

$configureArgs = @(
    "\"$devCmd\" -arch=x64 -host_arch=x64",
    "&&",
    'cmake',
    "-S", "\"$sourceDir\"",
    "-B", "\"$buildDirResolved\"",
    '-G', 'Ninja',
    '-D', "CMAKE_BUILD_TYPE=$Config",
    '-D', 'CMAKE_C_COMPILER=cl.exe',
    '-D', 'CMAKE_CXX_COMPILER=cl.exe',
    '-D', "CMAKE_TOOLCHAIN_FILE=$toolchainFile",
    '-D', "VCPKG_TARGET_TRIPLET=$Triplet"
)

$buildArgs = @(
    "\"$devCmd\" -arch=x64 -host_arch=x64",
    '&&',
    'cmake',
    '--build', "\"$buildDirResolved\"",
    '--config', $Config
)

Invoke-CheckedCommand -Command ($configureArgs -join ' ') -ErrorMessage 'CMake configuration failed.'
Invoke-CheckedCommand -Command ($buildArgs -join ' ') -ErrorMessage 'CMake build failed.'
