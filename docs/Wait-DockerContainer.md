---
external help file: Docker.PowerShell.CLI-help.xml
Module Name: Docker.PowerShell.CLI
online version:
schema: 2.0.0
---

# Wait-DockerContainer

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Id (Default)
```
Wait-DockerContainer -Id <String> [-Context <String>] [<CommonParameters>]
```

### Name
```
Wait-DockerContainer [-Name] <String> [-Context <String>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Context
{{ Fill Context Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
{{ Fill Id Description }}

```yaml
Type: System.String
Parameter Sets: Id
Aliases: Container, ContainerId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
{{ Fill Name Description }}

```yaml
Type: System.String
Parameter Sets: Name
Aliases: ContainerName

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
## OUTPUTS

### System.Management.Automation.Internal.AutomationNull
## NOTES

## RELATED LINKS
