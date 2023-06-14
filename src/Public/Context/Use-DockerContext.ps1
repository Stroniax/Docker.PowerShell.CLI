using namespace System.Management.Automation
using module ../../Classes/ValidateDockerContext.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Use-DockerContext {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    [Alias('udcx')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('ContextName')]
        [ValidateDockerContext()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Name,

        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [ScriptBlock]
        $ScriptBlock
    )
    process {
        if ($ScriptBlock) {
            $Context = Invoke-Docker context show
            Invoke-Docker context use $Name | Out-Null
            try {
                & $ScriptBlock
            }
            finally {
                Invoke-Docker context use $Context
            }
        }
        else {
            Invoke-Docker context use $Name | Out-Null
        }
    }
}