#Requires -Module PlatyPS
param(
    [string]
    $WorkspaceFolder = (Split-Path $PSScriptRoot -Parent),

    [string]
    $OutputPath = (Join-Path $PSScriptRoot 'debug/Docker.PowerShell.CLI'),

    [switch]
    $Force
)

$DocsPath = Join-Path $WorkspaceFolder -ChildPath 'docs'
$OutputFilePath = Join-Path $OutputPath 'Docker.PowerShell.CLI-help.xml'
if (!$Force -and (Test-Path $OutputFilePath)) {
    $LastModified = (Get-Item $OutputFilePath).LastWriteTimeUtc
    $UpdateDocs = $false
    foreach ($Item in Get-ChildItem $DocsPath -Recurse -Filter '*.md') {
        if ($Item.LastWriteTimeUtc -gt $LastModified) {
            $UpdateDocs = $true
            break
        }
    }
}
else {
    $UpdateDocs = $true
}

if (!$UpdateDocs) {
    Write-Host "$OutputFilePath is up to date" -ForegroundColor Cyan
    Get-Item $OutputFilePath
    return
}

Write-Host "$OutputFilePath is being updated" -ForegroundColor Magenta

New-ExternalHelp -Path $DocsPath -OutputPath $OutputPath -Force