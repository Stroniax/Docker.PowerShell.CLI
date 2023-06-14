using namespace System.Collections;
using namespace System.Diagnostics;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.Management.Automation.Language;
using module src/Classes/DockerContainerCompleter.psm1
using module src/Classes/DockerContextCompleter.psm1
using module src/Classes/DockerImageCompleter.psm1
using module src/Classes/ValidateDockerContext.psm1
using module src/Classes/DockerBuildAddHostTransformation.psm1

#region Classes

#endregion Classes

#region Helper Functions

#endregion Helper Functions

#region Docker Container

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
        [Alias('Unused', 'Prune')]
        [switch]
        $StoppedContainers,

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
        if ($StoppedContainers) {
            $ArgumentList = @(
                'container'
                'prune'
                if ($Force) { '--force' }
            )
            if ($PSCmdlet.ShouldProcess(
                    'Removing stopped containers.',
                    'Remove stopped containers?',
                    "docker $ArgumentList")) {
                Invoke-Docker $ArgumentList -Context $Context | Out-Null
            }
            return
        }
        $Containers = Get-DockerContainerInternal -Name $Name -Id $Id -Context $Context -EscapeId

        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose 'No containers to process.'
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
            Write-Verbose 'No containers to process.'
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
            Write-Verbose 'No containers to process.'
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
            Write-Verbose 'No containers to process.'
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
    process {
        $Containers = Get-DockerContainerInternal -Id $Id -Name $Name -Context $Context -EscapeId

        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose 'No containers to process.'
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
    process {
        $Containers = Get-DockerContainerInternal -Id $Id -Name $Name -Context $Context -EscapeId

        # Ensure we have containers to process
        if ($Containers.Count -eq 0) {
            # If no containers, the user input wildcard(s) or an error was reported by internal Get
            Write-Verbose 'No containers to process.'
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
    process {
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
}

#endregion Docker Container

#region Docker Image
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

function Remove-DockerImage {
    [CmdletBinding(
        DefaultParameterSetName = 'Id',
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        PositionalBinding = $false,
        SupportsShouldProcess,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType([System.Management.Automation.Internal.AutomationNull])]
    [Alias('rdi')]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'FullName', ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [Alias('Reference')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $FullName,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [Alias('RepositoryName', 'ImageName')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [SupportsWildcards()]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Tag,

        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Alias('ImageId')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string[]]
        $Id,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context
    )
    begin {
        $ArgumentList = [List[string]]::new()
        $ArgumentList.Add('image')
        $ArgumentList.Add('remove')
        if ($Force) {
            $ArgumentList.Add('--force')
        }
    }
    process {
        $Images = Get-DockerImageInternal -Name $Name -Tag $Tag -Id $Id -FullName $FullName -Context $Context -EscapeId

        if ($Images.Count -eq 0) {
            Write-Verbose 'No images to process.'
        }

        foreach ($Image in $Images) {
            if ($PSCmdlet.ShouldProcess(
                    "Removing docker image $($Image.FullName) ($($Image.Id)).",
                    "Remove docker image $($Image.FullName) ($($Image.Id))?",
                    "docker image remove $($Image.FullName)"
                )) {
                $ArgumentList.Add($Image.FullName)
            }
        }
    }
    end {
        if ($ArgumentList.Count -eq 2) {
            # no images
            return
        }
        Invoke-Docker $ArgumentList -Context $Context | Write-Debug
    }
}

function Build-DockerImage {
    [CmdletBinding(
        SupportsShouldProcess,
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        ConfirmImpact = [ConfirmImpact]::Medium
    )]
    [OutputType('Docker.Image')]
    [Alias('bddi')]
    param(
        [Parameter()]
        [string]
        $Path = '.',

        [Parameter()]
        [string]
        $DockerFile = './Dockerfile',

        # Tags are not mandatory by the docker engine so this argument may be $null,
        # but personally I always want a tag and if I forget one I'm annoyed at myself.
        [Parameter(Mandatory)]
        [AllowNull()]
        [string[]]
        $Tag,

        [Parameter()]
        [switch]
        $NoCache,

        [Parameter()]
        [switch]
        $Pull,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter([DockerContextCompleter])]
        [string]
        $Context,

        [Parameter()]
        [Alias('Dns', 'CustomDns')]
        [DockerBuildAddHostTransformation()]
        [Dictionary[string, ipaddress]]
        $AddHosts,

        [Parameter()]
        [Alias('BuildArgs')]
        [hashtable]
        $Parameters,

        [Parameter()]
        [switch]
        $PassThru
    )
    process {
        $ArgumentList = @(
            'image'
            'build'
            $Path
            if ($DockerFile) { '--file'; $Dockerfile }
            if ($NoCache) { '--no-cache' }
            if ($Pull) { '--pull' }
            if ($Tag) { $Tag | ForEach-Object { '--tag'; $_ } }
            if ($AddHosts) { $AddHosts.Keys | ForEach-Object { '--add-host'; "${_}:$($AddHosts[$_])" } }
            if ($Parameters) { $Parameters.Keys | ForEach-Object { '--build-arg'; "${_}=$($Parameters[$_])" } }
            '--quiet'
        )

        # Oh how I wish there were a way to write progress AND get the id of the final image
        if ($PassThru) {
            $Id = Invoke-Docker $ArgumentList -Context $Context
            if ($?) {
                Get-DockerImage -Id $Id
            }
        }
        else {
            Invoke-Docker $ArgumentList -Context $Context | Write-Debug
        }

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

# Creates a duplicate image with a new name based on a source docker image
# This uses the `docker image tag` command.
function Copy-DockerImage {
    [CmdletBinding(
        SupportsShouldProcess,
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        ConfirmImpact = [ConfirmImpact]::Low,
        PositionalBinding = $false
    )]
    [OutputType('Docker.Image')]
    [Alias('cpdi')]
    param(
        # Full name of the source image
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'FullName')]
        [SupportsWildcards()]
        [Alias('Reference', 'SourceReference', 'SourceFullName', 'SourceImage', 'Source')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $FullName,

        # FullName for the destination image (the copy to be created)
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('TargetImage', 'TargetName', 'DestinationFullName', 'DestinationImage', 'DestinationReference', 'TargetReference')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $DestinationName,

        # Id of the source image
        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Alias('ImageId')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
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
    dynamicparam {
        [string]$DestinationName = $PSBoundParameters['DestinationName'];

        if ($DestinationName.Contains(':')) {
            return $null
        }

        $DynamicParameters = [RuntimeDefinedParameterDictionary]::new()
        $DynamicParameters.Add('DestinationTag', [RuntimeDefinedParameter]::new(
                'DestinationTag',
                [string],
                [ObjectModel.Collection[Attribute]]@(
                    [ParameterAttribute]@{
                        Mandatory                       = $true
                        Position                        = 2
                        ValueFromPipelineByPropertyName = $true
                    },
                    [AliasAttribute]::new('Tag')
                )
            ))
        return $DynamicParameters
    }
    process {
        $Images = Get-DockerImageInternal -Id $Id -FullName $FullName -EscapeId -Context $Context | Sort-Object -Property Id -Unique

        # Handle no images
        if ($Images.Count -eq 0) {
            Write-Verbose 'No images to process.'
            return
        }

        # Handle ambiguous images
        if ($Images.Count -gt 1) {
            $Message = if ($Id) { "Id '$Id'" } else { "Name '$FullName'" }
            $TargetObject = if ($Id) { $Id } else { $FullName }
            Write-Error "More than one image found for $Message." -Category InvalidArgument -ErrorId 'AmbiguousImage' -TargetObject $TargetObject
            return
        }

        # Handle dynamic parameter in case someone wants to provide destination name and tag as separate arguments
        if ($PSBoundParameters['DestinationTag']) {
            $DestinationName = "${DestinationName}:$($PSBoundParameters['DestinationTag'])"
        }

        # ShouldProcess?
        $ResolvedImage = $Images[0]
        if (!$PSCmdlet.ShouldProcess(
                "Creating new tag '$DestinationName' for image '$($ResolvedImage.FullName)' ($($ResolvedImage.Id)).",
                "Create new tag '$DestinationName' for image '$($ResolvedImage.FullName)' ($($ResolvedImage.Id))?",
                "docker image tag '$($ResolvedImage.Id)' '$DestinationName'"
            )) {
            return
        }

        # execute
        $ArgumentList = @(
            'image'
            'tag'
            $ResolvedImage.Id
            $DestinationName
        )

        Invoke-Docker $ArgumentList -Context $Context

        # PassThru
        if ($? -and $PassThru) {
            Get-DockerImage -FullName $DestinationName -Context $Context
        }
    }
}

function Export-DockerImage {
    [CmdletBinding(
        DefaultParameterSetName = 'FullName',
        SupportsShouldProcess,
        RemotingCapability = [RemotingCapability]::OwnedByCommand,
        ConfirmImpact = [ConfirmImpact]::Low,
        PositionalBinding = $false
    )]
    [OutputType('System.IO.FileInfo')]
    [Alias('epdi')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'FullName')]
        [SupportsWildcards()]
        [Alias('Reference')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $FullName,

        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Alias('ImageId')]
        [ArgumentCompleter([DockerImageCompleter])]
        [string]
        $Id,

        [Parameter(Mandatory, Position = 1)]
        [Alias('Path')]
        [string]
        $Destination,

        [Parameter()]
        [switch]
        $Force,

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
        $Images = Get-DockerImageInternal -Id $Id -FullName $FullName -EscapeId | Sort-Object -Property Id -Unique

        # Handle no images
        if ($Images.Count -eq 0) {
            Write-Verbose 'No images to process.'
            return
        }

        # Handle ambiguous images
        if ($Images.Count -gt 1) {
            $Message = if ($Id) { "Id '$Id'" } else { "Name '$FullName'" }
            $TargetObject = if ($Id) { $Id } else { $FullName }
            Write-Error "More than one image found for $Message." -Category InvalidArgument -ErrorId 'AmbiguousImage' -TargetObject $TargetObject
            return
        }

        # Resolve destination path
        $OutputPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Destination)
        if (!$?) {
            return
        }
        if (Test-Path $OutputPath -PathType Container) {
            Write-Error "Destination path '$Destination' is a directory." -Category InvalidArgument -ErrorId 'DestinationIsDirectory' -TargetObject $OutputPath
            return
        }
        if (!$Force -and (Test-Path $OutputPath -PathType Leaf)) {
            Write-Error "Destination path '$Destination' already exists." -Category InvalidArgument -ErrorId 'DestinationExists' -TargetObject $OutputPath
            return
        }

        # ShouldProcess?
        $ResolvedImage = $Images[0]
        if (!$PSCmdlet.ShouldProcess(
                "Exporting image '$($ResolvedImage.FullName)' ($($ResolvedImage.Id)) to '$Destination'.",
                "Export image '$($ResolvedImage.FullName)' ($($ResolvedImage.Id)) to '$Destination'?",
                "docker image save --output '$Outputpath' '$($ResolvedImage.Id)'"
            )) {
            return
        }

        Invoke-Docker image save --output $OutputPath $ResolvedImage.Id -Context $Context

        if ($PassThru) {
            Get-Item $OutputPath
        }
    }
}

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
