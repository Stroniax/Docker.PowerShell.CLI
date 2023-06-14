using namespace System.Management.Automation
using namespace System.Collections.Generic
using module ../../Classes/DockerImageCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Publish-DockerImage {
    [CmdletBinding(
        DefaultParameterSetName = 'FullName',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType('Docker.Image', ParameterSetName = 'FullName')]
    [OutputType('Docker.PowerShell.CLI.DockerPushJob', ParameterSetName = 'FullNameJob')]
    [Alias('pbdi')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'FullName')]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'FullNameJob')]
        [Alias('Reference')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $FullName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Name')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameJob')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'AllTags')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'AllTagsJob')]
        [Alias('ImageName', 'RepositoryName')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1, ParameterSetName = 'Name')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1, ParameterSetName = 'NameJob')]
        [ValidateScript({ $_ -notmatch '[:@ ]' })]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Tag,

        [Parameter(Mandatory, ParameterSetName = 'AllTags')]
        [Parameter(Mandatory, ParameterSetName = 'AllTagsJob')]
        [switch]
        $AllTags,

        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Parameter(Mandatory, ParameterSetName = 'IdJob')]
        [Alias('ImageId')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Id,

        [Parameter()]
        [switch]
        $DisableContentTrust,

        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'AllTags')]
        [Parameter(ParameterSetName = 'FullName')]
        [Parameter(ParameterSetName = 'Name')]
        [switch]
        $PassThru,

        [Parameter(Mandatory, ParameterSetName = 'NameJob')]
        [Parameter(Mandatory, ParameterSetName = 'AllTagsJob')]
        [Parameter(Mandatory, ParameterSetName = 'FullNameJob')]
        [Parameter(Mandatory, ParameterSetName = 'IdJob')]
        [switch]
        $AsJob,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    begin {
        $HasPublishedFullName = [HashSet[string]]::new()
    }
    process {
        $ArgumentList = @(
            'image'
            'push'
            if ($DisableContentTrust) { '--disable-content-trust' }
            if ($AllTags) { '--all-tags' }
        )

        if ($Name -and $Tag) {
            $FullName = "${Name}:$Tag"
        }
        elseif ($Name) {
            $FullName = $Name
        }
        if ($Id) {
            $FullName = Get-DockerImageInternal -Id $Id -Context $Context -EscapeId | ForEach-Object FullName
        }

        foreach ($f in $FullName) {
            # Only publish once, in case of duplicate in pipeline
            if ($HasPublishedFullName.Contains($f)) {
                Write-Warning "Image '$f' has already just been published."
                continue
            }
            else {
                [void]$HasPublishedFullName.Add($f)
            }

            # Make sure the image exists
            if ($AllTags) {
                $Image = Get-DockerImageInternal -Name $f -Context $Context
            }
            else {
                $Image = Get-DockerImageInternal -FullName $f -Context $Context
            }
            if (!$? -or !$Image) {
                continue
            }

            if (!$PSCmdlet.ShouldProcess(
                    "Publishing image '$f'.",
                    "Publish image '$f'?",
                    "docker $ArgumentList $f"
                )) {
                continue
            }

            $FullArgumentList = @(
                $ArgumentList
                $f
            )

            if ($AsJob) {
                Assert-DockerPushJob
                $Job = [Docker.PowerShell.CLI.DockerPushJob]::new(
                    $MyInvocation.Line,
                    $FullArgumentList
                )

                $PSCmdlet.JobRepository.Add($Job)
                $Job
            }
            else {
                Invoke-Docker $FullArgumentList -Context $Context | Write-Debug
                if ($PassThru) {
                    $Image
                }
            }
        }
    }
}