[CmdletBinding()]
param(
    [string]$VcpkgRoot,
    [string]$Triplet = 'x64-windows'
)

$ErrorActionPreference = 'Stop'

if (-not $VcpkgRoot) {
    $repoRoot = Resolve-Path "$PSScriptRoot/../.."
    $VcpkgRoot = Join-Path $repoRoot 'vcpkg'
}

function Invoke-CommandChecked {
    param(
        [ScriptBlock]$Script,
        [string]$Message
    )

    Write-Host "==> $Message"
    & $Script
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Message"
    }
}

if (-not (Test-Path $VcpkgRoot)) {
    $parent = Split-Path $VcpkgRoot
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Invoke-CommandChecked -Message "Cloning vcpkg" -Script {
        git clone https://github.com/microsoft/vcpkg $VcpkgRoot
    }
} else {
    Write-Host "==> Re-using existing vcpkg clone at $VcpkgRoot"
    Invoke-CommandChecked -Message "Updating vcpkg" -Script {
        pushd $VcpkgRoot
        git pull --ff-only
        popd
    }
}

Invoke-CommandChecked -Message "Bootstrapping vcpkg" -Script {
    pushd $VcpkgRoot
    if (Test-Path (Join-Path $VcpkgRoot 'vcpkg.exe')) {
        Write-Host 'vcpkg.exe already exists, skipping bootstrap'
    } else {
        & (Join-Path $VcpkgRoot 'bootstrap-vcpkg.bat')
        if ($LASTEXITCODE -ne 0) {
            throw 'vcpkg bootstrap failed'
        }
    }
    popd
}

$packages = @(
    'hdf5[core]',
    'fftw3'
)

foreach ($package in $packages) {
    Invoke-CommandChecked -Message "Installing $package for $Triplet" -Script {
        & (Join-Path $VcpkgRoot 'vcpkg.exe') install $package --triplet $Triplet --recurse
    }
}

$env:VCPKG_ROOT = (Resolve-Path $VcpkgRoot)
Write-Host "==> Dependencies installed. Set VCPKG_ROOT to $env:VCPKG_ROOT"
