param(
  [string]$SourceDir = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Dest = Join-Path $Root "third_party\libarchive\windows"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$Candidates = @()

if ($SourceDir -ne "") {
  $Candidates += $SourceDir
}

if ($env:VCPKG_ROOT) {
  $Candidates += Join-Path $env:VCPKG_ROOT "installed\x64-windows\bin"
  $Candidates += Join-Path $env:VCPKG_ROOT "installed\x64-windows-release\bin"
}

$Candidates += "C:\vcpkg\installed\x64-windows\bin"
$Candidates += "C:\vcpkg\installed\x64-windows-release\bin"
$Candidates += "C:\vcpkg\packages\libarchive_x64-windows\bin"

$MsysRoots = @("C:\msys64\ucrt64\bin", "C:\msys64\mingw64\bin")
$Candidates += $MsysRoots

$Copied = @()
$Checked = @()
foreach ($Dir in $Candidates) {
  $Checked += $Dir
  if (!(Test-Path $Dir)) {
    continue
  }
  $Dlls = Get-ChildItem -Path $Dir -Filter "*.dll" -File |
    Where-Object {
      $_.Name -match "archive|zlib|bz2|lzma|lz4|zstd|iconv|charset|crypto|ssl|xml2|expat"
    }
  foreach ($Dll in $Dlls) {
    Copy-Item $Dll.FullName -Destination (Join-Path $Dest $Dll.Name) -Force
    $Copied += $Dll.Name
  }
  if ($Copied | Where-Object { $_ -match "archive" }) {
    break
  }
}

if (!($Copied | Where-Object { $_ -match "archive" })) {
  Write-Host "Checked directories:"
  $Checked | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" }
  throw "libarchive DLL was not found. Pass -SourceDir or install libarchive with vcpkg/MSYS2."
}

Write-Host "Vendored libarchive Windows files:"
$Copied | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" }
