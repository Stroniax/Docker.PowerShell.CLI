# Build type files

param(
    [string]
    $SourcePath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'src'),

    [string]
    $OutputPath = (Join-Path $PSScriptRoot 'debug/Docker.PowerShell.CLI'),

    [switch]
    $Force
)

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

$TypesFilePath = Join-Path $OutputPath 'Docker.PowerShell.CLI.types.ps1xml'
$TypeFiles = Get-ChildItem $SourcePath -Recurse -Include '*.types.ps1xml'

if (!$Force -and (Test-Path $TypesFilePath)) {
    $UpdateTypes = $false
    $LastModified = (Get-Item $TypesFilePath).LastWriteTimeUtc
    foreach ($Child in $TypesFiles) {
        if ($Child.LastWriteTimeUtc -gt $LastModified) {
            $UpdateTypes = $true
            break
        }
    }
}
else {
    $UpdateTypes = $true
}

if ($UpdateTypes) {
    foreach ($TypeFile in $TypeFiles) {
        $CurrentXml = [xml](Get-Content -LiteralPath $TypeFile.FullName)
        if ($TypeXml) {
            $TypeXml.Types.InnerXml += $CurrentXml.Types.InnerXml
        }
        else {
            $TypeXml = $CurrentXml
        }
    }

    Write-Host "$TypesFilePath is being updated" -ForegroundColor Magenta
    $TypeXml.Save($TypesFilePath)
}
else {
    Write-Host "$TypesFilePath is up to date" -ForegroundColor Cyan
}

$FormatsFilePath = Join-Path $OutputPath 'Docker.PowerShell.CLI.formats.ps1xml'
$FormatFiles = Get-ChildItem $SourcePath -Recurse -Include '*.formats.ps1xml'

if (!$Force -and (Test-Path $FormatsFilePath)) {
    $LastModified = (Get-Item $FormatsFilePath).LastWriteTimeUtc
    $UpdateFormats = $false
    foreach ($Child in $FormatFiles) {
        if ($Child.LastWriteTimeUtc -gt $LastModified) {
            $UpdateFormats = $true
            break
        }
    }
}
else {
    $UpdateFormats = $true
}

if ($UpdateFormats) {
    foreach ($FormatFile in $FormatFiles) {
        $CurrentXml = [xml](Get-Content -LiteralPath $FormatFile.FullName)
        if ($FormatXml) {
            foreach ($Node in $CurrentXml.Configuration.ViewDefinitions.ChildNodes) {
                [void]$FormatXml.Configuration.SelectSingleNode('ViewDefinitions').AppendChild($FormatXml.ImportNode($Node, $true))
            }
            foreach ($Node in $CurrentXml.Configuration.SelectionSets.ChildNodes) {
                [void]$FormatXml.Configuration.SelectSingleNode('SelectionSets').AppendChild($FormatXml.ImportNode($Node, $true))
            }
            foreach ($Node in $CurrentXml.Configuration.Controls.ChildNodes) {
                [void]$FormatXml.Configuration.SelectSingleNode('Controls').AppendChild($FormatXml.ImportNode($Node, $true))
            }
        }
        else {
            $FormatXml = $CurrentXml
            if (!$FormatXml.Configuration.ViewDefinitions) {
                [void]$FormatXml.Configuration.AppendChild($FormatXml.CreateElement('ViewDefinitions'))
            }
            if (!$FormatXml.Configuration.SelectionSets) {
                [void]$FormatXml.Configuration.AppendChild($FormatXml.CreateElement('SelectionSets'))
            }
            if (!$FormatXml.Configuration.Controls) {
                [void]$FormatXml.Configuration.AppendChild($FormatXml.CreateElement('Controls'))
            }
        }
    }

    Write-Host "$FormatsFilePath is being updated" -ForegroundColor Magenta
    $FormatXml.Save($FormatsFilePath)
}
else {
    Write-Host "$FormatsFilePath is up to date" -ForegroundColor Cyan
}

Get-Item $TypesFilePath, $FormatsFilePath