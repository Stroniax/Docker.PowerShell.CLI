#Requires -Version 7.0

param(
    [string]
    $WorkspaceFolder = (Split-Path $PSScriptRoot -Parent),

    [Parameter(Mandatory)]
    [System.Management.Automation.SemanticVersion]
    $Version
)

$OutputPath = Join-Path $PSScriptRoot 'release/Docker.PowerShell.CLI' $Version

if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force -Recurse
}

$BuildDocsFile = Join-Path $WorkspaceFolder 'build/build-docs.ps1'
$BuildDocs = Start-Job -FilePath $BuildDocsFile -ArgumentList $WorkspaceFolder, $OutputPath

$BuildPs1xmlFile = Join-Path $WorkspaceFolder 'build/build-ps1xml.ps1'
$BuildPs1xml = Start-Job -FilePath $BuildPs1xmlFile -ArgumentList $WorkspaceFolder, $OutputPath

$BuildScriptModuleFile = Join-Path $WorkspaceFolder 'build/build-scriptmodule.ps1'
$BuildScriptModule = Start-Job -FilePath $BuildScriptModuleFile -ArgumentList $WorkspaceFolder, $OutputPath

Receive-Job -Job $BuildDocs, $BuildPs1xml, $BuildScriptModule -Wait -AutoRemoveJob -ErrorAction Stop | Out-Null

$BuildManifestFile = Join-Path $WorkspaceFolder 'build/build-manifest.ps1'
$BuildManifest = Start-Job -ScriptBlock {
    param(
        $BuildManifestFile,
        $WorkspaceFolder,
        $OutputPath,
        $Version
    )
    & $BuildManifestFile @PSBoundParameters
} -ArgumentList $BuildManifestFile, $WorkspaceFolder, $OutputPath, ([string]$Version)

Receive-Job $BuildManifest -Wait -AutoRemoveJob -ErrorAction Stop