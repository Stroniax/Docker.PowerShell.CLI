using namespace System.Management.Automation.Language

function ConvertTo-CompletionText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $InputObject,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $WordToComplete
    )
    process {
        $QuoteType = $null
        foreach ($QuoteChar in @('''', '"')) {
            if ($WordToComplete.StartsWith($QuoteChar)) {
                $QuoteType = $QuoteChar
                break
            }
        }

        switch ($QuoteType) {
            '''' {
                '''{0}''' -f [CodeGeneration]::EscapeSingleQuotedStringContent($InputObject)
            }
            '"' {
                '"{0}"' -f (($InputObject -replace '"', '""') -replace '`', '``')
            }
            default {
                if ($InputObject -match '[\s''"]') {
                    '''{0}''' -f [CodeGeneration]::EscapeSingleQuotedStringContent($InputObject)
                }
                else {
                    $InputObject
                }
            }
        }
    }
}