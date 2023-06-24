# These tests are designed to ensure a consistent interface across all DockerContainer functions.

Describe '*-DockerContainer function parameters' {
    BeforeAll {
        $Module = Get-Module 'Docker.PowerShell.CLI'
        if (-not $Module) {
            Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -Force -PassThru -ArgumentList $true
        }
    }
    Context 'Function <CommandName>' -ForEach @(
        @{ CommandName = 'Get-DockerContainer' }
        # @{ Function = 'New-DockerContainer' }
        @{ CommandName = 'Remove-DockerContainer' }
        @{ CommandName = 'Start-DockerContainer' }
        @{ CommandName = 'Stop-DockerContainer' }
        @{ CommandName = 'Restart-DockerContainer' }
        @{ CommandName = 'Wait-DockerContainer' }
        @{ CommandName = 'Suspend-DockerContainer' }
        @{ CommandName = 'Resume-DockerContainer' }
    ) {
        BeforeAll {
            $script:Function = Get-Command -Name $CommandName
        }
        Context 'parameter ''-Name''' {
            It 'is of type [System.String[]]' {
                $script:Function.Parameters['Name'].ParameterType | Should -Be ([System.String[]])
            }
            It 'supports wildcards' {
                $script:Function.Parameters['Name'].Attributes | Should -Contain ([SupportsWildcards]::new())
            }
            It 'has alias ''-ContainerName''' {
                $script:Function.Parameters['Name'].Aliases | Should -Contain 'ContainerName'
            }
            It 'has argument completer' {
                $ArgumentCompleter = $script:Function.Parameters['Name'].Attributes | Where-Object { $_ -is [ArgumentCompleter] -and $_.Type.FullName -eq 'DockerContainerCompleter' }
                $ArgumentCompleter | Should -Not -BeNullOrEmpty
            }
            It 'is positional' {
                $Parameter = $script:Function.Parameters['Name'].Attributes | Where-Object { $_ -is [Parameter] -and $_.Position -eq 0 }
                $Parameter | Should -Not -BeNullOrEmpty
            }
            It 'does not accept pipeline input' {
                $script:Function.Parameters['Name'].Attributes.Where({ $_ -is [Parameter] }).ValueFromPipelineByPropertyName | Should -BeFalse
            }
        }
        Context 'parameter ''-Id''' {
            It 'is of type [System.String[]]' {
                $script:Function.Parameters['Id'].ParameterType | Should -Be ([System.String[]])
            }
            It 'has alias ''-Container''' {
                $script:Function.Parameters['Id'].Aliases | Should -Contain 'Container'
            }
            It 'has alias ''-ContainerId''' {
                $script:Function.Parameters['Id'].Aliases | Should -Contain 'ContainerId'
            }
            It 'is not positional' {
                $Parameter = $script:Function.Parameters['Id'].Attributes.Where({ $_ -is [Parameter] -and $_.Position -ne [int]::MinValue })
                $Parameter | Should -BeNullOrEmpty
            }
            It 'accepts pipeline input' {
                $script:Function.Parameters['Id'].Attributes.Where({ $_ -is [Parameter] }).ValueFromPipelineByPropertyName | Should -BeTrue
            }
            It 'has argument completer' {
                $ArgumentCompleter = $script:Function.Parameters['Id'].Attributes | Where-Object { $_ -is [ArgumentCompleter] -and $_.Type.FullName -eq 'DockerContainerCompleter' }
                $ArgumentCompleter | Should -Not -BeNullOrEmpty
            }
            It 'does not support wildcards' {
                if ($script:Function.Verb -eq 'Get') {
                    return
                }
                $script:Function.Parameters['Id'].Attributes | Should -Not -Contain ([SupportsWildcards]::new())
            }
        }
        Context 'parameter ''-Context''' {
            It 'is of type [System.String]' {
                $script:Function.Parameters['Context'].ParameterType | Should -Be ([System.String])
            }
            It 'is not positional' {
                $Parameter = $script:Function.Parameters['Context'].Attributes.Where({ $_ -is [Parameter] -and $_.Position -ne [int]::MinValue })
                $Parameter | Should -BeNullOrEmpty
            }
            It 'does not accept pipeline input' {
                $script:Function.Parameters['Context'].Attributes.Where({ $_ -is [Parameter] }).ValueFromPipelineByPropertyName | Should -BeFalse
            }
            It 'does not support wildcards' {
                $script:Function.Parameters['Context'].Attributes | Should -Not -Contain ([SupportsWildcards]::new())
            }
            It 'may not be null or empty' {
                $script:Function.Parameters['Context'].Attributes | Should -Contain ([ValidateNotNullOrEmpty]::new())
            }
            It 'has argument completer' {
                $ArgumentCompleter = $script:Function.Parameters['Context'].Attributes | Where-Object { $_ -is [ArgumentCompleter] -and $_.Type.FullName -eq 'DockerContextCompleter' }
                $ArgumentCompleter | Should -Not -BeNullOrEmpty
            }
        }
        It 'all parameters have completion' {
            $WithoutCompletion = @()
            foreach ($ParameterName in $script:Function.Parameters) {
                $Parameter = $script:Function.Parameters[$ParameterName]
                $Attributes = $Parameter.Attributes
                $ArgumentCompleter = $Attributes | Where-Object { $_ -is [ArgumentCompleter] }
                $IsSwitch = $Parameter.ParameterType -eq [switch]
                $IsPath = $Parameter.Name -like '*Path*'
                $IsEnum = $Parameter.ParameterType.IsEnum
                $IsSet = $Parameter.Attributes | Where-Object { $_ -is [ValidateSet] }

                $HasCompletion = $ArgumentCompleter -or $IsSwitch -or $IsPath -or $IsEnum -or $IsSet
                if (!$HasCompletion) {
                    $WithoutCompletion += $Parameter.Name
                }
            }

            $WithoutCompletion | Should -BeNullOrEmpty
        }
    }
}