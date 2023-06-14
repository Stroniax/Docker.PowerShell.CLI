This directory contains a collection of PowerShell class definitions. The classes contained here are referenced
in multiple scripts within the project.

PowerShell classes are used in this module for two purposes:

1. Docker models which support static analysis. This allows tab-completion, etc. Each of the docker models has
   a PSObject constructor which takes the deserialized JSON, and assigns itself all values of that json object.
   The class will also have a few key members of that type defined on itself, strongly-typed, for tab completion
   or type parsing (e.g. `DateTimeOffset` for `CreatedAt` member).

2. Parameter helpers such as validation and argument completion.
