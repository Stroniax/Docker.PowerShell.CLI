using namespace System.Collections;
using namespace System.Diagnostics;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.Management.Automation.Language;
using module src/Classes/DockerContainerCompleter.psm1
using module src/Classes/DockerContextCompleter.psm1
using module src/Classes/DockerImageCompleter.psm1
using module src/Classes/ValidateDockerContext.psm1

#region Classes

#endregion Classes

#region Helper Functions

#endregion Helper Functions

#region Docker Container

#endregion Docker Container

#region Docker Image

#endregion Docker Image

#region Docker Version

#endregion

#region Docker Context
function Get-DockerContext {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    [Alias('gdcx')]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name')]
        [ArgumentCompleter([DockerContextCompleter])]
        [string[]]
        $Context
    )
    process {
        $ReportNotMatched = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($i in $Context) {
            if (![WildcardPattern]::ContainsWildcardCharacters($i)) {
                [void]$ReportNotMatched.Add($i)
            }
        }

        Invoke-Docker context list --format '{{ json . }}' | ForEach-Object {
            $pso = $_ | ConvertFrom-Json

            if (-not (Test-MultipleWildcard -WildcardPattern $Context -ActualValue $pso.Name)) {
                return
            }

            $ReportNotMatched.Remove($pso.Name)
            $pso.PSTypeNames.Insert(0, 'Docker.Context')
            $pso
        }

        foreach ($Unmatched in $ReportNotMatched) {
            Write-Error "No context found with name '$Unmatched'." -Category ObjectNotFound -ErrorId 'ContextNotFound' -TargetObject $Unmatched
        }
    }
}

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
#endregion Docker Context

#region Miscellaneous Commands
function Invoke-DockerCommand {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $ContainerName,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $ArgumentList,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    $PassArgumentList = [List[string]]::new($ArgumentList)
    $PassArgumentList.Insert(0, 'exec')
    $PassArgumentList.Insert(1, $ContainerName)
    Invoke-Docker $PassArgumentList -Context $Context
}
#endregion Miscellaneous Commands
