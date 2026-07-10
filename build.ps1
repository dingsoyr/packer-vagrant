[CmdletBinding()]
param(
    [string]$Box,
    [Nullable[bool]]$DeleteCache = $null,
    [Nullable[bool]]$Publish = $null,
    [switch]$PreflightOnly
)

$ErrorActionPreference = 'Stop'

Set-Location -Path $PSScriptRoot

function Test-CommandAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Invoke-PreflightChecks {
    $errors = New-Object System.Collections.Generic.List[string]

    Write-Host 'Running preflight checks...'

    if (-not (Test-CommandAvailable -Name 'packer')) {
        $errors.Add('Packer is not installed or not available in PATH. Install Packer and try again.')
    }

    if (-not (Test-CommandAvailable -Name 'vagrant')) {
        $errors.Add('Vagrant is not installed or not available in PATH. Install Vagrant and try again.')
    }

    if (-not (Test-CommandAvailable -Name 'Get-VMHost')) {
        $errors.Add('Hyper-V PowerShell support is not available on this machine. Enable Hyper-V and try again.')
    }
    else {
        try {
            $null = Get-VMHost -ErrorAction Stop
        }
        catch {
            $errors.Add('Hyper-V is not available on this machine. Enable Hyper-V and try again.')
        }
    }

    if (-not (Test-CommandAvailable -Name 'Get-NetFirewallRule')) {
        $errors.Add("Windows Firewall management is not available. Verify that the 'Packer_http_server' rule exists before running the build.")
    }
    else {
        $firewallRule = Get-NetFirewallRule -DisplayName 'Packer_http_server' -ErrorAction SilentlyContinue

        if (-not $firewallRule) {
            $errors.Add("Firewall rule 'Packer_http_server' was not found. Configure the firewall rule from README.md and try again.")
        }
    }

    if ($errors.Count -gt 0) {
        $message = @(
            'Preflight checks failed:'
            $errors | ForEach-Object { '- ' + $_ }
        ) -join [Environment]::NewLine

        throw $message
    }

    Write-Host 'Preflight checks passed.'
}

function Select-BoxFile {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Files
    )

    Write-Host ''
    Write-Host 'Available box definitions:'

    for ($index = 0; $index -lt $Files.Count; $index++) {
        Write-Host ('[{0}] {1}' -f ($index + 1), $Files[$index].Name)
    }

    while ($true) {
        $selection = Read-Host 'Select the box to build by number'
        $selectedIndex = 0

        if ([int]::TryParse($selection, [ref]$selectedIndex) -and $selectedIndex -ge 1 -and $selectedIndex -le $Files.Count) {
            return $Files[$selectedIndex - 1]
        }

        Write-Warning 'Please enter a valid number from the list.'
    }
}

function Resolve-BoxFile {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Files,

        [Parameter(Mandatory = $true)]
        [string]$Selection
    )

    $normalizedSelection = $Selection.Trim()

    if ([string]::IsNullOrWhiteSpace($normalizedSelection)) {
        throw 'The Box parameter cannot be empty.'
    }

    $matchingFiles = @(
        $Files | Where-Object {
            $_.BaseName -ieq $normalizedSelection -or
            $_.Name -ieq $normalizedSelection
        }
    )

    if ($matchingFiles.Count -eq 1) {
        return $matchingFiles[0]
    }

    if ($matchingFiles.Count -gt 1) {
        throw "The Box parameter '$Selection' matched more than one box definition. Use the full file name."
    }

    throw "The Box parameter '$Selection' did not match any box definition in the boxes directory."
}

function Read-YesNo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    while ($true) {
        $answer = (Read-Host "$Prompt [y/N]").Trim().ToLowerInvariant()

        if ([string]::IsNullOrWhiteSpace($answer) -or $answer -eq 'n' -or $answer -eq 'no') {
            return $false
        }

        if ($answer -eq 'y' -or $answer -eq 'yes') {
            return $true
        }

        Write-Warning 'Please answer y or n.'
    }
}

function Import-DotEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Missing .env file at $Path. Copy .env.example to .env and fill in hcp_client_id, hcp_client_secret, and vagrant_cloud_user before publishing."
    }

    $values = @{}

    foreach ($line in Get-Content -Path $Path) {
        $trimmedLine = $line.Trim()

        if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith('#')) {
            continue
        }

        $parts = $trimmedLine -split '=', 2

        if ($parts.Count -ne 2) {
            continue
        }

        $key = $parts[0].Trim()
        $value = $parts[1].Trim()

        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $values[$key] = $value
    }

    foreach ($requiredKey in @('hcp_client_id', 'hcp_client_secret', 'vagrant_cloud_user')) {
        if (-not $values.ContainsKey($requiredKey) -or [string]::IsNullOrWhiteSpace($values[$requiredKey])) {
            throw "Missing required value '$requiredKey' in .env file at $Path."
        }
    }

    return $values
}

function Get-BoxNameFromVarFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    foreach ($line in Get-Content -Path $Path) {
        if ($line -match '^\s*name\s*=\s*"(?<name>[^"]+)"\s*$') {
            return $Matches['name']
        }
    }

    throw "Could not determine box name from $Path."
}

function Invoke-Packer {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $displayArguments = foreach ($argument in $Arguments) {
        if ($argument -match '^hcp_client_id=') {
            'hcp_client_id=***'
            continue
        }

        if ($argument -match '^hcp_client_secret=') {
            'hcp_client_secret=***'
            continue
        }

        $argument
    }

    Write-Host ''
    Write-Host ('> packer {0}' -f ($displayArguments -join ' '))
    & packer @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Packer command failed with exit code $LASTEXITCODE."
    }
}

$boxFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'boxes') -Filter '*.pkrvars.hcl' | Sort-Object -Property Name

if (-not $boxFiles) {
    throw 'No box definitions were found in the boxes directory.'
}

Invoke-PreflightChecks

if ($PreflightOnly) {
    Write-Host ''
    Write-Host 'Preflight-only mode completed successfully.'
    return
}

$selectedBox = if ($PSBoundParameters.ContainsKey('Box')) {
    Resolve-BoxFile -Files $boxFiles -Selection $Box
}
else {
    Select-BoxFile -Files $boxFiles
}

$selectedBoxPath = Join-Path -Path '.\boxes' -ChildPath $selectedBox.Name
$selectedBoxName = Get-BoxNameFromVarFile -Path $selectedBox.FullName

if ($null -ne $DeleteCache) {
    $shouldDeleteCache = $DeleteCache
}
else {
    $shouldDeleteCache = Read-YesNo -Prompt 'Delete packer_cache before build to force fresh downloads?'
}

if ($shouldDeleteCache) {
    $cachePath = Join-Path -Path $PSScriptRoot -ChildPath 'packer_cache'

    if (Test-Path -Path $cachePath) {
        Write-Host ''
        Write-Host 'Deleting packer_cache...'
        Remove-Item -Path $cachePath -Recurse -Force
    }
    else {
        Write-Host ''
        Write-Host 'packer_cache does not exist. Skipping delete.'
    }
}

Invoke-Packer -Arguments @('init', '.')
Invoke-Packer -Arguments @('validate', '--var-file', $selectedBoxPath, '.')
Invoke-Packer -Arguments @('build', '--var-file', $selectedBoxPath, '--force', '-only=build.hyperv-iso.efi', '.')

if ($null -ne $Publish) {
    $shouldPublish = $Publish
}
else {
    $shouldPublish = Read-YesNo -Prompt 'Publish the built box to Vagrant Cloud?'
}

if ($shouldPublish) {
    $envValues = Import-DotEnv -Path (Join-Path -Path $PSScriptRoot -ChildPath '.env')

    Invoke-Packer -Arguments @(
        'build'
        '--var-file'
        $selectedBoxPath
        '--var'
        ('hcp_client_id={0}' -f $envValues['hcp_client_id'])
        '--var'
        ('hcp_client_secret={0}' -f $envValues['hcp_client_secret'])
        '--var'
        ('vagrant_cloud_user={0}' -f $envValues['vagrant_cloud_user'])
        '--force'
        '-only=publish.null.core'
        '.'
    )

    $publishedBoxUrl = 'https://portal.cloud.hashicorp.com/vagrant/discover/{0}/{1}' -f $envValues['vagrant_cloud_user'], $selectedBoxName
    Write-Host ''
    Write-Host 'Published box:'
    Write-Host $publishedBoxUrl
}