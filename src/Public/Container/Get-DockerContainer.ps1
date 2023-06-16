using namespace System.Collections.Generic
using namespace System.Management.Automation
using module ../../Classes/DockerContainer.psm1
using module ../../Classes/DockerContainerCompleter.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1
using module ../../Classes/LowerCaseTransformation.psm1

function Get-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    [Alias('gdc')]
    [OutputType([DockerContainer])]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [Alias('ContainerName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [LowerCaseTransformation()]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [Alias('Container', 'ContainerId')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [LowerCaseTransformation()]
        [string[]]
        $Id,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string[]]
        $Label,

        [Parameter()]
        [ValidateSet('running', 'created', 'restarting', 'removing', 'paused', 'exited', 'dead')]
        [Alias('Status')]
        [LowerCaseTransformation()]
        [string[]]
        $State,

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

        foreach ($s in $State) {
            $cl.Add('--filter')
            $cl.Add("status=$s")
        }

        foreach ($n in $Name) {
            if (![WildcardPattern]::ContainsWildcardCharacters($n)) {
                [void]$ReportNotMatched.Add($n)
                
                $cl.Add('--filter')
                $cl.Add("name=$n")

                continue
            }

            # since --filter x=y matches ANY filter x, we can just add the longest part
            # here (least likely to match other filters) and provide specific PowerShell
            # filtering later
            $filter = $n -split '[*?[\]]' | Sort-Object -Property Length -Descending | Select-Object -First 1
            $cl.Add('--filter')
            $cl.Add("name=$filter")
        }

        foreach ($l in $Label) {
            # Label filter does not support partial match
            if (![WildcardPattern]::ContainsWildcardCharacters($l)) {
                $cl.Add('--filter')
                $cl.Add("label=$w")
            }
        }

        $IdFilter = [List[string]]::new()
        $UseIdFilter = $true
        foreach ($i in $Id) {
            if (![WildcardPattern]::ContainsWildcardCharacters($i)) {
                [void]$ReportNotMatched.Add($i)
                $IdFilter.Add($i)
                continue
            }
            if (!$UseIdFilter) {
                continue
            }
            # filter id=x only matches 'x...', not '...x'. We can therefore only
            # filter from the beginning of the string to the first wildcard character
            $FilterParts = $i -split '[*?[\]]'
            if ($FilterParts[0].Length -eq 0) {
                $UseIdFilter = $false
                continue
            }
            else {
                $IdFilter.Add($FilterParts[0])
            }
        }

        if ($UseIdFilter) {
            foreach ($i in $IdFilter) {
                $cl.Add('--filter')
                $cl.Add("id=$i")
            }
        }


        Invoke-Docker -ArgumentList $cl -Context $Context | ForEach-Object {
            [DockerContainer]$pso = $_ | ConvertFrom-Json
            $pso.PSObject.Members.Add([PSNoteProperty]::new('PSDockerContext', $Context))

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
            $ErrorId = if ($Id) { 'Id' } else { 'Name' }
            $WriteError = @{
                Message      = "The docker container '$r' was not found."
                Exception    = [ItemNotFoundException]'The docker container was not found.'
                Category     = 'ObjectNotFound'
                ErrorId      = "Container${ErrorId}NotFound"
                TargetObject = $r
            }
            Write-Error @WriteError
        }
    }
}