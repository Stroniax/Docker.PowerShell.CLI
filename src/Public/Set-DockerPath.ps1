using namespace System.Management.Automation

function Set-DockerPath {
    [CmdletBinding(
        DefaultParameterSetName = 'LiteralPath',
        RemotingCapability = [RemotingCapability]::None,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Path')]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'LiteralPath')]
        [Alias('PSPath')]
        [string]
        $LiteralPath,

        [Parameter()]
        [switch]
        $PassThru
    )
    process {
        if ($Path) {
            $ActualPath = Resolve-Path $Path -ErrorAction Stop
        }
        else {
            $ActualPath = Resolve-Path $LiteralPath -ErrorAction Stop
        }

        $ProviderPath = $ActualPath.ProviderPath

        # Test if the path is docker
        Write-Debug "$ProviderPath --version"
        $DockerVersionOutput = & $ProviderPath --version

        if ($DockerVersionOutput -notmatch 'Docker version') {
            $exn = [ArgumentException]'The provided path is not a valid docker executable.'
            $err = [ErrorRecord]::new(
                $exn,
                'InvalidDockerPath',
                [ErrorCategory]::InvalidArgument,
                $ActualPath
            )
            $err.ErrorDetails = "The provided path '$ProviderPath' is not a valid docker executable."
            $PSCmdlet.ThrowTerminatingError($err)
            return
        }

        if (!$PSCmdlet.ShouldProcess(
                "Setting docker executable to '$ProviderPath' for the 'Docker.PowerShell.CLI' module.",
                "Use the docker executable at '$ProviderPath' for the 'Docker.PowerShell.CLI' module?",
                'Set-DockerPath'
            )) {
            return
        }
        
        # Set the $Docker variable which contains the path to the docker executable
        Set-Variable -Name Docker -Value $ProviderPath -Scope 1

        if ($PassThru) {
            Get-Item -LiteralPath $ActualPath.Path
        }
    }
}