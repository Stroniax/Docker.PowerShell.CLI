using module ../../Classes/DockerNetwork.psm1
using module ../../Classes/DockerNetworkCompleter.psm1
using module ../../Classes/DockerNetworkAuxAddressTransformation.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1
using module ../../Classes/EmptyIpAddressArgumentCompleter.psm1
using module ../../Classes/EmptyHashtableArgumentCompleter.psm1
using namespace System.Management.Automation
using namespace System.Collections.Generic

function New-DockerNetwork {
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        RemotingCapability = [RemotingCapability]::None,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerNetwork])]
    [Alias('ndn')]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Name,

        [Parameter()]
        # [ValidateSet('bridge', 'host', 'none', 'overlay', 'macvlan', 'ipvlan', 'null')]
        [ArgumentCompleter([DockerNetworkCompleter])]
        [PSDefaultValue(Value = 'bridge')]
        [string]
        $Driver,

        [Parameter()]
        [ValidateSet('local', 'global')]
        [string]
        $Scope,

        [Parameter()]
        [switch]
        $Attachable,

        [Parameter()]
        [switch]
        $Internal,

        [Parameter()]
        [switch]
        $IPv6,

        [Parameter()]
        [switch]
        $Ingress,

        # Driver-specific options
        [Parameter()]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string[]]
        $Options,

        [Parameter()]
        [ArgumentCompleter([EmptyIpAddressArgumentCompleter])]
        [ipaddress[]]
        $Gateway,

        # Subnet in CIDR format that represents a network segment
        [Parameter()]
        [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d+$')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string[]]
        $Subnet,

        [Parameter()]
        [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d+$')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string[]]
        $IpRange,

        [Parameter()]
        [Alias('AuxAddress')]
        [ArgumentCompleter([EmptyHashtableArgumentCompleter])]
        [DockerNetworkAuxAddressTransformation()]
        [Dictionary[string, HashSet[IPAddress]]]
        $AuxiliaryAddressMapping,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $ArgumentList = @(
            'network'
            'create'
            if ($Attachable) { '--attachable' }
            if ($AuxiliaryAddressMapping) {
                foreach ($k in $AuxiliaryAddressMapping.Keys) {
                    foreach ($v in $AuxiliaryAddressMapping[$k]) {
                        '--aux-address'
                        "$k=$v"
                    }
                }
            }
            if ($Driver) { '--driver'; $Driver.ToLower() }
            foreach ($g in $Gateway) {
                '--gateway'
                $g.ToString()
            }
            if ($Ingress) { '--ingress' }
            if ($Internal) { '--internal' }
            foreach ($i in $IpRange) {
                '--ip-range'
                $i
            }
            if ($IPv6) { '--ipv6' }
            if ($Options) {
                foreach ($o in $Options) {
                    '--opt'
                    $o
                }
            }
            if ($Scope) { '--scope'; $Scope.ToLower() }
            foreach ($s in $Subnet) { '--subnet'; $s }
            $Name
        )

        if (!$Driver) { $Driver = 'bridge' }
        if (!$PSCmdlet.ShouldProcess(
                "Creating docker network '$Name' with driver '$Driver'.",
                "Create docker network '$Name' with driver '$Driver'?",
                "docker $ArgumentList"
            )) {
            return
        }

        $Id = Invoke-Docker -ArgumentList $ArgumentList -Context $Context
        if ($?) {
            Get-DockerNetworkInternal -Id $Id -Context $Context
        }
    }
}