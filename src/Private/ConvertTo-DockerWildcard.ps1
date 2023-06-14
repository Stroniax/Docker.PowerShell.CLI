function ConvertTo-DockerWildcard {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]
        $Expression
    )
    process {
        $Expression -split '(?<!`)\*' | ForEach-Object {
            if ($_) {
                $_ -replace '`\*', '*'
            }
        }
    }
}
