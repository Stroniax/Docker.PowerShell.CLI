#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

Describe 'Get-DockerContext' {
    BeforeAll {
        $Module = Get-Module Docker.PowerShell.CLI
        if (!$Module) {
            $script:RemoveModule = Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -PassThru -Force
        }
    }
    AfterAll {
        $script:RemoveModule | Where-Object { $_ } | Remove-Module -Force
    }

    It 'returns [DockerContext]' {
        # Arrange

        # Act
        $contexts = Get-DockerContext

        # Assert
        $contexts | ForEach-Object { $_.GetType().Name | Should -Be 'DockerContext' }
    }
    It 'returns at least one item' {
        # Arrange

        # Act
        $contexts = Get-DockerContext

        # Assert
        $contexts.Count | Should -BeGreaterThan 0
    }
    Context 'Parameter ''-Name''' {
        BeforeAll {
            $ContextName = 'docker-powershell-cli-test-1'
            docker context create $ContextName --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
        }
        AfterAll {
            docker context rm $ContextName 2>&1 | Out-Null
        }
        It 'filters by name' {
            # Arrange

            # Act
            $Context = Get-DockerContext -Name $ContextName

            # Assert
            $Context.Name | Should -Be $ContextName
        }
        It 'supports wildcards' -TestCases @(
            @{ Name = 'docker*cli*test*' }
        ) {
            # Arrange

            # Act
            $Context = Get-DockerContext -Name $Name

            # Assert
            $Context.Name | Should -Be $ContextName
        }
        It 'is case-insensitive' -TestCases @(
            @{ Name = 'DOCKER-POWERSHELL-CLI-TEST-1' }
            @{ Name = 'docker*cli*TEST*' }
        ) {
            # Arrange

            # Act
            $Context = Get-DockerContext -Name $Name

            # Assert
            $Context.Name | Should -Be $ContextName
        }
        It 'gets everything for ''*''' {
            # Arrange

            # Act
            $Context = Get-DockerContext -Name '*'

            # Assert
            $Context.Name | Should -Contain $ContextName
        }
        It 'does not duplicate results' {
            # Arrange

            # Act
            $Context = Get-DockerContext -Name $ContextName, $ContextName

            # Assert
            $Context | Should -HaveCount 1
        }
        Context 'when not found' {
            BeforeAll {
                $Name = 'does-not-exist'
                $Context = Get-DockerContext -Name $Name -ErrorAction SilentlyContinue -ErrorVariable e
                $null = $Context
            }
            It 'reports no error when a wildcard is present' {
                # Arrange

                # Act
                $Context = Get-DockerContext -Name 'does-not-exist*' -ErrorAction SilentlyContinue -ErrorVariable e

                # Assert
                $Context | Should -BeNullOrEmpty
                $e | Should -BeNullOrEmpty
            }
            It 'returns nothing' {
                # Assert
                $Context | Should -BeNullOrEmpty
            }
            It 'reports a non-terminal error when not found' {
                # Assert
                $e | Should -HaveCount 1
            }
            It 'reports FullyQualifiedErrorId ''ContextNameNotFound,Get-DockerContext'' when not found' {
                # Assert
                $e.FullyQualifiedErrorId | Should -Be 'ContextNameNotFound,Get-DockerContext'
            }
            It 'reports error message ''No context found with the specified name ''$Name''.'' when not found' {
                # Assert
                $e.ErrorDetails.Message | Should -Be "No context found with the specified name '$Name'."
            }
            It 'reports [ItemNotFoundException] when not found' {
                # Assert
                $e.Exception | Should -BeOfType System.Management.Automation.ItemNotFoundException
            }
            It 'reports ErrorCategory ''ObjectNotFound'' when not found' {
                # Assert
                $e.CategoryInfo.Category | Should -Be 'ObjectNotFound'
            }
            It 'reports TargetObject $Name when not found' {
                # Assert
                $e.TargetObject | Should -Be $Name
            }
        }
    }
}