using namespace System.Management.Automation
using module ../../src/Classes/DockerContainerCompleter.psm1
using module ../../src/Classes/DockerContextCompleter.psm1

function Restart-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [Alias('rtdc')]
    param(
        [Parameter(Position = 0, Mandatory, ParameterSetName = 'Name')]
        [Alias('ContainerName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Id')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [int]
        $TimeoutSeconds,

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
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -Context $Context -EscapeId

        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose 'No containers to process.'
            return
        }

        $ArgumentList = @(
            'container',
            'restart'
        )
        if ($TimeoutSeconds) {
            $ArgumentList += '--time'
            $ArgumentList += $TimeoutSeconds
        }
        $ArgumentList += $Containers.Id

        $ShouldProcessTarget = if ($Containers.Count -eq 1) { "container '$($Containers.Id)' ($($Containers.Names))" } else { "$($Containers.Count) containers" }
        if (!$PSCmdlet.ShouldProcess(
                "Restarting $ShouldProcessTarget.",
                "Restart $ShouldProcessTarget?",
                "docker $ArgumentList")) {
            return
        }

        # Stream results as they become available
        Invoke-Docker $ArgumentList -Context $Context | ForEach-Object {
            if ($PassThru) {
                Get-DockerContainerInternal -Id $_ -Context $Context
            }
        }
    }
}
