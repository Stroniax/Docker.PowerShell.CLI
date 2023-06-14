using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerContainer.psm1

function Suspend-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerContainer])]
    [Alias('ssdc')]
    param(
        [Parameter(Position = 0, Mandatory, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Id')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Containers = Get-DockerContainerInternal -Id $Id -Name $Name -Context $Context -EscapeId

        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose 'No containers to process.'
            return
        }

        if ($Containers.Count -gt 1) {
            $ContainerIdentification = "$($Containers.Count) containers"
        }
        else {
            $ContainerIdentification = "container $($Containers.Id) ($($Containers.Names))"
        }

        if (!$PSCmdlet.ShouldProcess(
                "Pausing all processes in $ContainerIdentification.",
                "Pause all processes in $ContainerIdentification?",
                "docker $ArgumentList"
            )) {
            return
        }

        Invoke-Docker pause $Containers.Id -Context $Context | ForEach-Object {
            if ($PassThru) {
                Get-DockerContainerInternal -Id $_ -Context $Context
            }
        }
    }
}
