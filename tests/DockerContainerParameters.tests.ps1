# These tests are designed to ensure a consistent interface across all DockerContainer functions.

Describe '*-DockerContainer function parameters' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../build/debug/Docker.PowerShell.CLI/Docker.PowerShell.CLI.psd1"
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
            $Function = Get-Command -Name $CommandName
        }
        Context 'parameter ''-Name''' {
            It 'is of type [System.String[]]' {
                $Function.Parameters['Name'].ParameterType | Should -Be ([System.String[]])
            }
            It 'supports wildcards' {
                $Function.Parameters['Name'].Attributes | Should -Contain ([SupportsWildcards]::new())
            }
            It 'has alias ''-ContainerName''' {
                $Function.Parameters['Name'].Aliases | Should -Contain 'ContainerName'
            }
            It 'has argument completer' {
                $ArgumentCompleter = $Function.Parameters['Name'].Attributes | Where-Object { $_ -is [ArgumentCompleter] -and $_.Type.FullName -eq 'DockerContainerCompleter' }
                $ArgumentCompleter | Should -Not -BeNullOrEmpty
            }
            It 'is positional' {
                $Parameter = $Function.Parameters['Name'].Attributes | Where-Object { $_ -is [Parameter] -and $_.Position -eq 0 }
                $Parameter | Should -Not -BeNullOrEmpty
            }
            It 'does not accept pipeline input' {
                $Function.Parameters['Name'].Attributes.Where({ $_ -is [Parameter] }).ValueFromPipelineByPropertyName | Should -BeFalse
            }
        }
        Context 'parameter ''-Id''' {
            It 'is of type [System.String[]]' {
                $Function.Parameters['Id'].ParameterType | Should -Be ([System.String[]])
            }
            It 'has alias ''-Container''' {
                $Function.Parameters['Id'].Aliases | Should -Contain 'Container'
            }
            It 'has alias ''-ContainerId''' {
                $Function.Parameters['Id'].Aliases | Should -Contain 'ContainerId'
            }
            It 'is not positional' {
                $Parameter = $Function.Parameters['Id'].Attributes.Where({ $_ -is [Parameter] -and $_.Position -ne [int]::MinValue })
                $Parameter | Should -BeNullOrEmpty
            }
            It 'accepts pipeline input' {
                $Function.Parameters['Id'].Attributes.Where({ $_ -is [Parameter] }).ValueFromPipelineByPropertyName | Should -BeTrue
            }
            It 'has argument completer' {
                $ArgumentCompleter = $Function.Parameters['Id'].Attributes | Where-Object { $_ -is [ArgumentCompleter] -and $_.Type.FullName -eq 'DockerContainerCompleter' }
                $ArgumentCompleter | Should -Not -BeNullOrEmpty
            }
            It 'does not support wildcards' {
                if ($Function.Verb -eq 'Get') {
                    return
                }
                $Function.Parameters['Id'].Attributes | Should -Not -Contain ([SupportsWildcards]::new())
            }
        }
        Context 'parameter ''-Context''' {
            It 'is of type [System.String]' {
                $Function.Parameters['Context'].ParameterType | Should -Be ([System.String])
            }
            It 'is not positional' {
                $Parameter = $Function.Parameters['Context'].Attributes.Where({ $_ -is [Parameter] -and $_.Position -ne [int]::MinValue })
                $Parameter | Should -BeNullOrEmpty
            }
            It 'does not accept pipeline input' {
                $Function.Parameters['Context'].Attributes.Where({ $_ -is [Parameter] }).ValueFromPipelineByPropertyName | Should -BeFalse
            }
            It 'does not support wildcards' {
                $Function.Parameters['Context'].Attributes | Should -Not -Contain ([SupportsWildcards]::new())
            }
            It 'may not be null or empty' {
                $Function.Parameters['Context'].Attributes | Should -Contain ([ValidateNotNullOrEmpty]::new())
            }
            It 'has argument completer' {
                $ArgumentCompleter = $Function.Parameters['Context'].Attributes | Where-Object { $_ -is [ArgumentCompleter] -and $_.Type.FullName -eq 'DockerContextCompleter' }
                $ArgumentCompleter | Should -Not -BeNullOrEmpty
            }
        }
        It 'all parameters have completion' {
            $WithoutCompletion = @()
            foreach ($ParameterName in $Function.Parameters) {
                $Parameter = $Function.Parameters[$ParameterName]
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