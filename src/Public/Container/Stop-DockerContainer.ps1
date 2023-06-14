using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Stop-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [Alias('spdc')]
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
        [switch]
        $Force,

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

        $StopOrKill = if ($Force) { 'kill' } else { 'stop' }
        $Time = if (!$Force -and $TimeoutSeconds -gt 0) { '--time'; $TimeoutSeconds }
        $ArgumentList = @(
            'container'
            $StopOrKill
            $Time
        )
        $ArgumentList += $Containers.Id

        $ShouldProcessTarget = if ($Containers.Count -eq 1) { "container '$($Containers.Id)' ($($Containers.Names))" } else { "$($Containers.Count) containers" }
        if (!$PSCmdlet.ShouldProcess(
                "$StopOrKill $ShouldProcessTarget.",
                "$StopOrKill $ShouldProcessTarget?",
                "docker $ArgumentList"
            )) {
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
