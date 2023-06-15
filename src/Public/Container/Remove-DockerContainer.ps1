using namespace System.Collections.Generic
using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Remove-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [Alias('ContainerName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Id,

        [Parameter(Mandatory, ParameterSetName = 'Prune')]
        [Alias('Unused', 'Prune')]
        [switch]
        $StoppedContainers,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        if ($StoppedContainers) {
            $ArgumentList = @(
                'container'
                'prune'
                if ($Force) { '--force' }
            )
            if ($PSCmdlet.ShouldProcess(
                    'Removing stopped containers.',
                    'Remove stopped containers?',
                    "docker $ArgumentList")) {
                Invoke-Docker -ArgumentList $ArgumentList -Context $Context | Out-Null
            }
            return
        }
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -Context $Context -EscapeId

        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose 'No containers to process.'
            return
        }

        $ArgumentList = @(
            'container'
            'rm'
            $Containers.Id
            if ($Force) { '--force' }
        )

        $ShouldProcessTarget = if ($Containers.Count -eq 1) {
            "container '$($Containers.Id)' ($($Containers.Names))"
        }
        else {
            "$($Containers.Count) containers"
        }

        if (!$PSCmdlet.ShouldProcess(
                "Removing $ShouldProcessTarget.",
                "Remove $ShouldProcessTarget?",
                "docker $ArgumentList")) {
            return;
        }
        Invoke-Docker -ArgumentList $ArgumentList -Context $Context | Write-Debug
    }
}
