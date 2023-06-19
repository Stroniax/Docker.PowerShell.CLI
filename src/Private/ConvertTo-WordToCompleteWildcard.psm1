function ConvertTo-WordToCompleteWildcard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $WordToComplete
    )
    process {
        if ($WordToComplete -eq '') {
            return '*'
        }

        $StartIndex = 0
        $Length = $WordToComplete.Length
        foreach ($QuoteChar in @('''', '"')) {
            if ($WordToComplete.StartsWith($QuoteChar)) {
                $StartIndex = 1
                if ($WordToComplete.EndsWith($QuoteChar)) {
                    $Length = [Math]::Max($WordToComplete.Length - 2, 0)
                }
                else {
                    $Length = $WordToComplete.Length - 1
                }
                # Do not remove multiple quote characters
                break
            }
        }

        $TextToComplete = $WordToComplete.Substring($StartIndex, $Length)

        "$TextToComplete*"
    }
}