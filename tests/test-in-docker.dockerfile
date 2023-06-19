FROM mcr.microsoft.com/powershell:latest as build-docs

SHELL ["pwsh", "-Command"]

RUN Install-Module -Name PlatyPS -Force

COPY ./build/build-docs.ps1 /build/
COPY ./docs /docs

RUN & /build/build-docs.ps1 -OutputPath /out

FROM mcr.microsoft.com/powershell:latest as build-scriptmodule
SHELL ["pwsh", "-Command"]

COPY ./build/build-scriptmodule.ps1 /build/
COPY ./src /src

RUN & /build/build-scriptmodule.ps1 -OutputPath /out

FROM mcr.microsoft.com/powershell:latest as build-ps1xml
SHELL ["pwsh", "-Command"]

COPY ./build/build-ps1xml.ps1 /build/
COPY ./src /src

RUN & /build/build-ps1xml.ps1 -OutputPath /out

FROM mcr.microsoft.com/powershell:latest as build-manifest
SHELL ["pwsh", "-Command"]

COPY ./build/build-manifest.ps1 /build/
COPY --from=build-docs /out /out
COPY --from=build-scriptmodule /out /out
COPY --from=build-ps1xml /out /out

RUN & /build/build-manifest.ps1 -OutputPath /out -Version '0.0.1-dockertest'

FROM docker:dind as runtime

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

SHELL [ "pwsh", "-Command" ]

RUN Install-Module -Name Pester -MinimumVersion 5.0 -Force

COPY ./tests /tests
COPY --from=build-manifest /out /src/

CMD Import-Module /src/Docker.PowerShell.CLI.psd1 && Invoke-Pester -Path /tests