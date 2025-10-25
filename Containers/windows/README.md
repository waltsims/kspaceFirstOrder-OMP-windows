# Windows container build workflow

This directory contains helper assets for building **kspaceFirstOrder-OMP** inside a Windows container that uses the Microsoft Visual C++ toolchain with OpenMP enabled. The scripts assume the host has GPU passthrough configured only if runtime tests require it—the build itself does not require CUDA.

## Contents

- `Dockerfile` – provisions a Windows Server Core base image with Visual Studio Build Tools, CMake, Ninja, and Git.
- `install-deps.ps1` – bootstraps [vcpkg](https://github.com/microsoft/vcpkg) and installs the required third-party libraries (HDF5 and FFTW3).
- `build.ps1` – configures and compiles the project using CMake, Ninja, and MSVC while consuming dependencies through vcpkg.

## Usage

1. Build the container image (requires Windows host with container support):
   ```powershell
   docker build -t kspace-omp-builder -f Containers/windows/Dockerfile .
   ```

2. Start a container and mount your workspace:
   ```powershell
   docker run --rm -it -v ${PWD}:C:\workspace kspace-omp-builder
   ```

3. Inside the container, install dependencies and build the project:
   ```powershell
   Set-Location C:\workspace\Containers\windows
   .\install-deps.ps1
   $env:VCPKG_ROOT  # confirm path exported by the script
   .\build.ps1 -Config Release
   ```

   Build artifacts are placed under `build/windows` relative to the repository root.

### Customising the build

- Pass `-Config Debug` (or other `CMAKE_BUILD_TYPE` values) to `build.ps1` to generate different configurations.
- Supply a custom `-Triplet` if targeting a different architecture supported by vcpkg.
- Set the `VCPKG_ROOT` environment variable before invoking `build.ps1` to re-use an existing vcpkg instance.

## Continuous Integration

See [`.github/workflows/windows-container.yml`](../../.github/workflows/windows-container.yml) for an example GitHub Actions job that installs the dependencies with `install-deps.ps1` and then configures/builds the project using the `windows-msvc-vcpkg-release` CMake preset on hosted Windows runners.
