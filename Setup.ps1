<#
    .SYNOPSIS
        A PowerShell script to set up a Windows environment by installing packages based on system hardware and user preferences.

    .DESCRIPTION
        This script detects the CPU and GPU of the system and installs relevant tools. It also prompts the user to install additional packages from YAML configuration files.
#>

Import-Module powershell-yaml

function Install-PackageYaml([string] $Filename) {
    <#
        .SYNOPSIS
            Installs packages listed in a YAML file.

        .PARAMETER Filename
            The path to the YAML file containing package information.
    #>

    if (Test-Path $Filename) {
        Write-Host "Installing packages from $Filename..."
        $packageContent = Get-Content -Raw -Path $Filename
        $packageData = $packageContent | ConvertFrom-Yaml

        foreach($package in $packageData.packages) {
            $id = $package.id
            $mode = $package.mode
            $source = $package.source
            $scope = $package.scope
            $condition = $package.condition

            # verify condition if it exists
            if ($null -ne $condition) {
                if (-not (Invoke-Expression $condition)) {
                    Write-Host "Skipping package $id due to unmet condition."
                    continue
                }
            }

            Write-Host "Installing package with ID: $id"
            winget.exe install `
                --$mode $id `
                -e `
                -s $source `
                --scope $scope `
                --accept-package-agreements `
                --accept-source-agreements `
                --force
        }
    } else {
        Write-Host "File not found: $filename"
    }
}

function Invoke-Main {
    <#
        .SYNOPSIS
            Main entry point for the script. 
    #>

    $files = Get-ChildItem -Recurse -Filter "*.yaml"
    foreach($file in $files) {
        $install = 0
        $filename = [System.IO.Path]::GetFileNameWithoutExtension($file)

        while ($install -ne "y" -and $install -ne "n") {
            $install = Read-Host "Do you want to install packages from $filename.yaml? (y/n)"
            if ($install -eq "y") {
                Install-PackageYaml -Filename $file.FullName
            }
        }
    }
    Write-Host "Setup complete. Please restart your system to apply all changes."
}

Invoke-Main