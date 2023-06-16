Describe 'Get-DockerContainer' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../build/debug/Docker.PowerShell.CLI/Docker.PowerShell.CLI.psd1"
        docker container create -it --name docker-powershell-cli-test1 alpine
        docker container create -it --name docker-powershell-cli-test2 alpine
        docker container create -it --name docker-powershell-cli-test3 alpine
    }
    AfterAll {
        docker container rm -f docker-powershell-cli-test1 docker-powershell-cli-test2 docker-powershell-cli-test3
    }

    It 'Returns all containers' {
        # Arrange

        # Act
        $Containers = Get-DockerContainer

        # Assert (user may have existing containers)
        $Containers.Count | Should -BeGreaterOrEqual 3
    }

    It 'Returns [DockerContainer]' {
        # Arrange
        $Expected = 'DockerContainer'

        # Act
        $Containers = Get-DockerContainer

        # Assert
        $Containers | ForEach-Object { $_.GetType().FullName | Should -Be $Expected }
    }

    Context 'Parameter ''-Name''' {
        It 'filters by name' -TestCases @(
            @{ Name = @('docker-powershell-cli-test1') }
            @{ Name = 'docker-powershell-cli-test1', 'docker-powershell-cli-test2' }
            @{ Name = 'docker-powershell-cli-test1', 'docker-powershell-cli-test2', 'docker-powershell-cli-test3' }
        ) {
            # Arrange

            # Act
            $Containers = Get-DockerContainer -Name $Name

            # Assert
            $Containers | Should -HaveCount $Name.Count
            $Containers.Name | Should -BeIn $Name
        }
        It 'supports wildcards' -TestCases @(
            @{ Name = 'docker-powershell-cli-test*' }
            @{ Name = '*-powershell-cli-test*' }
        ) {
            # Arrange

            # Act
            $Containers = Get-DockerContainer -Name $Name

            # Assert
            $Containers | Should -HaveCount 3
        }
        It 'is case-insensitive' -TestCases @(
            @{ Name = 'docker-powershell-cli-test1' }
            @{ Name = 'DOCKER-powershell-CLI-TEST1' }
            @{ Name = '*-POWERSHELL-CLI-*' }
        ) {
            # Arrange
            $ExpectedCount = if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)) {
                3
            }
            else {
                1
            }

            # Act
            $Containers = Get-DockerContainer -Name $Name

            # Assert
            $Containers | Should -HaveCount $ExpectedCount
        }
        It 'does not return the same container twice' {
            # Arrange

            # Act
            $Containers = Get-DockerContainer -Name '*', '*'

            # Assert
            $Containers | Select-Object -Unique | Should -BeExactly $Containers
        }
        It 'reports an error when no containers match' {
            # Arrange
            $Name = 'docker-powershell-cli-test4'

            # Act
            $Containers = Get-DockerContainer -Name $Name -ErrorVariable e

            # Assert
            $Containers | Should -BeNullOrEmpty
            $e.Count | Should -Be 1
            $e.Exception | Should -BeOfType [System.Management.Automation.ItemNotFoundException]
            $e.TargetObject | Should -Be $Name
            $e.CategoryInfo.Category | Should -Be 'ObjectNotFound'
            $e.FullyQualifiedErrorId | Should -Be 'ContainerNameNotFound,Get-DockerContainer'
        }
        It 'does not report an error if the input has a wildcard' {
            # Arrange
            $Name = '*-powershell-cli-test4'

            # Act
            $Containers = Get-DockerContainer -Name $Name -ErrorVariable e

            # Assert
            $Containers | Should -BeNullOrEmpty
            $e | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter ''-Id''' {
        It 'filters by id' -TestCases @(
            @{ Name = 'docker-powershell-cli-test1' }
            @{ Name = 'docker-powershell-cli-test1', 'docker-powershell-cli-test2' }
        ) {
            # Arrange
            $Id = Get-DockerContainer -Name $Name | ForEach-Object Id | Sort-Object

            # Act
            $Containers = Get-DockerContainer -Id $Id
            $ContainerIds = $Containers.Id | Sort-Object

            # Assert
            $ContainerIds | Should -BeExactly $Id
        }
        It 'supports wildcards' -TestCases @(
            @{ Name = '*'; Substring = @(@(0, -1), @(12, 10), @(0, -1)) }
            @{ Name = '*'; Substring = @(@(11, 17), @(0, -1), @(0, 11)) }
            @{ Name = '*'; Substring = @(@(0, 17), @(0, -1), @(5, 11)) }
            @{ Name = '*'; Substring = @(@(0, -1), @(0, 6), @(5, 11)) }
        ) {
            # Arrange
            $Container = Get-DockerContainer -Name $Name
            $Id = for ($i = 0; $i -lt $Substring.Count; $i++) {
                $StartIndex = $Substring[$i][0]
                $Length = $Substring[$i][1]
                if ($Length -eq -1) { $Length = $Container[$i].Id.Length }
                $IdSubstring = $Container[$i].Id.Substring($StartIndex, $Length)
                if ($IdSubstring -ne $Container[$i].Id) {
                    $IdSubstring = "*$IdSubstring*"
                }
                $IdSubstring
            }

            # Act
            $Containers = Get-DockerContainer -Id $Id

            # Assert
            $Containers | Should -HaveCount $Substring.Count
        }
        It 'is case-insensitive' {
            # Arrange
            $Container = Get-DockerContainer -Name 'docker-powershell-cli-test1'
            $Id = $Container.Id.ToUpper()

            # Act
            $Containers = Get-DockerContainer -Id $Id

            # Assert
            $Containers.Id | Should -BeExactly $Container.Id
        }
        It 'does not return the same container twice' {
            # Arrange
            $Container = Get-DockerContainer -Name 'docker-powershell-cli-test1'
            $Id = $Container.Id

            # Act
            $Containers = Get-DockerContainer -Id $Id, $Id

            # Assert
            $Containers | Select-Object -Unique | Should -BeExactly $Containers
        }
        It 'reports an error when no containers match' {
            # Arrange
            $Id = 'zzinvalidzz'

            # Act
            $Containers = Get-DockerContainer -Id $Id -ErrorVariable e

            # Assert
            $Containers | Should -BeNullOrEmpty
            $e.Count | Should -Be 1
            $e.Exception | Should -BeOfType [System.Management.Automation.ItemNotFoundException]
            $e.CategoryInfo.Category | Should -Be 'ObjectNotFound'
            $e.TargetObject | Should -Be $Id
            $e.FullyQualifiedErrorId | Should -Be 'ContainerIdNotFound,Get-DockerContainer'
        }
        It 'does not report an error if the input has a wildcard' {
            # Arrange
            $Id = '*zzinvalidzz*'

            # Act
            $Containers = Get-DockerContainer -Id $Id -ErrorVariable e

            # Assert
            $Containers | Should -BeNullOrEmpty
            $e | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter ''-State''' {
        BeforeAll {
            docker container start docker-powershell-cli-test1 docker-powershell-cli-test2
            docker container stop docker-powershell-cli-test2
        }
        AfterAll {
            docker container stop docker-powershell-cli-test1
        }
        It 'filters by status' -TestCases @(
            @{ Status = 'running' }
            @{ Status = 'exited' }
            @{ Status = 'paused' ; ExpectNone = $true }
        ) {
            # Arrange

            # Act
            $Containers = Get-DockerContainer -State $Status

            # Assert
            if ($ExpectNone) {
                $Containers | Should -BeNullOrEmpty
            }
            else {
                $Containers.State | ForEach-Object { $_ | Should -Be $Status }
            }
        }
        It 'is case-insensitive' {
            # Arrange

            # Act
            $Containers = Get-DockerContainer -State 'RUNNING'

            # Assert
            $Containers.State | ForEach-Object { $_ | Should -Be 'running' }
        }
        It 'does not return the same container twice' {
            # Arrange

            # Act
            $Containers = Get-DockerContainer -State 'running', 'running' -ErrorAction Stop

            # Assert
            $Containers | Select-Object -Unique | Should -BeExactly $Containers
        }
        It 'does not report an error when no containers match' {
            # Arrange

            # Act
            $Containers = Get-DockerContainer -State 'paused' -ErrorVariable e

            # Assert
            $Containers | Should -BeNullOrEmpty
            $e | Should -BeNullOrEmpty
        }
        It 'reports an error if no container matches a specified id and status' {
            # Arrange
            $Id = Get-DockerContainer -Name 'docker-powershell-cli-test1' | ForEach-Object Id
            if (!$Id) { throw 'Container is missing' }

            # Act
            $Containers = Get-DockerContainer -Id $Id -State 'exited' -ErrorVariable e

            # Assert
            $Containers | Should -BeNullOrEmpty
            $e.FullyQualifiedErrorId | Should -Be 'ContainerIdNotFound,Get-DockerContainer'
        }
        It 'reports an error if no container matches a specified name and status' {
            # Arrange
            $Name = 'docker-powershell-cli-test1'

            # Act
            $Containers = Get-DockerContainer -Name $Name -State 'exited' -ErrorVariable e

            # Assert
            $Containers | Should -BeNullOrEmpty
            $e.FullyQualifiedErrorId | Should -Be 'ContainerNameNotFound,Get-DockerContainer'
        }
    }
}