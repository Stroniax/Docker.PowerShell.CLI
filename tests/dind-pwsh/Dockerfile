# Build: docker build -t dind-pwsh .
# This dockerfile creates an image of docker-in-docker with PowerShell installed
# dind-pwsh is the base image for containers used for testing the docker.powershell.cli module

FROM docker:dind

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

RUN mkdir /usr/local/bin/dind-pwsh-setup
COPY ./dind-pwsh-entrypoint.ps1 /usr/local/bin/

WORKDIR /usr/local/bin/
ENTRYPOINT ["pwsh", "-NoExit", "-File", "/usr/local/bin/dind-pwsh-entrypoint.ps1"]

# To connect to the container interactively in PowerShell with the daemon running:
# docker run --privileged --name dind-pwsh -it dind-pwsh

# Derived containers can insert additional PowerShell setup into the dind-pwsh-setup folder
