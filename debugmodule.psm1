param(
    [Parameter()]
    [bool]$ExportAll
)

# Import the micro modules
Get-ChildItem $PSScriptRoot/src/Public -Recurse -Include '*.psm1', '*.ps1' | ForEach-Object {
    if ($_.Extension -eq '.ps1') {
        . $_.FullName
    }
    else {
        Import-Module $_.FullName
    }
}
Get-ChildItem $PSScriptRoot/src/Private -Recurse -Include '*.psm1', '*.ps1' | ForEach-Object {
    if ($_.Extension -eq '.ps1') {
        . $_.FullName
    }
    else {
        Import-Module $_.FullName
    }
}

# Import the micro types/formats
Get-ChildItem $PSScriptRoot/src -Recurse -Include '*.types.ps1xml' | ForEach-Object {
    Update-TypeData -PrependPath $_.FullName
}
Get-ChildItem $PSScriptRoot/src -Recurse -Include '*.formats.ps1xml' | ForEach-Object {
    Update-FormatData -PrependPath $_.FullName
}

if ($ExportAll) {
    # Some tests require external access to all functions (notably
    # tests for classes). These classes can access the private functions
    # when the module is built into a single file but not when imported
    # through this debugmodule.psm1 file.
    $ExportFunctions = '*'
}
else {
    # Identify public functions to export
    $ExportFunctions = @(
        Get-ChildItem $PSScriptRoot/src/Public -File -Recurse -Include '*.psm1', '*.ps1' | ForEach-Object -MemberName BaseName
    ) | Where-Object { $_ }
}
Export-ModuleMember -Function $ExportFunctions -Alias *