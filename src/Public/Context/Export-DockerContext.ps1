using namespace System.Management.Automation
using module ../../Classes/DockerContextCompleter.psm1

function Export-DockerContext {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([System.IO.FileInfo])]
    [Alias('epdcx')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Path,

        [Parameter(DontShow)]
        [Obsolete('Deprecated by Docker. Ignored in newer versions of the CLI.')]
        [switch]
        $KubeConfig,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $PassThru
    )
    process {
        # Ensure the context exists
        $context = Get-DockerContext -Name $Name -ErrorVariable hadErrors
    
        if ($hadErrors) {
            return
        }

        if ($context.Count -eq 0) {
            # Wildcard name with no match
            $WriteError = @{
                Message      = "No context found with the specified name '$Name'."
                Exception    = [ItemNotFoundException]'No context found with the specified name.'
                Category     = 'ObjectNotFound'
                ErrorId      = 'ContextNameNotFound'
                TargetObject = $Name
            }
            Write-Error @WriteError
            return
        }
        if ($context.Count -gt 1) {
            $WriteError = @{
                Exception    = [System.Reflection.AmbiguousMatchException]::new('Multiple Docker contexts match the provided name.')
                ErrorId      = 'ContextNameAmbiguous'
                TargetObject = $Name
                Message      = "Multiple Docker contexts match the name '$Name'."
                Category     = [ErrorCategory]::InvalidArgument
            }
            Write-Error @WriteError
            return
        }

        # Ensure the path is valid
        $ResolvedPath = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        if (!$?) {
            return
        }
        $ParentPath = Split-Path -Path $ResolvedPath -Parent -ErrorAction Ignore
        if ($ParentPath -and !(Test-Path $ParentPath)) {
            $WriteError = @{
                Message      = "Could not find a part of the path '$ParentPath'."
                Exception    = [System.IO.DirectoryNotFoundException]::new('Could not find a part of the path.')
                ErrorId      = 'DirectoryNotFound'
                TargetObject = $ParentPath
                Category     = [ErrorCategory]::ObjectNotFound
            }
            Write-Error @WriteError
            return
        }

        # Ensure the file does not exist
        if (!$Force -and (Test-Path -LiteralPath $ResolvedPath)) {
            $WriteError = @{
                Message      = "The file '$ResolvedPath' already exists."
                Exception    = [System.IO.IOException]::new('The file already exists.')
                ErrorId      = 'FileExists'
                TargetObject = $ResolvedPath
                Category     = [ErrorCategory]::ResourceExists
            }
            Write-Error @WriteError
            return
        }

        $ArgumentList = @(
            'context'
            'export'
            if ($KubeConfig) {
                '--kubeconfig'
            }
            $Context.Name
            $ResolvedPath
        )

        # Confirm
        if (!$PSCmdlet.ShouldProcess(
                "Exporting docker context '$Name' to '$ResolvedPath'.",
                "Export docker context '$Name' to '$ResolvedPath'?",
                "docker $ArgumentList"
            )) {
            Remove-Item -LiteralPath $ResolvedPath -WhatIf -ErrorAction Ignore
            return
        }

        $WhatIfPreference = $false
        $ConfirmPreference = 'None'

        Remove-Item -LiteralPath $ResolvedPath -ErrorAction Ignore -WhatIf:$false -Confirm:$false

        # Export the context
        Invoke-Docker -ArgumentList $ArgumentList 2>&1 | ForEach-Object -ErrorVariable hadErrors -Process {
            if ($_ -isnot [ErrorRecord] -or $_ -like 'Written file *') {
                # Success message written to stderr
                Write-Debug $_
            }
            else {
                Write-Error -ErrorRecord $_
            }
        }

        if (!$hadErrors -and $PassThru) {
            Get-Item -LiteralPath $ResolvedPath
        }

    }
}