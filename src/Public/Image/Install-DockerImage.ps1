using namespace System.Management.Automation
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1

function Install-DockerImage {
    [CmdletBinding(
        DefaultParameterSetName = 'FullName',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType('Docker.Image', ParameterSetName = 'FullName', 'NameTag', 'NameAllTags', 'NameDigest')]
    [OutputType('Docker.PowerShell.CLI.DockerPullJob', ParameterSetName = 'FullNameJob', 'NameTagJob', 'NameAllTagsJob', 'NameDigestJob')]
    [Alias('isdi')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'FullName')]
        [Parameter(Position = 0, ParameterSetName = 'FullNameJob')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string[]]
        $FullName,
        
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameTag')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameAllTags')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameDigest')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameTagJob')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameAllTagsJob')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameDigestJob')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameTag')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameTagJob')]
        [ValidateScript({ $_ -notmatch '[:@ ]' })]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Tag,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameDigest')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameDigestJob')]
        [ValidateScript({ $_ -match '^(sha256:)?[0-9a-f]+$' })]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Digest,

        [Parameter(Mandatory, ParameterSetName = 'NameAllTags')]
        [Parameter(Mandatory, ParameterSetName = 'NameAllTagsJob')]
        [switch]
        $AllTags,

        [Parameter()]
        [switch]
        $DisableContentTrust,

        [Parameter()]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Platform,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter(Mandatory, ParameterSetName = 'FullNameJob')]
        [Parameter(Mandatory, ParameterSetName = 'NameTagJob')]
        [Parameter(Mandatory, ParameterSetName = 'NameAllTagsJob')]
        [Parameter(Mandatory, ParameterSetName = 'NameDigestJob')]
        [switch]
        $AsJob,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {

        $ArgumentList = @(
            'image'
            'pull'
            if ($DisableContentTrust) { '--disable-content-trust' }
            if ($Platform) { '--platform'; $Platform }
        )

        if ($Name -and $Tag) {
            $FullName = "${Name}:$Tag"
        }
        if ($Name -and $Digest) {
            $FullName = "$Name@$Digest"
        }

        foreach ($f in $FullName) {
            if (!$PSCmdlet.ShouldProcess(
                    "Installing image '$f'.",
                    "Install image '$f'?",
                    "docker $ArgumentList $f"
                )) {
                continue
            }
            $FullArgumentList = @(
                $ArgumentList
                $f
            )

            if ($AsJob) {
                Assert-DockerPullJob
                $Job = [Docker.PowerShell.CLI.DockerPullJob]::new(
                    $MyInvocation.Line,
                    $FullArgumentList
                )

                $PSCmdlet.JobRepository.Add($Job)
                $Job
            }
            else {
                Invoke-Docker $FullArgumentList -Context $Context | Tee-Object -Variable DockerOutput | Write-Debug

                if ($? -and $PassThru) {
                    Get-DockerImage -FullName $DockerOutput[-1]
                }
            }
        }
    }
}
