using namespace System.Management.Automation
using module ../../Classes/DockerContextCompleter.psm1

function Import-DockerImage {
    [CmdletBinding(
        DefaultParameterSetName = 'LiteralPath',
        SupportsShouldProcess,
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        ConfirmImpact = [ConfirmImpact]::Low,
        PositionalBinding = $false
    )]
    [OutputType('Docker.Image')]
    [Alias('ipdi')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Path')]
        [SupportsWildcards()]
        [Alias('FilePath')]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'LiteralPath')]
        [Alias('PSPath')]
        [string]
        $LiteralPath,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        if ($Path) {
            $FullPath = Resolve-Path -Path $Path
        }
        else {
            $FullPath = Resolve-Path -LiteralPath $LiteralPath
        }

        if (!$?) {
            return
        }

        # ShouldProcess
        if (!$PSCmdlet.ShouldProcess(
                "Importing image from '$FullPath'.",
                "Import image from '$FullPath'?",
                "docker image load --input '$FullPath'"
            )) {
            return
        }

        $ArgumentList = @(
            'image'
            'load'
            '--quiet'
            '--input'
            $FullPath
        )

        $Output = Invoke-Docker -ArgumentList $ArgumentList -Context $Context

        if ($? -and $PassThru) {
            $Id = $Output.Replace('Loaded image ID: ', '')
            Get-DockerImage -Id $Id
        }
    }
}
