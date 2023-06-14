# Import the monolith module file and types/formats
Update-TypeData -PrependPath $PSScriptRoot/docker.types.ps1xml
Update-FormatData -PrependPath $PSScriptRoot/docker.formats.ps1xml

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

$ExportFunctions = @(
    Get-ChildItem $PSScriptRoot/src/Public -File -Recurse -Include '*.psm1', '*.ps1' | ForEach-Object -MemberName BaseName
) | Where-Object { $_ }
Export-ModuleMember -Function $ExportFunctions -Alias *