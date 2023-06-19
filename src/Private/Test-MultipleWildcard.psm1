function Test-MultipleWildcard {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]
        $WildcardPattern,

        [Parameter()]
        [string[]]
        $ActualValue
    )
    process {
        if (!$WildcardPattern) {
            return $true
        }
        if (!$ActualValue) {
            return $false
        }

        foreach ($w in $WildcardPattern) {
            foreach ($a in $ActualValue) {
                if ($a -like $w) {
                    return $true
                }
            }
        }
        return $false
    }
}
