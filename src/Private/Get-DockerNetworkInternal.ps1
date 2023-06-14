using module ../Classes/DockerNetwork.psm1
using namespace System.Management.Automation

function Get-DockerNetworkInternal {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::None,
        PositionalBinding = $false
    )]
    [OutputType([DockerNetwork])]
    param(
        [Parameter()]
        [string[]]
        $Name,

        [Parameter()]
        [string[]]
        $Id,

        [Parameter()]
        [switch]
        $EscapeId,

        [Parameter()]
        [string]
        $Context
    )
    process {
        $Parameters = @{}

        if ($Name) {
            $Parameters['Name'] = $Name
        }
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
        if ($Context) {
            $Parameters['Context'] = $Context
        }

        Get-DockerNetwork @Parameters
    }
}