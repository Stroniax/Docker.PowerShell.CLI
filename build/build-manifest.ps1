#Requires -Version 7.0
param(
    [string]
    $WorkspaceFolder = (Split-Path $PSScriptRoot -Parent),

    [string]
    $OutputPath = (Join-Path $PSScriptRoot 'debug/Docker.PowerShell.CLI'),

    [System.Management.Automation.SemanticVersion]
    $Version = '0.0.1-dev',

    [switch]
    $Force,

    [string[]]
    $Functions,

    [string[]]
    $Variables,

    [string[]]
    $Aliases
)

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

$ModuleFiles = Get-ChildItem -Path $OutputPath -Recurse
$ManifestPath = Join-Path $OutputPath 'Docker.PowerShell.CLI.psd1'

if (!$Force -and (Test-Path $ManifestPath)) {
    $LastModified = (Get-Item $ManifestPath).LastWriteTimeUtc
    if ((Get-Item $MyInvocation.MyCommand.Source).LastWriteTimeUtc -gt $LastModified) {
        $UpdateModule = $true
    }
    else {
        $UpdateModule = $false
        foreach ($Child in $ModuleFiles) {
            if ($Child.LastWriteTimeUtc -gt $LastModified) {
                $UpdateModule = $true
                break
            }
        }
    }    
}
else {
    $UpdateModule = $true
}

if (!$UpdateModule) {
    Write-Host "$ManifestPath is up to date" -ForegroundColor Cyan
    Get-Item $ManifestPath
    return
}

Write-Host "$ManifestPath is being updated" -ForegroundColor Magenta

if (!$PSBoundParameters.ContainsKey('Functions') -or
    !$PSBoundParameters.ContainsKey('Variables') -or
    !$PSBoundParameters.ContainsKey('Aliases')) {

    $ScriptModulePath = Join-Path $OutputPath 'Docker.PowerShell.CLI.psm1'
    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptModulePath, [ref]$null, [ref]$null)
    $ExportModuleMember = $Ast.Find({
            param($Ast)
            $Ast -is [System.Management.Automation.Language.HashtableAst] -and
            $Ast.Parent.Parent -is [System.Management.Automation.Language.AssignmentStatementAst] -and
            $Ast.Parent.Parent.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
            $Ast.Parent.Parent.Left.VariablePath.UserPath -eq 'ExportModuleMember'
        }, $true).SafeGetValue()

    if (!$PSBoundParameters.ContainsKey('Functions')) {
        $Functions = $ExportModuleMember['Function']
    }
    if (!$PSBoundParameters.ContainsKey('Variables')) {
        $Variables = $ExportModuleMember['Variable']
    }
    if (!$PSBoundParameters.ContainsKey('Aliases')) {
        $Aliases = $ExportModuleMember['Alias']
    }
}

$NewModuleManifest = @{
    Path                       = $ManifestPath
    ModuleVersion              = $Version
    RootModule                 = 'Docker.PowerShell.CLI.psm1'
    FunctionsToExport          = $Functions
    VariablesToExport          = $Variables
    AliasesToExport            = $Aliases
    CmdletsToExport            = @()
    FileList                   = @(Get-ChildItem -Path $OutputPath -Recurse -Name)
    TypesToProcess             = @(Get-ChildItem -Path $OutputPath -Filter '*.types.ps1xml' -Recurse -Name)
    FormatsToProcess           = @(Get-ChildItem -Path $OutputPath -Filter '*.formats.ps1xml' -Recurse -Name)
    Guid                       = New-Guid
    Author                     = 'Caleb Frederickson'
    CompanyName                = 'Kenai Peninsula Borough School District'
    Copyright                  = '(c) KPBSD 2023'
    Description                = 'PowerShell module wrapper for the Docker CLI'
    RequiredAssemblies         = @(Get-ChildItem -Path $OutputPath -Filter '*.dll' -Recurse -Name)
    LicenseUri                 = 'https://github.com/Stroniax/Docker.PowerShell.CLI/LICENSE'
    ProjectUri                 = 'https://github.com/Stroniax/Docker.PowerShell.CLI'
    ReleaseNotes               = 'Find the latest release notes on github at https://github.com/Stroniax/Docker.PowerShell/CLI/releases'
    Tags                       = @('Docker', 'CLI', 'Docker.PowerShell.CLI')
    PowerShellVersion          = '5.1'
    DscResourcesToExport       = @()
    NestedModules              = @()
    ProcessorArchitecture      = 'None'
    PowerShellHostName         = $null
    PowerShellHostVersion      = $null
    ClrVersion                 = $null
    DotNetFrameworkVersion     = $null
    RequiredModules            = @()
    ScriptsToProcess           = @()
    ModuleList                 = @()
    CompatiblePSEditions       = @('Desktop', 'Core')
    # IconUri                    = $null
    RequireLicenseAcceptance   = $false
    ExternalModuleDependencies = @('docker')
    HelpInfoUri                = 'https://github.com/Stroniax/Docker.PowerShell/CLI/docs'
}
if ($Version.PreReleaseLabel) {
    $NewModuleManifest['Prerelease'] = $Version.PreReleaseLabel
}
New-ModuleManifest @NewModuleManifest
Get-Item $NewModuleManifest['Path']