using namespace System.Management.Automation
using module ../../Classes/ValidateDockerContext.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/DockerContext.psm1
using module ../../Classes/EmptyScriptBlockArgumentCompleter.psm1
using module ../../Classes/LowerCaseTransformation.psm1

function Test-DockerContext {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]
        $Name
    )
    process {
        $Context = Invoke-Docker context list --format '{{ .Name }}'

        $Context -contains $Name
    }
}

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
        [LowerCaseTransformation()]
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
        if (-not (Test-DockerContext $Name)) {
            $WriteError = @{
                Message      = "No context found with the specified name '$Name'."
                Exception    = [ItemNotFoundException]'No context found with the specified name.'
                Category     = 'ObjectNotFound'
                ErrorId      = 'ContextNameNotFound'
                TargetObject = $Name
                ErrorAction  = 'Stop'
            }
            Write-Error @WriteError
            return
        }

        # docker context use $Name writes the second line:
        # Current context is now "$Name"
        # to the error stream, so we can ignore it by redirecting it to the debug stream.
        if ($ScriptBlock) {
            $Context = Invoke-Docker context show
            Invoke-Docker context use $Name 2>&1 | Write-Debug
            try {
                Invoke-Command $ScriptBlock -NoNewScope
            }
            finally {
                Invoke-Docker context use $Context | Write-Debug
            }
        }
        else {
            Invoke-Docker context use $Name 2>&1 | Write-Debug
            if ($? -and $PassThru) {
                Get-DockerContext -Name $Name
            }
        }
    }
}