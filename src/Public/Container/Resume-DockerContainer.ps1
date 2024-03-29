using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerContainer.psm1

function Resume-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerContainer])]
    [Alias('rudc')]
    param(
        [Parameter(Position = 0, Mandatory, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Id')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [Alias('Container', 'ContainerId')]
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

        # Ensure we have containers to process
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
                "Unpausing all processes in $ContainerIdentification.",
                "Unpause all processes in $ContainerIdentification?",
                "docker $ArgumentList"
            )) {
            return
        }

        Invoke-Docker unpause $Containers.Id -Context $Context | ForEach-Object {
            if ($PassThru) {
                Get-DockerContainerInternal -Id $_ -Context $Context
            }
        }
    }
}
