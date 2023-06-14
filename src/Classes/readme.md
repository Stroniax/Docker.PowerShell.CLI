This directory contains a collection of PowerShell class definitions.
The classes contained here are referenced in multiple scripts within
the project.

There are some classes within this project which exist for the purpose
of static analysis (such as tab-completion of member names). Those types
do not need referenced outside of the file in which they are constructed
and therefore they do not need defined within the Classes directory.

If I later feel that this structure should be changed so that all classes
are contained in this directory, I may. For the time being I believe it
is sufficient to leave such classes with the function that uses them.

What this means is that most completer or validator types will be placed
in this directory (for example, 'DockerNetworkCompleter'). Module output
types will instead be placed in the Get-* file for that type (for example,
[`Get-DockerNetwork.ps1`](../Public/Network/Get-DockerNetwork.ps1) defines
the `[DockerNetwork]` class and the only function that uses it directly,
`Get-DockerNetwork`). An additional side-effect of this decision is that
pipeline input will not be supported directly by value, but I believe
this is acceptable: the Id parameter can be passed by property value,
which will allow for the same effect to be achieved.