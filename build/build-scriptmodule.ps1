[CmdletBinding()]
param(
    [string]
    $WorkspaceFolder = (Split-Path $PSScriptRoot -Parent),

    [string]
    $OutputPath = (Join-Path $PSScriptRoot 'debug/Docker.PowerShell.CLI'),

    [switch]
    $Force
)

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

$ScriptModulePath = Join-Path $OutputPath 'Docker.PowerShell.CLI.psm1'
$Parser = [System.Management.Automation.Language.Parser]

$UsingNamespaces = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$UsingModules = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

function Get-UsingNamespace ($FilePath) {
    $Ast = $Parser::ParseFile($FilePath, [ref]$null, [ref]$null)
    $Ast.UsingStatements | ForEach-Object {
        if ($_.UsingStatementKind -eq 'Namespace') {
            $_.Name.Value.TrimEnd(';')
        }
    }
}

function Get-UsingModule ($FilePath) {
    $Ast = $Parser::ParseFile($FilePath, [ref]$null, [ref]$null)
    $Ast.UsingStatements | ForEach-Object {
        if ($_.UsingStatementKind -eq 'Module') {
            $_.Name.Value.TrimEnd(';')
        }
    }
}

function Resolve-RelativePath ($From, $Path) {
    Push-Location $From
    (Resolve-Path $Path).ProviderPath
    Pop-Location
}

$SourceFiles = Get-ChildItem $WorkspaceFolder -Exclude build, tests | Get-ChildItem -Recurse -Include '*.ps1', '*.psm1' -Exclude debugmodule.psm1

if (!$Force -and (Test-Path $ScriptModulePath)) {
    $LastModified = (Get-Item $ScriptModulePath).LastWriteTimeUtc
    
    if ((Get-Item $MyInvocation.MyCommand.Source).LastWriteTimeUtc -gt $LastModified) {
        $UpdateScriptModule = $true
    }
    else {
        $UpdateScriptModule = $false
        foreach ($Child in $SourceFiles) {
            if ($Child.LastWriteTimeUtc -gt $LastModified) {
                $UpdateScriptModule = $true
                break
            }
        }
    }
}
else {
    $UpdateScriptModule = $true
}

if (!$UpdateScriptModule) {
    Write-Host "$ScriptModulePath is up to date" -ForegroundColor Cyan
    $Ast = $Parser::ParseFile($ScriptModulePath, [ref]$null, [ref]$null)
    $ExportedMembers = $Ast.Find({
            param([System.Management.Automation.Language.Ast]$Ast)

            if ($Ast -isnot [System.Management.Automation.Language.HashtableAst]) {
                return $false
            }
            if ($Ast.Parent.Parent -isnot [System.Management.Automation.Language.AssignmentStatementAst]) {
                return $false
            }
            if ($Ast.Parent.Parent.Left -isnot [System.Management.Automation.Language.VariableExpressionAst]) {
                return $false
            }

            return $Ast.Parent.Parent.Left.VariablePath.UserPath -eq 'ExportModuleMember'
        }, $false).SafeGetValue()
    
    [pscustomobject]@{
        PublicFunctions = $ExportedMembers['Function']
        PublicAliases   = $ExportedMembers['Alias']
        PublicVariables = $ExportedMembers['Variable']
        SourceFiles     = $SourceFiles.FullName
        OutputFile      = Get-Item $ScriptModulePath
    }
    return
}

Write-Host "$ScriptModulePath is being updated" -ForegroundColor Magenta

foreach ($File in $SourceFiles) {
    Get-UsingNamespace $File.FullName | ForEach-Object { [void]$UsingNamespaces.Add($_) }
    Get-UsingModule $File.FullName | ForEach-Object {
        $ResolvedPath = Resolve-RelativePath -From $File.Directory.FullName -Path $_
        if ($SourceFiles.FullName -notcontains $ResolvedPath) {
            $UsingModules.Add($ResolvedPath)
        }
    }
}


Remove-Item -Path $ScriptModulePath -ErrorAction SilentlyContinue

foreach ($ns in $UsingNamespaces) {
    "using namespace $ns" | Out-File -Append -Path $ScriptModulePath
}
foreach ($m in $UsingModules) {
    "using module $m" | Out-File -Append -Path $ScriptModulePath
}

$PublicFunctions = [System.Collections.Generic.HashSet[string]]::new()
$PublicAliases = [System.Collections.Generic.HashSet[string]]::new()
$PublicVariables = [System.Collections.Generic.HashSet[string]]::new()

foreach ($File in $SourceFiles) {
    $Ast = $Parser::ParseFile($File, [ref]$null, [ref]$null)
    $Ast.EndBlock.Extent.Text | Out-File -Append -Path $ScriptModulePath

    if ($File.FullName -match 'public') {
        $Functions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
        foreach ($Function in $Functions) {
            [void]$PublicFunctions.Add($Function.Name)
            $AliasAst = $Function.Body.ParamBlock.Attributes | Where-Object { $_.TypeName.GetReflectionType() -eq [Alias] }
            foreach ($Alias in $AliasAst.PositionalArguments) {
                [void]$PublicAliases.Add($Alias.SafeGetValue())
            }
        }
        $Variables = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $false)
        foreach ($Variable in $Variables) {
            if ($Variable.IsUnqualified) {
                [void]$PublicVariables.Add($Variable.VariablePath.UserPath)
            }
        }
    }
}

@"

`$ExportModuleMember = @{
    Function = @(
        $(($PublicFunctions | ForEach-Object { "'$_'" }) -join ",$([Environment]::NewLine)`t`t")
    )
    Alias = @(
        $(($PublicAliases | ForEach-Object { "'$_'" }) -join ",$([Environment]::NewLine)`t`t")
    )
    Variable = @(
        $(($PublicVariables | ForEach-Object { "'$_'" }) -join ",$([Environment]::NewLine)`t`t")
    )
}
Export-ModuleMember @ExportModuleMember
"@ | Out-File -Append -Path $ScriptModulePath

[pscustomobject]@{
    PublicFunctions = $PublicFunctions
    PublicAliases   = $PublicAliases
    PublicVariables = $PublicVariables
    SourceFiles     = $SourceFiles.FullName
    OutputFile      = Get-Item $ScriptModulePath
}

