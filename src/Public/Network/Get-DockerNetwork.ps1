using module ../../Classes/DockerNetworkCompleter.psm1
using module ../../../Docker.PowerShell.CLI.psm1
using namespace System.Management.Automation
using namespace System.Collections.Generic

class DockerNetwork {

    hidden [psobject]$PSSourceValue

    [string]$Id

    [string]$Name

    [string]$Driver

    [string]$Scope

    [string[]]$Labels

    [DateTimeOffset]$CreatedAt

    [string] ToString() {
        return $this.Id
    }

    DockerNetwork([psobject]$deserializedJson) {
        $this.PSSourceValue = $deserializedJson
        $this.PSObject.TypeNames.Insert(0, 'Docker.Network')
        $this.PSObject.TypeNames.Insert(1, 'Docker.PowerShell.CLI.Network')

        foreach ($Property in $deserializedJson.PSObject.Properties) {
            if ($Property -is [psnoteproperty]) {
                # Handle special property values
                if ($Property.Name -eq 'Driver' -and $Property.Value -eq 'null') {
                    $this.Driver = $null
                    continue
                }
                if ($Property.Name -eq 'Labels') {
                    $this.Labels = $Property.Value -split ','
                    continue
                }
                if ($Property.Name -eq 'CreatedAt') {
                    $this.CreatedAt = [DateTimeOffset]::Parse($Property.Value.Substring(0, 35))
                    continue
                }

                # Handle normal property values
                if ($this.PSObject.Properties[$Property.Name]) {
                    $this.($Property.Name) = $Property.Value
                }
                else {
                    $Duplicate = $Property.Copy()
                    $asBool = $false
                    if ([bool]::TryParse($Duplicate.Value, [ref]$asBool)) {
                        $Duplicate.Value = $asBool
                    }
                    $this.PSObject.Properties.Add($Duplicate)
                }
            }
            else {
                Write-Warning "Unsupported property type '$($Property.GetType().Name)' for property '$($Property.Name)'. Contact the module author."
            }
        }
    }
}

function Get-DockerNetwork {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::None,
        PositionalBinding = $false
    )]
    [OutputType([DockerNetwork])]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [SupportsWildcards()]
        [Alias('NetworkId')]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Driver,

        [Parameter()]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [string[]]
        $Scope,

        [Parameter()]
        [ValidateSet('custom', 'builtin')]
        [string[]]
        $Type,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $ReportNotMatched = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

        foreach ($i in $Id) {
            if (![WildcardPattern]::ContainsWildcardCharacters($i)) {
                [void]$ReportNotMatched.Add($i)
            }
        }
        foreach ($n in $Name) {
            if (![WildcardPattern]::ContainsWildcardCharacters($n)) {
                [void]$ReportNotMatched.Add($n)
            }
        }

        $ArgumentList = @(
            'network'
            'list'
            '--format'
            'json'
            '--no-trunc'
            foreach ($i in $Id | ConvertTo-DockerWildcard) {
                '--filter'
                "id=$i"
            }
            foreach ($n in $Name | ConvertTo-DockerWildcard) {
                '--filter'
                "name=$n"
            }
            foreach ($d in $Driver) {
                '--filter'
                "driver=$d"
            }
            foreach ($s in $Scope) {
                '--filter'
                "scope=$s"
            }
            foreach ($t in $Type) {
                '--filter'
                "type=$t"
            }
        )

        Invoke-Docker $ArgumentList -Context $Context | ConvertFrom-Json | ForEach-Object {
            $Network = [DockerNetwork]::new($_)
            if (-not (Test-MultipleWildcard -WildcardPattern $Name -ActualValue $Network.Name)) {
                return
            }
            if (-not (Test-MultipleWildcard -WildcardPattern $Id -ActualValue $Network.Id)) {
                return
            }

            [void]$ReportNotMatched.Remove($Network.Id)
            [void]$ReportNotMatched.Remove($Network.Name)

            $Network
        }

        foreach ($NotMatched in $ReportNotMatched) {
            $Exception = [ItemNotFoundException]::new(
                "The docker network was not found."
            )
            $ErrorRecord = [ErrorRecord]::new(
                $Exception,
                'NetworkNotFound',
                [ErrorCategory]::ObjectNotFound,
                $NotMatched
            )
            $ErrorRecord.ErrorDetails = "No network found with the $($PSCmdlet.ParameterSetName) '$NotMatched'."
            Write-Error -ErrorRecord $ErrorRecord
        }
    }
}