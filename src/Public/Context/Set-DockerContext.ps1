using namespace System.Management.Automation
using module ../../Classes/DockerContext.psm1
using module ../../Classes/DockerContextCompleter.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1
using module ../../Classes/LowerCaseTransformation.psm1

function Set-DockerContext {
    [CmdletBinding(
        DefaultParameterSetName = 'DockerEndpoint',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess = $true,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerContext])]
    [Alias('sdcx')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_.+-]+$')]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'DockerEndpoint')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'DockerEndpoint')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $DockerHost,

        [Parameter(ParameterSetName = 'DockerEndpoint')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $CertificateAuthority,

        [Parameter(ParameterSetName = 'DockerEndpoint')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $TclCertificateFile,

        [Parameter(ParameterSetName = 'DockerEndpoint')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $TlsKeyFile,

        [Parameter(ParameterSetName = 'DockerEndpoint')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [switch]
        $SkipTlsVerify,

        [Parameter(ParameterSetName = 'KubernetesEndpoint')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $KubernetesConfigFile,

        [Parameter(ParameterSetName = 'KubernetesEndpoint')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $ContextOverride,

        [Parameter(ParameterSetName = 'KubernetesEndpoint')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
        [string]
        $NamespaceOverride,

        [Parameter()]
        [ValidateSet('swarm', 'kubernetes', 'all')]
        [LowerCaseTransformation()]
        [string]
        $DefaultStackOrchestrator,

        [Parameter()]
        [switch]
        $PassThru
    )
    process {
        $ArgumentList = [List[string]]::new()
        $ArgumentList.Add('context')

        $ExistingContexts = Invoke-Docker context list --format '{{ .Name }}'
        if ($ExistingContexts -contains $Name) {
            $ArgumentList.Add('update')
        }
        else {
            $ArgumentList.Add('create')
        }

        $ArgumentList.Add($Name)
        if ($Description) {
            $ArgumentList.Add('--description')
            $ArgumentList.Add($Description)
        }

        if ($DefaultStackOrchestrator) {
            $ArgumentList.Add('--default-stack-orchestrator')
            $ArgumentList.Add($DefaultStackOrchestrator)
        }

        $configuration = [System.Text.StringBuilder]::new()
        $configurationType = ''

        switch ($PSCmdlet.ParameterSetName) {
            'DockerEndpoint' {
                $configurationType = '--docker'
                if ($DockerHost) {
                    [void]$configuration.Append("host=$DockerHost")
                }
                if ($CertificateAuthority) {
                    if ($configuration.Length -gt 0) {
                        [void]$configuration.Append(',')
                    }
                    [void]$configuration.Append("ca=$CertificateAuthority")
                }
                if ($TclCertificateFile) {
                    if ($configuration.Length -gt 0) {
                        [void]$configuration.Append(',')
                    }
                    [void]$configuration.Append("cert=$TclCertificateFile")
                }
                if ($TlsKeyFile) {
                    if ($configuration.Length -gt 0) {
                        [void]$configuration.Append(',')
                    }
                    [void]$configuration.Append("key=$TlsKeyFile")
                }
                if ($SkipTlsVerify) {
                    if ($configuration.Length -gt 0) {
                        [void]$configuration.Append(',')
                    }
                    [void]$configuration.Append('skip-tls-verify=true')
                }
                elseif ($PSBoundParameters.ContainsKey('SkipTlsVerify')) {
                    if ($configuration.Length -gt 0) {
                        [void]$configuration.Append(',')
                    }
                    [void]$configuration.Append('skip-tls-verify=false')
                }
            }
            'KubernetesEndpoint' {
                $configurationType = '--kubernetes'
                if ($KubernetesConfigFile) {
                    [void]$configuration.Append("config-file=$KubernetesConfigFile")
                }
                if ($ContextOverride) {
                    if ($configuration.Length -gt 0) {
                        [void]$configuration.Append(',')
                    }
                    [void]$configuration.Append("context-override=$ContextOverride")
                }
                if ($NamespaceOverride) {
                    if ($configuration.Length -gt 0) {
                        [void]$configuration.Append(',')
                    }
                    [void]$configuration.Append("namespace-override=$NamespaceOverride")
                }
            }
            default {
                $exn = [System.NotImplementedException]'The parameter set is not implemented.'
                $er = [ErrorRecord]::new(
                    $exn,
                    'ParameterSetNotImplemented',
                    [ErrorCategory]::NotImplemented,
                    $PSCmdlet.ParameterSetName
                )
                $er.ErrorDetails = [ErrorDetails]::new(
                    "The parameter set '$($PSCmdlet.ParameterSetName)' is not implemented.",
                    'Contact the module author to request support for this parameter set.'
                )
                throw $er
            }
        }

        if ($configuration.Length -gt 0) {
            $ArgumentList.Add($configurationType)
            $ArgumentList.Add($configuration.ToString())
        }

        $Operation = [cultureinfo]::CurrentCulture.TextInfo.ToTitleCase($ArgumentList[1])
        if (!$PSCmdlet.ShouldProcess(
                "$Operation docker context '$Name'.",
                "$Operation docker context '$Name'?",
                "docker $ArgumentList")) {
            return
        }

        Invoke-Docker -ArgumentList $ArgumentList -ErrorVariable hadErrors 2>&1 | ForEach-Object {
            if ($_ -isnot [ErrorRecord] -or $_ -like 'Successfully updated context *' -or $_ -like 'Successfully created context *') {
                Write-Debug $_
            }
            else {
                Write-Error -ErrorRecord $_
            }
        }

        if ($PassThru) {
            Get-DockerContext $Name
        }
    }
}