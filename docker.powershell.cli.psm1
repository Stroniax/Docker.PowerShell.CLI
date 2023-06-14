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
        $PassThru
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

        $Output = Invoke-Docker $ArgumentList

        if ($? -and $PassThru) {
            $Id = $Output.Replace('Loaded image ID: ', '')
            Get-DockerImage -Id $Id
        }
    }
}

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
        [string[]]
        $FullName,
        
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameTag')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameAllTags')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameDigest')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameTagJob')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameAllTagsJob')]
        [Parameter(ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'NameDigestJob')]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameTag')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameTagJob')]
        [ValidateScript({ $_ -notmatch '[:@ ]' })]
        [string]
        $Tag,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameDigest')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameDigestJob')]
        [ValidateScript({ $_ -match '^(sha256:)?[0-9a-f]+$' })]
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
#endregion Docker Image

#region Docker Version
function Get-DockerVersion {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [OutputType('Docker.DockerVersion')]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        Invoke-Docker version --format '{{ json . }}' -Context $Context | ForEach-Object {
            $pso = $_ | ConvertFrom-Json
            $pso.PSTypeNames.Insert(0, 'Docker.DockerVersion')
            $pso.Client.PSTypeNames.Insert(0, 'Docker.ClientVersion')
            $pso.Server.PSTypeNames.Insert(0, 'Docker.ServerVersion')
            $ModuleVersionInfo = [pscustomobject]@{
                Version    = $MyInvocation.MyCommand.Module.Version
                Prerelease = $MyInvocation.MyCommand.Module.PrivateData.PSData.Prerelease
                PSTypeName = 'Docker.ModuleVersion'
            }
            $pso.PSObject.Members.Add([PSNoteProperty]::new('Module', $ModuleVersionInfo))
            $pso
        }
    }
}
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
