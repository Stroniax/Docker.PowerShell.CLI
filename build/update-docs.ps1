#Requires -Module PlatyPS
param(
    [string]
    $WorkspaceFolder = (Split-Path $PSScriptRoot -Parent)
)

if (-not (Get-Module Docker.PowerShell.CLI)) {
    Import-Module (Join-Path $WorkspaceFolder 'build/debug/Docker.PowerShell.CLI/Docker.PowerShell.CLI.psd1' -ErrorAction Stop)
}

$UpdateMarkdownHelpModule = @{
    Path              = Join-Path $WorkspaceFolder 'docs'
    Encoding          = [System.Text.Encoding]::Unicode
    RefreshModulePage = $true
    UseFullTypeName   = $true
    UpdateInputOutput = $true
    Force             = $true
}
Update-MarkdownHelpModule @UpdateMarkdownHelpModule