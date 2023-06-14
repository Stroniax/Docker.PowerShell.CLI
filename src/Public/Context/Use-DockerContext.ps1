using namespace System.Management.Automation
using module ../../Classes/ValidateDockerContext.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerContext.psm1
using module ../../Classes/EmptyScriptBlockArgumentCompleter.psm1

function Use-DockerContext {
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    [OutputType([DockerContext], ParameterSetName = 'Default')]
    [OutputType([System.Management.Automation.Internal.AutomationNull], ParameterSetName = 'ScriptBlock')]
    [Alias('udcx')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('ContextName')]
        [ValidateDockerContext()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, Position = 1, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNull()]
        [ArgumentCompleter([EmptyScriptBlockArgumentCompleter])]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(ParameterSetName = 'Default')]
        [switch]
        $PassThru
    )
    process {
        if ($ScriptBlock) {
            $Context = Invoke-Docker context show
            Invoke-Docker context use $Name | Write-Debug
            try {
                & $ScriptBlock
            }
            finally {
                Invoke-Docker context use $Context
            }
        }
        else {
            Invoke-Docker context use $Name | Write-Debug
            if ($? -and $PassThru) {
                Get-DockerContext -Name $Name
            }
        }
    }
}