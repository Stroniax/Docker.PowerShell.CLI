using namespace System.Collections.Generic
using namespace System.Management.Automation
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1

function Get-DockerContainer {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [Alias('gdc')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [Alias('ContainerName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [Alias('Container', 'ContainerId')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Id,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $Label,

        [Parameter()]
        [ValidateSet('running', 'created', 'restarting', 'removing', 'paused', 'exited', 'dead')]
        [string[]]
        $Status,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        [List[string]]$cl = @(
            'container'
            'list'
            '--no-trunc'
            '--format'
            '{{ json . }}'
            '--all'
        )

        $ReportNotMatched = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

        foreach ($s in $Status) {
            $cl.Add('--filter')
            $cl.Add("status=$($s.ToLower())")
        }

        foreach ($n in $Name) {
            if (![WildcardPattern]::ContainsWildcardCharacters($n)) {
                [void]$ReportNotMatched.Add($n)
            }
            foreach ($w in ConvertTo-DockerWildcard $n) {
                $cl.Add('--filter')
                $cl.Add("name=$w")
            }
        }

        foreach ($l in $Label) {
            # Label filter does not support partial match
            if (![WildcardPattern]::ContainsWildcardCharacters($l)) {
                $cl.Add('--filter')
                $cl.Add("label=$w")
            }
        }

        foreach ($i in $Id) {
            if (![WildcardPattern]::ContainsWildcardCharacters($i)) {
                [void]$ReportNotMatched.Add($i)
            }
            foreach ($w in ConvertTo-DockerWildcard $i) {
                $cl.Add('--filter')
                $cl.Add("id=$w")
            }
        }


        Invoke-Docker $cl -Context $Context | ForEach-Object {
            $pso = $_ | ConvertFrom-Json
            $pso.PSObject.Members.Add([PSNoteProperty]::new('RawNames', $pso.Names))
            $pso.PSObject.Members.Remove('Names')
            $pso.PSObject.Members.Add([PSNoteProperty]::new('RawLabels', $pso.Labels))
            $pso.PSObject.Members.Remove('Labels')
            $pso.PSObject.Members.Add([PSNoteProperty]::new('Context', $Context))
            $pso.PSTypeNames.Insert(0, 'Docker.Container')

            if (-not (Test-MultipleWildcard -WildcardPattern $Name -ActualValue $pso.Names)) {
                return
            }
            if (-not (Test-MultipleWildcard -WildcardPattern $Id -ActualValue $pso.Id)) {
                return
            }
            if (-not (Test-MultipleWildcard -WildcardPattern $Label -ActualValue $pso.Labels)) {
                return
            }

            $ToRemove = if ($PSCmdlet.ParameterSetName -eq 'Id') { $pso.Id } else { $pso.Names }
            foreach ($removable in $ToRemove) {
                [void]$ReportNotMatched.Remove($removable)
            }

            $pso
        }

        foreach ($r in $ReportNotMatched) {
            Write-Error "No container found for '$r'." -Category ObjectNotFound -ErrorId 'ContainerNotFound' -TargetObject $r
        }
    }
}