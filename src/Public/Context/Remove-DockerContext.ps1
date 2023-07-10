using namespace System.Collections.Generic
using namespace System.Management.Automation
using module ../../Classes/DockerContextCompleter.psm1

function Remove-DockerContext {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([System.Management.Automation.Internal.AutomationNull])]
    [Alias('rdcx')]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [Alias('ContextName')]
        [ArgumentCompleter([DockerContextCompleter])]
        [string[]]
        $Name
    )
    begin {
        $RemoveContexts = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    }
    process {
        $Contexts = Get-DockerContext -Name $Name

        foreach ($Context in $Contexts) {
            if ($Context.Current) {
                $WriteError = @{
                    Message           = "The docker context '$($Context.Name)' cannot be removed because it is currently in use."
                    Exception         = [InvalidOperationException]'The docker context cannot be removed because it is currently in use.'
                    RecommendedAction = 'Change the current docker context with ''Use-DockerContext'' and try again.'
                    TargetObject      = $Context
                    ErrorId           = 'ContextInUse'
                    Category          = 'ResourceBusy'
                }
                Write-Error @WriteError
                continue
            }

            if ($RemoveContexts.Contains($Context.Name)) {
                Write-Warning "Context '$($Context.Name)' is already being removed."
                continue
            }

            if ($PSCmdlet.ShouldProcess(
                    "Removing docker context '$($Context.Name)'.",
                    "Remove docker context '$($Context.Name)'?",
                    "docker context remove $($Context.Name)"
                )) {
                [void]$RemoveContexts.Add($Context.Name)
            }
        }

    }
    end {
        if ($RemoveContexts.Count -eq 0) {
            return
        }
        $ArgumentList = @(
            'context'
            'remove'
            $RemoveContexts
        )
        Invoke-Docker -ArgumentList $ArgumentList | Write-Debug
    }
}