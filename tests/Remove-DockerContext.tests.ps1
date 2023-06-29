Describe 'Remove-DockerContext' {
    BeforeAll {
        $script:Module = Get-Module 'Docker.PowerShell.CLI'
        if (-not $script:Module) {
            $script:Module = Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -PassThru -Force
            $script:RemoveModule = $true
        }
        $script:PreviousDockerContext = docker context show
    }
    AfterAll {
        if ($script:RemoveModule) {
            $script:Module | Remove-Module -Force
        }
        docker context use $script:PreviousDockerContext
    }
    It 'has no output' {
        # Arrange
        docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null

        # Act
        $Output = Remove-DockerContext 'docker-powershell-cli-test-1'

        # Assert
        $Output | Should -BeNullOrEmpty
    }
    Context 'with the current context' {
        BeforeAll {
            docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
            docker context use 'docker-powershell-cli-test-1'
            if ($LASTEXITCODE -ne 0) {
                throw 'Failed to set the current docker context for the tests.'
            }

            Remove-DockerContext 'docker-powershell-cli-test-1' -ErrorAction SilentlyContinue -ErrorVariable e
        }
        AfterAll {
            docker context use $script:PreviousDockerContext
            docker context rm 'docker-powershell-cli-test-1' 2>&1 | Out-Null
        }
        It 'reports an error' {
            # Assert
            $e | Should -Not -BeNullOrEmpty
        }
        It 'reports FullyQualifiedErrorId ''ContextInUse,Remove-DockerContext''' {
            # Assert
            $e.FullyQualifiedErrorId | Should -Be 'ContextInUse,Remove-DockerContext'
        }
        It 'reports TargetObject $Name' {
            # Assert
            $e.TargetObject | Should -Be 'docker-powershell-cli-test-1'
        }
        It 'does not remove the current context' {
            docker context show | Should -Be 'docker-powershell-cli-test-1'
        }
    }
    Context 'Parameter ''-WhatIf''' {
        BeforeAll {
            Mock Invoke-Docker -ModuleName Docker.PowerShell.CLI -ParameterFilter { $ArgumentList -contains 'context' -and $ArgumentList -contains 'remove' } -MockWith { } -Verifiable
            docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
            docker context create 'docker-powershell-cli-test-2' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
            docker context use $script:PreviousDockerContext
        }
        AfterAll {
            docker context use $script:PreviousDockerContext
            docker context remove 'docker-powershell-cli-test-1' 'docker-powershell-cli-test-2' 2>&1 | Out-Null
        }
        It 'does not invoke ''docker context remove'' when $true' {
            Remove-DockerContext 'docker-powershell-cli-test-1' -WhatIf:$true

            Should -Invoke Invoke-Docker -Exactly -Times 0 -ModuleName Docker.PowerShell.CLI
        }
        It 'invokes ''docker context remove'' when $false' {
            Remove-DockerContext 'docker-powershell-cli-test-2' -WhatIf:$false -ErrorAction Stop

            Should -Invoke Invoke-Docker -Exactly -Times 1 -ModuleName Docker.PowerShell.CLI
        }
        It 'reports an error when the name is not found' {
            # Arrange
            $Name = 'docker-powershell-cli-test-3'

            # Act
            Remove-DockerContext $Name -WhatIf:$true -ErrorAction SilentlyContinue -ErrorVariable e

            # Assert
            $e.FullyQualifiedErrorId | Should -Be 'ContextNameNotFound,Get-DockerContext'
        }
    }
    Context 'Parameter ''-Name''' {
        BeforeAll {
            docker context use $script:PreviousDockerContext
        }
        It 'removes the specified context' {
            # Arrange
            docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null

            # Act
            Remove-DockerContext 'docker-powershell-cli-test-1' -ErrorAction Stop

            # Assert
            docker context list --format '{{ .Name }}' | Should -Not -Contain 'docker-powershell-cli-test-1'
        }
        It 'removes multiple contexts' {
            # Arrange
            docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
            docker context create 'docker-powershell-cli-test-2' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
            $RemainingContexts = docker context list --format '{{ .Name }}'
            $RemainingContexts | Should -Contain 'docker-powershell-cli-test-1'
            $RemainingContexts | Should -Contain 'docker-powershell-cli-test-2'

            # Act
            Remove-DockerContext 'docker-powershell-cli-test-1', 'docker-powershell-cli-test-2' -ErrorAction Stop

            # Assert
            $RemainingContexts = docker context list --format '{{ .Name }}'
            $RemainingContexts | Should -Not -Contain 'docker-powershell-cli-test-1'
            $RemainingContexts | Should -Not -Contain 'docker-powershell-cli-test-2'
        }
        It 'removes a context by pipeline' {
            # Arrange
            docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null

            # Act
            [pscustomobject]@{
                Name = 'docker-powershell-cli-test-1'
            } | Remove-DockerContext -ErrorAction Stop

            # Assert
            docker context list --format '{{ .Name }}' | Should -Not -Contain 'docker-powershell-cli-test-1'
        }
        It 'supports wildcards' {
            # Arrange
            docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
            docker context create 'docker-powershell-cli-test-2' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null
            $RemainingContexts = docker context list --format '{{ .Name }}'
            $RemainingContexts | Should -Contain 'docker-powershell-cli-test-1'
            $RemainingContexts | Should -Contain 'docker-powershell-cli-test-2'

            # Act
            Remove-DockerContext 'docker-powershell-cli-test-?' -ErrorAction Stop

            # Assert
            $RemainingContexts = docker context list --format '{{ .Name }}'
            $RemainingContexts | Should -Not -Contain 'docker-powershell-cli-test-1'
            $RemainingContexts | Should -Not -Contain 'docker-powershell-cli-test-2'
        }
        It 'is case-insensitive' {
            # Arrange
            docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null

            # Act
            Remove-DockerContext 'DOCKER-POWERSHELL-CLI-TEST-1' -ErrorAction Stop

            # Assert
            docker context list --format '{{ .Name }}' | Should -Not -Contain 'docker-powershell-cli-test-1'
        }
        It 'removes existing contexts even when one is not found' {
            # Arrange
            docker context create 'docker-powershell-cli-test-1' --description 'docker context for Pester Tests' --docker 'host=tcp://myserver:2376' 2>&1 | Out-Null

            # Act
            Remove-DockerContext 'docker-powershell-cli-test-3', 'docker-powershell-cli-test-1' -ErrorAction Ignore

            # Assert
            docker context list --format '{{ .Name }}' | Should -Not -Contain 'docker-powershell-cli-test-1'
        }
        Context 'when the context does not exist' {
            BeforeAll {
                Mock Invoke-Docker -ModuleName Docker.PowerShell.CLI -ParameterFilter { $ArgumentList -contains 'context' -and $ArgumentList -contains 'remove' } -MockWith { } -Verifiable

                Remove-DockerContext -Name 'docker-powershell-cli-test-3' -ErrorAction SilentlyContinue -ErrorVariable e
            }
            It 'does not invoke ''docker context remove''' {
                Should -Invoke Invoke-Docker -Exactly -Times 0 -ModuleName Docker.PowerShell.CLI
            }
            It 'reports an error' {
                $e | Should -HaveCount 1
            }
            It 'reports FullyQualifiedErrorId ''ContextNameNotFound,Get-DockerContext''' {
                $e.FullyQualifiedErrorId | Should -Be 'ContextNameNotFound,Get-DockerContext'
            }
            It 'does not report an error when the name has a wildcard' {
                Remove-DockerContext -name 'docker-powershell-cli-test?invalid' -ErrorAction SilentlyContinue -ErrorVariable e

                $e | Should -BeNullOrEmpty
            }
        }
    }
}