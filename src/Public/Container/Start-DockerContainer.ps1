using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerContainer.psm1

function Start-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerContainer])]
    [Alias('sadc')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name+Interactive')]
        [Alias('ContainerName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id+Interactive')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Id,

        # Maps to the --attach and --interactive parameters. (In the context of PowerShell, it does not make
        # sense to stream output to the console without attaching to the container.)
        [Parameter(Mandatory, ParameterSetName = 'Id+Interactive')]
        [Parameter(Mandatory, ParameterSetName = 'Name+Interactive')]
        [switch]
        $Interactive,

        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'Name')]
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
            'container'
            'start'
            if ($Interactive) { '--attach'; '--interactive' }
            $Containers.Id
        )

        $ShouldProcessTarget = if ($Containers.Count -eq 1) { "container '$($Containers.Id)' ($($Containers.Names))" } else { "$($Containers.Count) containers" }
        if (!$PSCmdlet.ShouldProcess(
                "Starting $ShouldProcessTarget.",
                "Start $ShouldProcessTarget?",
                "docker $ArgumentList"
            )) {
            return
        }

        Invoke-Docker -ArgumentList $ArgumentList -Context $Context | ForEach-Object {
            if ($PassThru) {
                Get-DockerContainerInternal -Id $_ -Context $Context
            }
        }
    }
}