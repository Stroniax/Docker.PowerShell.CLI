using namespace System.Management.Automation
using module ../../Classes/DockerContext.psm1
using module ../../Classes/EmptyStringArgumentCompleter.psm1
using module ../../Classes/LowerCaseTransformation.psm1

function New-DockerContext {
    [CmdletBinding(
        DefaultParameterSetName = 'DockerEndpoint',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess = $true,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([DockerContext])]
    [Alias('ndcx')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Scope = 'Function', 
        Target = 'New-DockerContext',
        Justification = 'ShouldProcess is used in the Set-DockerContext function.'
    )]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_.+-]+$')]
        [ArgumentCompleter([EmptyStringArgumentCompleter])]
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
        $DefaultStackOrchestrator
    )
    process {
        # Since Set-DockerContext can create a new docker context, we can use it
        # after verifying that the context does not already exist

        $ExistingContexts = Invoke-Docker context list --format '{{ .Name }}'

        if ($ExistingContexts -contains $Name) {
            $WriteError = @{
                Exception         = [InvalidOperationException]::new('A context with the provided name already exists.')
                Message           = "A context with the name '$Name' already exists."
                Category          = [ErrorCategory]::InvalidArgument
                TargetObject      = $Name
                ErrorId           = 'ContextExists'
                RecommendedAction = 'Use Set-DockerContext to modify the existing context, or remove the existing context and try again.'
            }
            Write-Error @WriteError
            return
        }

        Set-DockerContext @PSBoundParameters -PassThru
    }
}