using namespace System.Management.Automation
using module ../../Classes/EmptyStringArgumentCompleter.psm1
using module ../../Classes/DockerContext.psm1

function Import-DockerContext {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerContext])]
    [Alias('ipdcx')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_.+-]+$')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, Position = 1, ParameterSetName = 'Path')]
        [string]
        $Path,

        [Parameter(Mandatory, Position = 1, ParameterSetName = 'LiteralPath', ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [string]
        $LiteralPath,

        [Parameter()]
        [switch]
        $PassThru
    )
    process {
        # Ensure the path exists
        if ($Path) {
            $ResolvedPath = Resolve-Path -Path $Path -ErrorVariable hadErrors
        }
        else {
            $ResolvedPath = Resolve-Path -LiteralPath $LiteralPath -ErrorVariable hadErrors
        }

        if ($hadErrors) {
            return
        }

        # Ensure the context does not already exist
        $ExistingContexts = Invoke-Docker context list --format '{{ .Name }}'
        if ($ExistingContexts -contains $Name) {
            $WriteError = @{
                Exception         = [InvalidOperationException]::new('A context with the provided name already exists.')
                Message           = "A context with the name '$Name' already exists."
                Category          = [ErrorCategory]::InvalidArgument
                TargetObject      = $Name
                ErrorId           = 'ContextExists'
                RecommendedAction = 'Provide a different name, or remove the existing context and try again.'
            }
            Write-Error @WriteError
            return
        }

        $ArgumentList = @(
            'context'
            'import'
            $Name
            $ResolvedPath.ProviderPath
        )

        if (!$PSCmdlet.ShouldProcess(
            "Importing docker context '$Name' from file '$ResolvedPath'.",
            "Import docker context '$Name' from file '$ResolvedPath'?",
            "docker $ArgumentList"
        )) {
            return
        }

        Invoke-Docker -ArgumentList $ArgumentList 2>&1 | ForEach-Object -ErrorVariable hadErrors -Process {
            if ($_ -isnot [ErrorRecord] -or $_ -like 'Successfully imported context *') {
                Write-Debug $_
            }
            else {
                Write-Error -ErrorRecord $_
            }
        }

        if (!$hadErrors -and $PassThru) {
            Get-DockerContext -Name $Name
        }
    }
}