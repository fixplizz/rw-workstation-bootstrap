Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step($Message) {
  Write-Host "install-windows-tools: $Message"
}

function Test-Command($Name) {
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-WingetPackage($Id, $Name) {
  if (-not (Test-Command "winget.exe")) {
    throw "winget.exe is required. Install App Installer from Microsoft Store, then rerun this script."
  }

  Write-Step "ensuring $Name ($Id)"
  $installed = winget.exe list --id $Id --exact --accept-source-agreements 2>$null
  if ($LASTEXITCODE -eq 0 -and $installed -match [regex]::Escape($Id)) {
    Write-Step "$Name already installed"
    return
  }

  winget.exe install --id $Id --exact --accept-package-agreements --accept-source-agreements
}

function Install-OpenCodeDesktop {
  $downloadDir = Join-Path $env:USERPROFILE "Downloads"
  $target = Join-Path $downloadDir "opencode-desktop-windows-x64.exe"
  $api = "https://api.github.com/repos/anomalyco/opencode/releases/latest"

  Write-Step "downloading latest OpenCode Desktop installer"
  $release = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "rw-workstation-bootstrap" }
  $asset = $release.assets | Where-Object { $_.name -match "opencode-desktop-windows-x64\.exe$" } | Select-Object -First 1
  if (-not $asset) {
    Write-Warning "OpenCode Desktop Windows installer was not found in latest release. Download manually from https://opencode.ai/download"
    return
  }

  New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $target
  Write-Step "launching OpenCode Desktop installer: $target"
  Start-Process -FilePath $target -Wait
}

Install-WingetPackage -Id "Git.Git" -Name "Git for Windows"
Install-WingetPackage -Id "Docker.DockerDesktop" -Name "Docker Desktop"
Install-WingetPackage -Id "Microsoft.EdgeWebView2Runtime" -Name "Microsoft Edge WebView2 Runtime"
Install-OpenCodeDesktop

$dockerDesktop = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerDesktop) {
  Write-Step "starting Docker Desktop"
  Start-Process -FilePath $dockerDesktop | Out-Null
}

Write-Step "done. If Docker Desktop was installed for the first time, reboot Windows or sign out/in, then enable WSL integration for Ubuntu 24.04."
