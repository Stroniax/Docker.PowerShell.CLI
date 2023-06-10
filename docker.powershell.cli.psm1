using namespace System.Collections;
using namespace System.Diagnostics;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.Management.Automation.Language;

#region Classes
class DockerContainerCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string]$commandName,
        [string]$parameterName,
        [string]$wordToComplete,
        [CommandAst]$commandAst,
        [IDictionary]$fakeBoundParameters
    ) {
        if ($null -eq $wordToComplete) {
            $wordToComplete = ''
        }
        $wc = $wordToComplete.Trim('"''') + '*'
        $ProxyParameters = @{}
        if ($FakeBoundParameters['Context']) {
            $ProxyParameters['Context'] = $FakeBoundParameters['Context']
        }

        $Containers = Get-DockerContainer @ProxyParameters

        $CompletionResults = [List[CompletionResult]]::new();
        foreach ($Container in $Containers) {
            $IsMatch = $Container.Names -like $wc -or $Container.id -like $wc
            if (-not $IsMatch) {
                continue
            }

            if ($parameterName -in 'ContainerId', 'Id') {
                $CompletionText = @($Container.Id)
            }
            else {
                $CompletionText = @($Container.Names)
            }

            foreach ($Completion in $CompletionText) {
                $HasUnsafeChar = $Completion.IndexOfAny("`0`n`r`t`v`'`"`` ".ToCharArray()) -ge 0
                $SafeCompletionText = if ($HasUnsafeChar) { "'$Completion'" } else { $Completion }
                $ListItemText = if ($Completion -eq $Container.Id) { "$Completion (name: $($Container.Names -join ', '))" } else { "$Completion (id: $($Container.Id))" }

                $CompletionResults.Add(
                    [CompletionResult]::new(
                        $SafeCompletionText,
                        $ListItemText,
                        'ParameterValue',
                        $Completion
                    )
                )
            }
        }

        return $CompletionResults
    }
}

class DockerContextCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string]$commandName,
        [string]$parameterName,
        [string]$wordToComplete,
        [CommandAst]$commandAst,
        [IDictionary]$fakeBoundParameters
    ) {
        if ($null -eq $wordToComplete) {
            $wordToComplete = ''
        }
        $wc = $wordToComplete.Trim('"''') + '*'

        Write-Debug 'docker context list --quiet'
        $Contexts = docker context list --quiet

        $Results = [List[CompletionResult]]::new()
        foreach ($Context in $Contexts) {
            if ($Context -notlike $wc) {
                continue
            }
            $Results.Add(
                [CompletionResult]::new(
                    $Context,
                    $Context,
                    'ParameterValue',
                    $Context
                )
            )
        }
        return $Results
    }
}

class DockerImageCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string]$commandName,
        [string]$parameterName,
        [string]$wordToComplete,
        [CommandAst]$commandAst,
        [IDictionary]$fakeBoundParameters
    ) {
        if ($null -eq $wordToComplete) {
            $wordToComplete = ''
        }
        $wc = $wordToComplete.Trim('"''') + '*'
        $ProxyParameters = @{}
        if ($FakeBoundParameters['Context']) {
            $ProxyParameters['Context'] = $FakeBoundParameters['Context']
        }

        $Images = Get-DockerImage @ProxyParameters

        $CompletionResults = [List[CompletionResult]]::new();
        $CompletedTags = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($Image in $Images) {
            $IsMatch = $Image.Name -like $wc -or $Image.id -like $wc
            if (-not $IsMatch) {
                continue
            }

            if ($parameterName -in 'ImageId', 'Id') {
                $CompletionText = $Image.Id
                $ListItemText = "$($Image.Id) ($($Image.Repository))"
            }
            # DockerImageCompleter is designed to complete from all images, so we don't
            # need to worry about filtering the tag down to tags for the specified image.
            elseif ($parameterName -eq 'Tag') {
                $CompletionText = $Image.Tag
                if (!$CompletedTags.Add($CompletionText)) {
                    continue
                }
                $ListItemText = $Image.Tag
            }
            else {
                $CompletionText = $Image.Repository
                $ListItemText = "$($Image.Repository) ($($Image.Id))"
            }
            
            $HasUnsafeChar = $CompletionText.IndexOfAny("`0`n`r`t`v`'`"`` ".ToCharArray()) -ge 0
            $SafeCompletionText = if ($HasUnsafeChar) { "'$CompletionText'" } else { $CompletionText }

            $CompletionResults.Add(
                [CompletionResult]::new(
                    $SafeCompletionText,
                    $ListItemText,
                    'ParameterValue',
                    $CompletionText
                )
            )
        }

        return $CompletionResults
    }
}

class ValidateDockerContext : ValidateArgumentsAttribute {
    [void ]Validate([object]$Context, [EngineIntrinsics]$EngineIntrinsics) {
        if ($Context -as [string]) {
            Write-Debug 'docker context list --quiet'
            $Contexts = docker context list --quiet
            if ($Contexts -notcontains $Context) {
                throw "Context '$Context' does not exist"
            }
        }
    }
}

class DockerAttachJob : System.Management.Automation.Job {
    hidden [System.Diagnostics.Process]$_Process
    DockerAttachJob([System.Diagnostics.Process]$Process) : base($Process.CommandLine, $Process.Name) {
        $this._Process = $Process
        Register-ObjectEvent -InputObject $Process -EventName OutputDataReceived -Action {
            $this.Output.Add($EventArgs.Data)
        }
        Register-ObjectEvent -InputObject $Process -EventName Exited -Action {
            if ($this._Process.ExitCode -eq 0) {
                $this.SetJobState([System.Management.Automation.JobState]::Completed)
            }
            else {
                $this.SetJobState([System.Management.Automation.JobState]::Failed)
            }
        }
    }

    hidden [string] get_StatusMessage() {
        if ($this._Process.HasExited) {
            return 'Exited'
        }
        else {
            return 'Running'
        }
    }

    hidden [bool] get_HasMoreData() {
        return $this.Output.Count -gt 0
    }

    hidden [string] get_Location() {
        return $this._Process.StartInfo.FileName
    }

    [void] StopJob() {
        $this._Process.Kill()
    }
}

#endregion Classes

#region Helper Functions
function Invoke-Docker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
        [string[]]
        $ArgumentList,

        [Parameter()]
        [ValidateDockerContext()]
        [string]
        $Context
    )

    process {
        $List = [List[string]]$ArgumentList
        if ($Context) {
            $List.Insert(0, '--context')
            $List.Insert(1, $Context)
        }
        Write-Debug "docker $List"
        docker $List
    }
}

function ConvertTo-DockerWildcard {
    param(
        [Parameter()]
        [string]
        $Expression
    )
    process {
        $Expression -split '(?<!`)\*' | ForEach-Object { 
            if ($_) {
                $_ -replace '`\*', '*'
            }
        }
    }
}

function Test-MultipleWildcard {
    param(
        [string[]]$WildcardPattern,
        [string[]]$ActualValue
    )
    process {
        if (!$WildcardPattern) {
            return $true
        }
        if (!$ActualValue) {
            return $false
        }

        foreach ($w in $WildcardPattern) {
            foreach ($a in $ActualValue) {
                if ($a -like $w) {
                    return $true
                }
            }
        }
        return $false
    }
}

# Helper function to get a container by name or id depending on which
# parameters were passed to the origin function. If the id parameter
# is passed, it will be escaped so that it does not support wildcard
# patterns. This function will throw an error if more than one container
# is found or if no containers are found and the allow none switch is
# not specified.
function Get-DockerContainerSingle {
    param(
        [string]$Name,

        [string]$Id,

        [string]$Context,

        [switch]$AllowNone
    )
    process {
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -Context $Context -EscapeId

        if ($Containers.Count -gt 1) {
            Write-Error "More than one container found for $Message." -Category InvalidArgument -ErrorId 'AmbiguousContainer' -TargetObject $TargetObject
        }
        if ($Containers.Count -eq 0 -and !$AllowNone) {
            Write-Error "No container found for $Message." -Category ObjectNotFound -ErrorId 'ContainerNotFound' -TargetObject $TargetObject
        }

        $Containers
    }
}

# Helper function to get a container by name or id depending on which
# parameters were passed to the origin function. This can also escape
# the id parameter so that it does not support wildcard patterns.
function Get-DockerContainerInternal {
    param(
        [string[]]$Name,

        [string[]]$Id,

        [string]$Context,

        [switch]$EscapeId
    )

    process {
        $Parameters = @{}
        if ($Id) {
            $Parameters['Id'] = $Id | ForEach-Object { 
                if ($EscapeId) {
                    [WildcardPattern]::Escape($_)
                }
                else {
                    $_
                } 
            }
        }
        if ($Name) {
            $Parameters['Name'] = $Name
        }
        if ($Context) {
            $Parameters['Context'] = $Context
        }

        Get-DockerContainer @Parameters
    }
}

#endregion Helper Functions

#region Docker Container
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

function New-DockerContainer {
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $ImageName,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('ContainerName')]
        [string]
        $Name,

        [Parameter()]
        [string]
        $HostName,

        [Parameter()]
        [IPAddress]
        $IPAddress,

        [Parameter()]
        [switch]
        $Interactive,

        [Parameter()]
        [Hashtable]
        $Labels,

        [Parameter()]
        [Hashtable]
        $Environment,

        [Parameter()]
        [ValidateSet('always', 'missing', 'never')]
        [string]
        $PullBehavior,

        [Parameter()]
        [switch]
        $ReadOnly,

        [Parameter()]
        [switch]
        $AutoRemove,

        [Parameter()]
        [int]
        $TimeoutSeconds,

        [Parameter()]
        [string]
        $WorkingDirectory,

        # Any additional parameters to pass to the docker cli
        [Parameter()]
        [string[]]
        $Parameters,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        [List[string]]$ArgumentList = @(
            'container'
            'create'
        )

        if ($Name) {
            $ArgumentList.Add('--name')
            $ArgumentList.Add($Name)
        }

        if ($HostName) {
            $ArgumentList.Add('--hostname')
            $ArgumentList.Add($HostName)
        }

        if ($IPAddress) {
            $ArgumentList.Add('--ip')
            $ArgumentList.Add($IPAddress)
        }

        if ($Interactive) {
            $ArgumentList.Add('--interactive')
        }

        if ($Labels) {
            foreach ($k in $Labels.Keys) {
                $ArgumentList.Add('--label')
                $ArgumentList.Add("$k=$($Labels[$k])")
            }
        }

        if ($Environment) {
            foreach ($k in $Environment.Keys) {
                $ArgumentList.Add('--env')
                $ArgumentList.Add("$k=$($Environment[$k])")
            }
        }

        if ($PullBehavior) {
            $ArgumentList.Add('--pull')
            $ArgumentList.Add($PullBehavior)
        }

        if ($ReadOnly) {
            $ArgumentList.Add('--read-only')
        }

        if ($AutoRemove) {
            $ArgumentList.Add('--rm')
        }

        if ($TimeoutSeconds) {
            $ArgumentList.Add('--timeout')
            $ArgumentList.Add($TimeoutSeconds)
        }

        if ($WorkingDirectory) {
            $ArgumentList.Add('--workdir')
            $ArgumentList.Add($WorkingDirectory)
        }

        if ($Parameters) {
            foreach ($p in $Parameters) {
                $ArgumentList.Add($p)
            }
        }

        $ArgumentList.Add($ImageName)

        if (!$PSCmdlet.ShouldProcess(
                "Creating container '$Name' from image '$ImageName'.",
                "Create container '$Name' from image '$ImageName'?",
                "docker $ArgumentList")) {
            return
        }

        Invoke-Docker $ArgumentList -Context $Context | ForEach-Object {
            if ($PassThru) {
                Get-DockerContainerInternal -Id $_ -Context $Context
            }
        }
    }
}

function Remove-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [Alias('ContainerName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Id,

        [Parameter(Mandatory, ParameterSetName = 'Prune')]
        [switch]
        $Unused,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -Context $Context -EscapeId

        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose "No containers to process."
            return
        }

        $ArgumentList = @(
            'container'
            'rm'
            $Containers.Id
            if ($Force) { '--force' }
        )

        $ShouldProcessTarget = if ($Containers.Count -eq 1) { "container '$($Containers.Id)' ($($Containers.Names))" } else { "$($Containers.Count) containers" }

        if (!$PSCmdlet.ShouldProcess(
                "Removing $ShouldProcessTarget.",
                "Remove $ShouldProcessTarget?",
                "docker $ArgumentList")) {
            return;
        }
        Invoke-Docker $ArgumentList -Context $Context | Out-Null
    }
}

function Connect-DockerContainer {
    [CmdletBinding()]
    [Alias('ccdc')]
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $ContainerName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        Invoke-Docker attach $ContainerName -Context $Context
    }
}

function Start-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [Alias('sadc')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Name')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Name+Interactive')]
        [Alias('ContainerName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Id')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Id+Interactive')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [Alias('Container', 'ContainerId')]
        [string]
        $Id,

        # Maps to the --attach and --interactive parameters. (In the context of PowerShell, it does not make
        # sense to stream output to the console without attaching to the container.)
        [Parameter(Mandatory, ParameterSetName = 'Id+Interactive')]
        [Parameter(Mandatory, ParameterSetName = 'Name+Interactive')]
        [switch]
        $Interactive,

        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'Name')]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -Context $Context -EscapeId

        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose "No containers to process."
            return
        }
        
        $ArgumentList = @(
            'container',
            'start'
        )
        $ArgumentList += $Containers.Id

        if ($Interactive) {
            $ArgumentList += '--attach'
            $ArgumentList += '--interactive'
        }
        
        $ShouldProcessTarget = if ($Containers.Count -eq 1) { "container '$($Containers.Id)' ($($Containers.Names))" } else { "$($Containers.Count) containers" }
        if (!$PSCmdlet.ShouldProcess(
                "Starting $ShouldProcessTarget.",
                "Start $ShouldProcessTarget?",
                "docker $ArgumentList"
            )) {
            return
        }

        Invoke-Docker $ArgumentList -Context $Context | ForEach-Object {
            if ($PassThru) {
                Get-DockerContainerInternal -Id $_ -Context $Context
            } 
        }
    }
}

function Stop-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [Alias('spdc')]
    param(
        [Parameter(Position = 0, Mandatory, ParameterSetName = 'Name')]
        [Alias('ContainerName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Id')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [int]
        $TimeoutSeconds,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -Context $Context -EscapeId

        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose "No containers to process."
            return
        }

        $StopOrKill = if ($Force) { 'kill' } else { 'stop' }
        $Time = if (!$Force -and $TimeoutSeconds -gt 0) { '--time'; $TimeoutSeconds }
        $ArgumentList = @(
            'container'
            $StopOrKill
            $Time
        )
        $ArgumentList += $Containers.Id

        $ShouldProcessTarget = if ($Containers.Count -eq 1) { "container '$($Containers.Id)' ($($Containers.Names))" } else { "$($Containers.Count) containers" }
        if (!$PSCmdlet.ShouldProcess(
                "$StopOrKill $ShouldProcessTarget.",
                "$StopOrKill $ShouldProcessTarget?",
                "docker $ArgumentList"
            )) {
            return
        }

        # Stream results as they become available
        Invoke-Docker $ArgumentList -Context $Context | ForEach-Object {
            if ($PassThru) {
                Get-DockerContainerInternal -Id $_ -Context $Context
            }
        }
    }
}

function Restart-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [Alias('rtdc')]
    param(
        [Parameter(Position = 0, Mandatory, ParameterSetName = 'Name')]
        [Alias('ContainerName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Id')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [int]
        $TimeoutSeconds,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -Context $Context -EscapeId

        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose "No containers to process."
            return
        }

        $ArgumentList = @(
            'container',
            'restart'
        )
        if ($TimeoutSeconds) {
            $ArgumentList += '--time'
            $ArgumentList += $TimeoutSeconds
        }
        $ArgumentList += $Containers.Id

        $ShouldProcessTarget = if ($Containers.Count -eq 1) { "container '$($Containers.Id)' ($($Containers.Names))" } else { "$($Containers.Count) containers" }
        if (!$PSCmdlet.ShouldProcess(
                "Restarting $ShouldProcessTarget.",
                "Restart $ShouldProcessTarget?",
                "docker $ArgumentList")) {
            return
        }

        # Stream results as they become available
        Invoke-Docker $ArgumentList -Context $Context | ForEach-Object {
            if ($PassThru) {
                Get-DockerContainerInternal -Id $_ -Context $Context
            } 
        }
    }
}

function Suspend-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [Alias('ssdc')]
    param(
        [Parameter(Position = 0, Mandatory, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Id')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [Alias('Container', 'ContainerId')]
        [string[]]
        $Id,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )

    $Containers = Get-DockerContainerInternal -Id $Id -Name $Name -Context $Context -EscapeId

    if ($Containers.Count -eq 0) {
        # If no containers, the user input wildcard(s) or an error was reported by internal Get
        Write-Verbose "No containers to process."
        return
    }

    if ($Containers.Count -gt 1) {
        $ContainerIdentification = "$($Containers.Count) containers"
    }
    else {
        $ContainerIdentification = "container $($Containers.Id) ($($Containers.Names))"
    }

    if (!$PSCmdlet.ShouldProcess(
            "Pausing all processes in $ContainerIdentification.",
            "Pause all processes in $ContainerIdentification?",
            "docker $ArgumentList"
        )) {
        return
    }

    Invoke-Docker pause $Containers.Id -Context $Context | ForEach-Object {
        if ($PassThru) {
            Get-DockerContainerInternal -Id $_ -Context $Context
        }
    }
}

function Resume-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [Alias('rudc')]
    param(
        [Parameter(Position = 0, Mandatory, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Id')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [Alias('Container', 'ContainerId')]
        [string[]]
        $Id,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )

    $Containers = Get-DockerContainerInternal -Id $Id -Name $Name -Context $Context -EscapeId

    # Ensure we have containers to process
    if ($Containers.Count -eq 0) {
        # If no containers, the user input wildcard(s) or an error was reported by internal Get
        Write-Verbose "No containers to process."
        return
    }

    if ($Containers.Count -gt 1) {
        $ContainerIdentification = "$($Containers.Count) containers"
    }
    else {
        $ContainerIdentification = "container $($Containers.Id) ($($Containers.Names))"
    }

    if (!$PSCmdlet.ShouldProcess(
            "Unpausing all processes in $ContainerIdentification.",
            "Unpause all processes in $ContainerIdentification?",
            "docker $ArgumentList"
        )) {
        return
    }

    Invoke-Docker unpause $Containers.Id -Context $Context | ForEach-Object {
        if ($PassThru) {
            Get-DockerContainerInternal -Id $_ -Context $Context
        }
    }
}

#TODO: Does not reliably enter a prompt in the container
# Depends on the container having /bin/ash
function Enter-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        PositionalBinding = $false,
        RemotingCapability = [RemotingCapability]::OwnedByCommand)]
    [Alias('etdc')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [Alias('Container', 'ContainerId')]
        [string]
        $Id,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $Container = Get-DockerContainerSingle -Name $Name -Id $Id -Context $Context
        if (!$?) { return }

        if ($Container.State -ne 'running') {
            Write-Error "Cannot enter container $($Container.Id) ($($Container.Names)) because it is not running."
            return
        }

        Invoke-Docker exec -it $Container.Id /bin/ash -Context $Context
    }
}

function Wait-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        PositionalBinding = $false,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [Alias('wdc')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [Alias('Container', 'ContainerId')]
        [string]
        $Id,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        Invoke-Docker wait $Name -Context $Context
    }
}

function Rename-DockerContainer {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = [ConfirmImpact]::Medium,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    [Alias('rndc')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [Alias('Container', 'ContainerId')]
        [string]
        $Id,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $NewName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context,

        [Parameter()]
        [switch]
        $PassThru
    )
    process {
        $Container = Get-DockerContainerSingle -Name $Name -Id $Id -Context $Context
        if (!$?) { return }

        if ($PSCmdlet.ShouldProcess(
                "Renaming docker container '$($Container.Id)' from '$($Container.Names)' to $($NewName).",
                "Rename docker container '$($Container.Id)' from '$($Container.Names)' to $($NewName)?",
                "docker $ArgumentList")) {
            Invoke-Docker rename $Container.Id $NewName -Context $Context
            if ($PassThru) {
                Get-DockerContainerSingle -Name $NewName -Context $Context
            }
        }
    }
}

function Get-DockerContainerLog {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        PositionalBinding = $false,
        RemotingCapability = [RemotingCapability]::OwnedByCommand
    )]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [Alias('ContainerName')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
        [Alias('Container', 'ContainerId')]
        [ArgumentCompleter([DockerContainerCompleter])]
        [string]
        $Id,

        [Parameter()]
        [DateTime]
        $Since,

        [Parameter()]
        [DateTime]
        $Until,

        [Parameter()]
        [Alias('Tail')]
        [int]
        $Last,

        [Parameter()]
        [switch]
        $Follow,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )

    $Container = Get-DockerContainerSingle -Name $Name -Id $Id -Context $Context
    if (!$?) { return }

    $ArgumentList = @(
        'container'
        'logs'
        $Container.Id
        '--timestamps'
        '--details'
    )

    if ($Follow) {
        $ArgumentList += '--follow'
    }

    if ($Last) {
        $ArgumentList += '--tail'
        $ArgumentList += $Last
    }

    if ($Since) {
        $ArgumentList += '--since'
        $ArgumentList += $Since.ToString('yyyy-MM-ddTHH:mm:ss')
    }

    if ($Until) {
        $ArgumentList += '--until'
        $ArgumentList += $Until.ToString('yyyy-MM-ddTHH:mm:ss')
    }

    Write-Debug "$ArgumentList"
    Invoke-Docker $ArgumentList -Context $Context
}

#endregion Docker Container

#region Docker Image
function Get-DockerImage {
    [Alias('gdi')]
    param(
        [Parameter(Position = 0)]
        [SupportsWildcards()]
        [Alias('RepositoryName', 'ImageName')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $Name,

        [Parameter(Position = 1)]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $Tag,

        [Parameter()]
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

    $ArgumentList = @(
        'image',
        'list',
        '--no-trunc'
        '--format'
        '{{ json . }}'
        if ($IncludeIntermediateImages) { '--all' }
        if ($Dangling) { '--filter'; 'dangling=true' }
    )

    $ReportNotMatched = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    foreach ($n in $Name) {
        if (![WildcardPattern]::ContainsWildcardCharacters($n)) {
            [void]$ReportNotMatched.Add($n)
        }
    }

    for ($i = 0; $i -lt $Id.Length; $i++) {
        if ($id[$i].Length -eq 12 -and ![WildcardPattern]::ContainsWildcardCharacters($id[$i])) {
            $id[$i] = "sha256:$($id[$i])*"
        }

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

        [void]$ReportNotMatched.Remove($pso.Id)
        [void]$ReportNotMatched.Remove($pso.Repository)

        $pso.PSObject.Members.Add([PSNoteProperty]::new('RawLabels', $pso.Labels))
        $pso.PSObject.Members.Remove('Labels')
        $pso.PSObject.Members.Add([PSNoteProperty]::new('RawMounts', $pso.Mounts))
        $pso.PSObject.Members.Remove('Mounts')
        $pso.PSObject.Members.Add([PSNoteProperty]::new('Context', $Context))
        $pso.PSTypeNames.Insert(0, 'Docker.Image')

        $pso
    }

    foreach ($Unmatched in $ReportNotMatched) {
        Write-Error "No image found for '$Unmatched'." -Category ObjectNotFound -TargetObject $Unmatched -ErrorId 'ImageNotFound'
    }    
}

function Remove-DockerImage {
    param([Parameter(Mandatory)][string]$ImageName)
    Write-Debug "docker rmi $ImageName"
    docker rmi $ImageName
}

function New-DockerImage {
    [CmdletBinding()]
    [Alias('Build-DockerImage', 'ndi', 'bddi')]
    param(
        [Parameter()]
        [string]
        $Path = '.',

        [string]
        $DockerFile = './Dockerfile',

        [Parameter()]
        [string[]]
        $Tag,

        [Parameter()]
        [switch]
        $NoCache,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $ArgumentList = @(
            'build'
            $Path
            if ($DockerFile) { '--file'; $Dockerfile }
            if ($NoCache) { '--no-cache' }
        )

        Invoke-Docker $ArgumentList -Context $Context
    }
}

function Find-DockerImage {
    [CmdletBinding(
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false
    )]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Keyword,

        [Parameter()]
        [Alias('Automated')]
        [Nullable[bool]]
        $IsAutomated,

        [Parameter()]
        [Alias('Official')]
        [Nullable[bool]]
        $IsOfficial,

        [Parameter()]
        [Alias('Stars')]
        [int]
        $MinimumStars,

        [Parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('First', 'Take')]
        [int]
        $Limit = 100,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    process {
        $ArgumentList = @(
            'search'
            '--no-trunc'
            "--limit=$Limit"
            '--format'
            '{{ json . }}'
            if ($IsAutomated.HasValue) { "--filter=is-automated=$IsAutomated" }
            if ($IsOfficial.HasValue) { "--filter=is-official=$IsOfficial" }
            if ($MinimumStars) { "--filter=stars=$MinimumStars" }
            $Keyword
        )
        $Count = 0
        Invoke-Docker $ArgumentList -Context $Context | ForEach-Object {
            $pso = $_ | ConvertFrom-Json
            $pso.PSTypeNames.Insert(0, 'Docker.RemoteImage')
            $pso

            if ((++$Count) -eq $Limit -and !($PSBoundParameters.ContainsKey('Limit'))) {
                Write-Warning "The number of results has reached the default limit of $Limit. There may be more results available. Use the -Limit parameter to increase the limit."
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
            $pso.PSTypeNames.Insert(0, 'Docker.Version')
            $pso.Client.PSTypeNames.Insert(0, 'Docker.ClientVersion')
            $pso.Server.PSTypeNames.Insert(0, 'Docker.ServerVersion')
            $pso
        }
    }
}
#endregion

#region Docker Context
function Get-DockerContext {
    [Alias('gdcx')]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context = '*'
    )
    process {
        Invoke-Docker context list --format '{{ json . }}' | ForEach-Object {
            $pso = $_ | ConvertFrom-Json

            if ($pso.Name -notlike $Context) {
                return
            }

            $pso.PSTypeNames.Insert(0, 'Docker.Context')
            $pso
        }
    }
}

function Use-DockerContext {
    [Alias('udx')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('ContextName')]
        [ValidateDockerContext()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Name,

        [Parameter()]
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
