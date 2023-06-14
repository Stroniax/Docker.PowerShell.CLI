using namespace System.Management.Automation
using namespace System.Collections.Generic
using module ../../Classes/DockerImageCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Get-DockerImage {
    [CmdletBinding(
        DefaultParameterSetName = 'Search',
        PositionalBinding = $false,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [OutputType('Docker.Image')]
    [Alias('gdi')]
    param(
        [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Search')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'FullName')]
        [SupportsWildcards()]
        [Alias('Reference')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $FullName,

        [Parameter(Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('RepositoryName', 'ImageName')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $Name,

        [Parameter(Position = 1, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $Tag,

        [Parameter(ParameterSetName = 'Id')]
        [SupportsWildcards()]
        [Alias('ImageId')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [Alias('All')]
        [switch]$IncludeIntermediateImages,

        [Parameter()]
        [Alias('Untagged')]
        [switch]
        $Dangling,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        [List[string]]$ArgumentList = @(
            'image',
            'list',
            '--no-trunc'
            '--format'
            '{{ json . }}'
            if ($IncludeIntermediateImages) { '--all' }
            if ($Dangling) { '--filter'; 'dangling=true' }
        )

        # Track unmatched filters
        $ReportNotMatched = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

        foreach ($_ in $InputObject) {
            if ($_ -match '^[0-9a-f]{12}$' -or $_ -match '^sha256:[0-9a-f]64$') {
                $Id += $_
            }
            elseif ($_.Contains(':')) {
                $FullName += $_
            }
            else {
                $Name += $_
            }
        }

        foreach ($i in $FullName) {
            # it could be an id, probably of a nameless image
            if (!$i.StartsWith('sha256:')) {
                $ArgumentList += '--filter'
                $ArgumentList += "reference=$i"
            }
            if (![WildcardPattern]::ContainsWildcardCharacters($i)) {
                [void]$ReportNotMatched.Add($i)
            }
        }
        if ($Tag.Count -in @(0, 1) -and $Name.Count -gt 0) {
            $TagPattern = if ($Tag) { $Tag } else { '*' }
            $Name | ForEach-Object {
                $ArgumentList += '--filter'
                $ArgumentList += "reference=${_}:$TagPattern"
            }
        }

        foreach ($i in $Name) {
            if (![WildcardPattern]::ContainsWildcardCharacters($i)) {
                [void]$ReportNotMatched.Add($i)
            }
        }

        for ($i = 0; $i -lt $Id.Length; $i++) {
            # a 12-character hex string is the default displayed image id
            # is not the actual image's id but a pattern for it: handle
            # such appropriately

            if ($id[$i].Length -eq 12 -and ![WildcardPattern]::ContainsWildcardCharacters($id[$i])) {
                $id[$i] = "sha256:$($id[$i])*"
            }

            # Track unmatched filters
            if (![WildcardPattern]::ContainsWildcardCharacters($id[$i])) {
                [void]$ReportNotMatched.Add($id[$i])
            }
        }

        Invoke-Docker $ArgumentList -Context $Context | ForEach-Object {
            $pso = $_ | ConvertFrom-Json

            if (-not (Test-MultipleWildcard -WildcardPattern $Name -ActualValue $pso.Repository)) {
                return
            }

            if (-not (Test-MultipleWildcard -WildcardPattern $Tag -ActualValue $pso.Tag)) {
                return
            }

            if (-not (Test-MultipleWildcard -WildcardPattern $Id -ActualValue $pso.Id)) {
                return
            }

            $ImageFullName = if ($pso.Repository -eq '<none>') { $pso.Id } else { "$($pso.Repository):$($pso.Tag)" }
            if (-not (Test-MultipleWildcard -WildcardPattern $FullName -ActualValue $ImageFullName)) {
                return
            }

            [void]$ReportNotMatched.Remove($pso.Id)
            [void]$ReportNotMatched.Remove($pso.Repository)
            [void]$ReportNotMatched.Remove(($pso.Repository + ':' + $pso.Tag))

            $pso.PSObject.Members.Add([PSNoteProperty]::new('RawLabels', $pso.Labels))
            $pso.PSObject.Members.Remove('Labels')
            $pso.PSObject.Members.Add([PSNoteProperty]::new('RawMounts', $pso.Mounts))
            $pso.PSObject.Members.Remove('Mounts')
            $pso.PSObject.Members.Add([PSNoteProperty]::new('Context', $Context))
            $pso.PSTypeNames.Insert(0, 'Docker.Image')

            $pso
        }

        $UnmatchedMember = $PSCmdlet.ParameterSetName
        foreach ($Unmatched in $ReportNotMatched) {
            Write-Error "No image found for $UnmatchedMember '$Unmatched'." -Category ObjectNotFound -TargetObject $Unmatched -ErrorId 'ImageNotFound'
        }
    }
}
