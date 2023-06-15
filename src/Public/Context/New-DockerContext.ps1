using namespace System.Management.Automation
using module ../../Classes/DockerContext.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1

function New-DockerContext {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess = $true,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerContext])]
    [Alias('ndcx')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [Alias('DockerEndpoint', 'Host')]
        [ValidatePattern('^[^,]+$')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $DockerHost,

        [Parameter()]
        [Alias('swarm', 'kubernetes', 'all')]
        [string]
        $DefaultStackOrchestrator,

        [Parameter()]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Description
    )
    process {
        $ArgumentList = @(
            'context'
            'create'
            $Name
            if ($DefaultStackOrchestrator) { '--default-stack-orchestrator'; $DefaultStackOrchestrator }
            if ($Description) { '--description'; $Description }
            if ($DockerHost) { '--docker'; "host=$DockerHost" }
            if ($Kubernetes) { '--kubernetes'; $Kubernetes }
        )

        if ($PSCmdlet.ShouldProcess(
                "Creating docker context '$Name' with host '$($DockerHost)'.",
                "Create docker context '$Name' with host '$($DockerHost)'?",
                "docker $ArgumentList"
            )) {
            Invoke-Docker -ArgumentList $ArgumentList 2>&1 | Write-Debug
            if ($?) {
                Get-DockerContext -Name $Name
            }
        }
    }
}