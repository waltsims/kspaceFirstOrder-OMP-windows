[CmdletBinding()]
param(
    [ValidateSet('Release','Debug')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $PSScriptRoot)) {
    throw 'PSScriptRoot is unavailable; run this script via PowerShell.'
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
if (-not $env:VCPKG_ROOT) {
    $env:VCPKG_ROOT = Join-Path $repoRoot '.vcpkg'
}

if (-not (Test-Path $env:VCPKG_ROOT)) {
    git clone https://github.com/microsoft/vcpkg $env:VCPKG_ROOT
    & (Join-Path $env:VCPKG_ROOT 'bootstrap-vcpkg.bat')
}

& (Join-Path $env:VCPKG_ROOT 'vcpkg.exe') install hdf5[core] fftw3 --triplet x64-windows --recurse

$configurePreset = "windows-msvc-vcpkg-$($Configuration.ToLower())"
cmake --preset $configurePreset
cmake --build --preset $configurePreset
