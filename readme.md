# Docker.PowerShell.CLI

[Docker.PowerShell.CLI](https://github.com/Stroniax/Docker.PowerShell.CLI) is a PowerShell wrapper for the Docker
command-line tool. It is designed to be cross-compatible and supports parameter completion, the pipeline, and
rich object models returned from commands.

For more information about the module, see the [help documentation](./docs/Docker.PowerShell.CLI.md).

## Requirements

- PowerShell 5.1 or PowerShell Core
- [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/)

### Installation

#### PowerShell Gallery

The module is available on the [PowerShell Gallery](https://www.powershellgallery.com/packages/Docker.PowerShell.CLI/).
To install it, run the following command:

```powershell
Install-Module 'Docker.PowerShell.CLI' -Repository PSGallery # -Scope CurrentUser
```

## Usage

To use the module, import it with `Import-Module Docker.PowerShell.CLI`. The module will automatically detect the
location of the Docker executable and use it. If you need to specify a different location, use the `Set-DockerPath`
command.

## Contributing

Contributions are welcome.

This module is developed using Visual Studio Code. There are build, test, and launch profiles which
can be used when developing the module.

## License

This project is licensed under the [MIT License](./LICENSE).

## Acknowledgements

This project is based on the [Docker CLI](https://github.com/docker/cli) by Docker.
