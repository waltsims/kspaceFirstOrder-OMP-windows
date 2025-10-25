# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell", "-NoProfile", "-Command"]

# Install Chocolatey and core build dependencies.
RUN Set-ExecutionPolicy Bypass -Scope Process -Force ; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072 ; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

RUN choco install -y --no-progress visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.ATLMFC --add Microsoft.VisualStudio.Component.Windows11SDK.22621" ; \
    choco install -y --no-progress cmake ninja git

ENV VCPKG_ROOT C:\\vcpkg

# Copy helper scripts for dependency installation and builds.
WORKDIR C:\\workspace
COPY install-deps.ps1 C:\\tools\\install-deps.ps1
COPY build.ps1 C:\\tools\\build.ps1

# By default drop into PowerShell. Users should invoke install-deps.ps1 followed by build.ps1.
ENTRYPOINT ["powershell.exe", "-NoLogo"]
