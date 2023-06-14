using namespace System.Management.Automation

function Get-DockerImageInternal {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Tag,

        [Parameter()]
        [string[]]
        $Id,

        [Parameter()]
        [string[]]
        $FullName,

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
            $Parameters['Tag'] = $Tag
        }
        if ($FullName) {
            $Parameters['FullName'] = $FullName
        }
        if ($Context) {
            $Parameters['Context'] = $Context
        }

        Get-DockerImage @Parameters
    }
}
