# Build: docker build -t dind-pwsh .
# This dockerfile creates an image of docker-in-docker with PowerShell installed
# dind-pwsh is the base image for containers used for testing the docker.powershell.cli module

FROM docker:dind as dind-pwsh

# https://learn.microsoft.com/en-us/powershell/scripting/install/install-alpine?view=powershell-7.3
RUN apk add --no-cache \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    curl \
    ## Personally I don't know what this one does
    && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust \
    # Download the powershell '.tar.gz' archive
    && curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/powershell-7.3.4-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz \
    # Create the target folder where powershell will be placed
    && mkdir -p /opt/microsoft/powershell/7 \
    # Expand powershell to the target folder
    && tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
    # Set execute permissions
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    # Create the symbolic link that points to pwsh
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

SHELL [ "pwsh", "-Command", "$ErrorActionPreference = 'Stop';" ]

# RUN mkdir /usr/local/bin/dind-pwsh-setup
# COPY ./dind-pwsh-entrypoint.ps1 /usr/local/bin/

# WORKDIR /usr/local/bin/

# ENTRYPOINT ["pwsh", "-NoExit", "-File", "/usr/local/bin/dind-pwsh-entrypoint.ps1"]

FROM mcr.microsoft.com/powershell as build-base
SHELL [ "pwsh", "-Command", "$ErrorActionPreference = 'Stop';" ]

# Build documentation using PlatyPS
FROM build-base as build-docs

# Install the module dependencies
RUN Install-Module -Name PlatyPS -Force

# Copy the build script
COPY ./build/build-docs.ps1 ./build-docs.ps1

# Copy the module into the image
COPY ./docs ./docs

# Build the docs
RUN & ./build-docs.ps1 -OutputPath ./out -SourcePath ./docs

# Build the script module file
FROM build-base as build-module

# Copy the build script
COPY ./build/build-scriptmodule.ps1 ./build-scriptmodule.ps1

# Copy the source files
# TODO: only copy .ps1, .psm1
COPY ./src ./src

# Run the build script
RUN & ./build-scriptmodule.ps1 -OutputPath ./out -SourcePath ./src

# Build the types and format files
FROM build-base as build-types

# Copy the build script
COPY ./build/build-ps1xml.ps1 ./build-ps1xml.ps1

# Copy the source files
# TODO: only copy ps1xml files
COPY ./src ./src

# Run the build script
RUN & ./build-ps1xml.ps1 -OutputPath ./out -SourcePath ./src

# Build the manifest
FROM build-base as build-manifest
ARG VERSION=0.0.1-docker

# Copy the build script
COPY ./build/build-manifest.ps1 ./build-manifest.ps1

# Copy the source files
COPY --from=build-docs ./out ./out
COPY --from=build-module ./out ./out
COPY --from=build-types ./out ./out

# Run the build script
RUN & ./build-manifest.ps1 -OutputPath ./out -Version $env:VERSION -SourcePath ./src

# run Pester tests
FROM dind-pwsh as test

# Install the module dependencies
RUN Install-Module -Name Pester -Force -MinimumVersion 5.0

# Copy the tests and the assembled module. Which will be updated last?
# I think we can copy the tests first because they can be added while the module is being built
COPY ./tests ./tests
COPY --from=build-manifest ./out ./src/Docker.PowerShell.CLI

# Run the tests
RUN Import-Module ./src/Docker.PowerShell.CLI && \
    Invoke-Pester -Configuration (\New-PesterConfiguration @{ \
        Run = @{ \
            Path = './tests'; \
            Exit = $true; \
            Throw = $true; \
            PassThru = $true; \
        }; \
        Output = @{ \
            Verbosity = 'Detailed'; \
        } \
    })

# jump back to the dind-pwsh layer and add the build files
FROM dind-pwsh as docker-powershell-cli

COPY --from=build-manifest ./out ./src/Docker.PowerShell.CLI
# COPY --from=test ./src/Docker.PowerShell.CLI ./src/Docker.PowerShell.CLI

ENTRYPOINT ["pwsh", "-NoExit", "-c", "pwsh -wd /usr/local/bin -c /usr/local/bin/dockerd-entrypoint.sh &", "Import-Module ./src/Docker.PowerShell.CLI"]