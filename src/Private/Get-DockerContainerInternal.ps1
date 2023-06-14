using namespace System.Management.Automation

# Helper function to get a container by name or id depending on which
# parameters were passed to the origin function. This can also escape
# the id parameter so that it does not support wildcard patterns.
function Get-DockerContainerInternal {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]
        $Name,

        [Parameter()]
        [string[]]
        $Id,

        [Parameter()]
        [string]
        $Context,

        [Parameter()]
        [switch]
        $EscapeId
    )

    process {
        $Parameters = @{}
        if ($Id) {
            $Parameters['Id'] = $Id | ForEach-Object {
                if ($EscapeId) {
                    [WildcardPattern]::Escape($_)
                }
                else {
                    $_
                }
            }
        }
        if ($Name) {
            $Parameters['Name'] = $Name
        }
        if ($Context) {
            $Parameters['Context'] = $Context
        }

        Get-DockerContainer @Parameters
    }
}
