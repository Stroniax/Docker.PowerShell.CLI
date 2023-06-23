# This script will build the test image and run the tests in a container
# It also will build the interactive module image for manual testing
param(

)

$ErrorActionPreference = 'Stop'
$WorkspaceDirectory = Split-Path $PSScriptRoot -Parent
Push-Location $WorkspaceDirectory
try {
    # Build test image
    docker build . --tag docker-powershell-cli/tests --target test
    # Build interactive module image
    docker build . --tag docker-powershell-cli/dind

    # Run tests
    docker run -it --rm --privileged --name docker-powershell-cli-tests docker-powershell-cli/tests
}
finally {
    Pop-Location
}