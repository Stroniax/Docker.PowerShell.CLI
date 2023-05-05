# This docker file uses the dind-pwsh base image and copies the module into the image.

# Build: docker build -t docker.powershell.cli:test .

# dind-pwsh can be built from the dockerfile in the dind-pwsh folder
FROM dind-pwsh

# Copy the module into the image
COPY .. ./docker.powershell.cli

ENTRYPOINT ["pwsh", "-NoExit", "-c", "Import-Module ./docker.powershell.cli"]