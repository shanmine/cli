# Copyright (c) .NET Foundation and contributors. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

# This script is used to generate a nuget package with the windows installer bundle.
# The generated nupkg file is used to deliver the CLI payload to Visual Studio.

param(
    [Parameter(Mandatory=$true)][string]$SdkBundlePath,
    [Parameter(Mandatory=$true)][string]$NugetVersion,
    [Parameter(Mandatory=$true)][string]$NuspecFile,
    [Parameter(Mandatory=$true)][string]$NupkgFile
)

. "$PSScriptRoot\..\..\..\scripts\common\_common.ps1"
$RepoRoot = Convert-Path "$PSScriptRoot\..\..\.."
$NuGetDir = Join-Path $RepoRoot ".nuget"
$NuGetExe = Join-Path $NuGetDir "nuget.exe"
$OutputDirectory = [System.IO.Path]::GetDirectoryName($SdkBundlePath)

function DownloadNugetExe
{
    if (-not (Test-Path $NuGetDir))
    {
        New-Item -ItemType Directory -Force -Path $NuGetDir | Out-Null
    }

    if (-not (Test-Path $NuGetExe)) {
        Write-Host 'Downloading nuget.exe to ' + $NuGetExe
        wget https://dist.nuget.org/win-x86-commandline/v3.5.0-rc1/NuGet.exe -OutFile $NuGetExe
    }
}

function GenerateNupkg
{
    if (-not (Test-Path $NuspecFile))
    {
        Write-Host 'Error nuspec not found - $NuspecFile'
    }

    $SdkBundleName = [System.IO.Path]::GetFileName($SdkBundlePath)
    $NuspecFileName = [System.IO.Path]::GetFileName($NuspecFile)
    $TempNuspecFile = [System.IO.Path]::Combine($OutputDirectory, $NuspecFileName)
    (Get-Content $NuspecFile) -replace '\[DOTNET_BUNDLE\]', $SdkBundleName | Set-Content $TempNuspecFile
    & $NuGetExe pack $TempNuspecFile -Version $NugetVersion -OutputDirectory $OutputDirectory
}


if(!(Test-Path $SdkBundlePath))
{
    throw "$SdkBundlePath not found"
}

Write-Host "Creating nupkg for Sdk installer"

DownloadNugetExe

if(Test-Path $NupkgFile)
{
    Remove-Item -Force $NupkgFile
}

if(-Not (GenerateNupkg))
{
    Exit -1
}

if(!(Test-Path $NupkgFile))
{
    throw "$NupkgFile not generated"
}

Write-Host -ForegroundColor Green "Successfully created installer nupkg - $NupkgFile"

exit $LastExitCode
