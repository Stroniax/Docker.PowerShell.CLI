# This script will build the dind-pwsh image, which is used to run tests

docker build -f $PSScriptRoot/Dockerfile -t dind-pwsh $PSScriptRoot