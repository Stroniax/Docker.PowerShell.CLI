#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

Describe 'Get-DockerVolume' {
    BeforeAll {
        $Module = Get-Module 'Docker.PowerShell.CLI'
        if (-not $Module) {
            $script:RemoveModule = Import-Module "$PSScriptRoot/../Docker.PowerShell.CLI.psd1" -PassThru -Force
        }
        docker volume create --label cli.powershell.docker.test=1 --driver local 'docker-powershell-cli-test-1'
        docker volume create --label cli.powershell.docker.test=2 --driver local 'docker-powershell-cli-test-2'
        docker volume create --label cli.powershell.docker.test=3 --driver local 'docker-powershell-cli-test-3'
    }
    AfterAll {
        docker volume remove 'docker-powershell-cli-test-1' 'docker-powershell-cli-test-2' 'docker-powershell-cli-test-3'
        $script:RemoveModule | Where-Object { $_ } | Remove-Module
    }
    It 'Gets all volumes' {
        # Arrange

        # Act
        $volumes = Get-DockerVolume

        # Assert (user may have preexisting volumes)
        $volumes.Count | Should -BeGreaterOrEqual 3
    }
    It 'Returns [DockerVolume]' {
        # Arrange

        # Act
        $volumes = Get-DockerVolume

        # Assert
        $volumes | ForEach-Object { $_.GetType().Name | Should -Be 'DockerVolume' }
    }
    Context 'Parameter ''-Name''' {
        It 'Gets volumes by name' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
            @{ Name = 'docker-powershell-cli-test-2', 'docker-powershell-cli-test-3' }
        ) {
            # Arrange

            # Act
            $volumes = Get-DockerVolume -Name $Name

            # Assert
            $volumes.Name | Should -Be $Name
        }
        It 'is case-insensitive' -TestCases @(
            @{ Name = 'DOCKER-powershell-cli-test-1' }
        ) {
            # Arrange
            $Expected = $Name.ToLower()

            # Act
            $volumes = Get-DockerVolume -Name $Name

            # Assert
            $volumes.Name | Should -BeExactly $Expected
        }
        It 'supports wildcards' -TestCases @(
            @{ 
                Name     = 'docker-powershell-cli-test-?'
                Expected = @(
                    'docker-powershell-cli-test-1'
                    'docker-powershell-cli-test-2'
                    'docker-powershell-cli-test-3'
                ) 
            }
            @{
                Name     = 'docker-powershell-cli-t*'
                Expected = @(
                    'docker-powershell-cli-test-1'
                    'docker-powershell-cli-test-2'
                    'docker-powershell-cli-test-3'
                )
            }
            @{
                Name     = '*-cli-test-[12]'
                Expected = @(
                    'docker-powershell-cli-test-1'
                    'docker-powershell-cli-test-2'
                )
            }
        ) {
            # Arrange

            # Act
            $volumes = Get-DockerVolume -Name $Name

            # Assert
            $volumes.Name | Should -Be $Expected
        }
        It 'gets everything for ''*''' {
            # Arrange

            # Act
            $Volumes = Get-DockerVolume -Name '*'

            # Assert
            $Volumes | Should -Not -BeNullOrEmpty
        }
        It 'succeeds when volume exists' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1' }
            @{ Name = 'docker-powershell-cli-test-2', 'docker-powershell-cli-test-3' }
        ) {
            # Arrange

            # Act

            # Assert
            { Get-DockerVolume -Name $Name -ErrorAction Stop } | Should -Not -Throw
        }
        It 'does not duplicate results' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-1', 'docker-powershell-cli-test-1' }
        ) {
            # Arrange
            $Expected = $Name | Select-Object -Unique

            # Act
            $volumes = Get-DockerVolume -Name $Name

            # Assert
            $volumes.Name | Should -Be $Expected
        }
        It 'returns nothing if no volumes match' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-4' }
        ) {
            # Arrange

            # Act
            $volumes = Get-DockerVolume -Name $Name -ErrorAction Ignore

            # Assert
            $volumes | Should -BeNullOrEmpty
        }
        It 'reports a non-terminal error when not found' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-4' }
        ) {
            # Arrange
            $e = $null

            # Act
            { Get-DockerVolume -Name $Name -ErrorAction SilentlyContinue -ErrorVariable e } | Should -Not -Throw

            # Assert
            $e | Should -HaveCount 1
        }
        It 'reports FullyQualifiedErrorId ''VolumeNameNotFound,Get-DockerVolume'' when not found' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-4' }
            @{ Name = 'docker-powershell-cli-test-4', 'docker-powershell-cli-test-5' }
        ) {
            # Arrange
            $Expected = $Name | ForEach-Object { 'VolumeNameNotFound,Get-DockerVolume' }

            # Act
            Get-DockerVolume -Name $Name -ErrorAction SilentlyContinue -ErrorVariable e

            # Assert
            $e.FullyQualifiedErrorId | Should -Be $Expected
        }
        It 'reports error message "No such volume: ''{name}''." when not found' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-4' }
            @{ Name = 'docker-powershell-cli-test-4', 'docker-powershell-cli-test-5' }
        ) {
            # Arrange
            $Expected = $Name | ForEach-Object { "No such volume: '$_'." }

            # Act
            Get-DockerVolume -Name $Name -ErrorAction SilentlyContinue -ErrorVariable e

            # Assert
            $e.ErrorDetails.Message | Should -Be $Expected
        }
        It 'reports [ItemNotFoundException] when not found' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-4' }
            @{ Name = 'docker-powershell-cli-test-4', 'docker-powershell-cli-test-5' }
        ) {
            # Arrange

            # Act
            Get-DockerVolume -Name $Name -ErrorAction SilentlyContinue -ErrorVariable e

            # Assert
            $e.Exception | Should -BeOfType System.Management.Automation.ItemNotFoundException
        }
        It 'reports ErrorCategory ''ObjectNotFound'' when not found' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-4' }
            @{ Name = 'docker-powershell-cli-test-4', 'docker-powershell-cli-test-5' }
        ) {
            # Arrange
            $Expected = $Name | ForEach-Object { 'ObjectNotFound' }

            # Act
            Get-DockerVolume -Name $Name -ErrorAction SilentlyContinue -ErrorVariable e

            # Assert
            $e.CategoryInfo.Category | Should -Be $Expected
        }
        It 'reports TargetObject $Name when not found' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-4' }
            @{ Name = 'docker-powershell-cli-test-4', 'docker-powershell-cli-test-5' }
        ) {
            # Arrange
            $Expected = $Name

            # Act
            Get-DockerVolume -Name $Name -ErrorAction SilentlyContinue -ErrorVariable e
            $Actual = $e.TargetObject

            # Assert
            $Actual | Should -Be $Expected
        }
        It 'does not report an error when a wildcard is present' -TestCases @(
            @{ Name = 'docker-powershell-cli-test-4*' }
            @{ Name = 'docker-powershell-cli-test-4*', '*docker-powershell-cli-test-5' }
        ) {
            # Arrange

            # Act

            # Assert
            { Get-DockerVolume -Name $Name -ErrorAction Stop } | Should -Not -Throw
        }
    }
    Context 'Parameter ''-Dangling''' {
        It 'returns volumes not associated to a container' {
            # Arrange
            docker container create --name docker-powershell-cli-test-1 -v docker-powershell-cli-test-1:/mnt alpine:3.8

            try {
                # Act
                $volumes = Get-DockerVolume -Dangling

                # Assert
                $volumes.Name | Should -Not -Contain 'docker-powershell-cli-test-1'
                $volumes.Name | Should -Contain 'docker-powershell-cli-test-2'
                $volumes.Name | Should -Contain 'docker-powershell-cli-test-3'
            }
            finally {
                docker container rm -f docker-powershell-cli-test-1
            }
        }
        It 'returns nothing if no volumes are dangling' {
            # Arrange
            docker container create --name docker-powershell-cli-test-1 -v docker-powershell-cli-test-1:/mnt alpine:3.8
            docker container create --name docker-powershell-cli-test-2 -v docker-powershell-cli-test-2:/mnt alpine:3.8
            docker container create --name docker-powershell-cli-test-3 -v docker-powershell-cli-test-3:/mnt alpine:3.8

            try {
                # Act
                $volumes = Get-DockerVolume -Dangling -Name 'docker-powershell-cli-test-?'

                # Assert
                $volumes | Should -BeNullOrEmpty
            }
            finally {
                docker container rm -f docker-powershell-cli-test-1 docker-powershell-cli-test-2 docker-powershell-cli-test-3
            }
        }
        It 'reports no error if no volumes are found' {
            # Arrange
            $i = 0
            $RemoveContainers = docker volume list --filter dangling=true --quiet | ForEach-Object {
                docker container create --name="docker-powershell-cli-test-n-$(($i++))" -v ${_}:/mnt alpine:3.8
            }

            try {
                # Act
                # Assert
                { Get-DockerVolume -Dangling -ErrorAction Stop } | Should -Not -Throw
            }
            finally {
                docker container remove --force $RemoveContainers
            }
        }
        It 'reports an error if no dangling volumes are found when a name is specified' {
            # Arrange
            docker container create --name docker-powershell-cli-test-1 -v docker-powershell-cli-test-1:/mnt alpine:3.8
            try {
                # Act
                Get-DockerVolume -Dangling -Name 'docker-powershell-cli-test-1' -ErrorVariable e -ErrorAction SilentlyContinue
            
                # Assert
                $e.Exception | Should -BeOfType System.Management.Automation.ItemNotFoundException
            }
            finally {
                docker container rm -f docker-powershell-cli-test-1
            }
        }
    }
}