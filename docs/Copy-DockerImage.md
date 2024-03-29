---
external help file: Docker.PowerShell.CLI-help.xml
Module Name: Docker.PowerShell.CLI
online version:
schema: 2.0.0
---

# Copy-DockerImage

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### FullName
```
Copy-DockerImage [-FullName] <String> [-DestinationName] <String> [-PassThru] [-Context <String>] [-WhatIf]
 [-Confirm] [-DestinationTag] <String> [<CommonParameters>]
```

### Id
```
Copy-DockerImage [-DestinationName] <String> -Id <String> [-PassThru] [-Context <String>] [-WhatIf] [-Confirm]
 [-DestinationTag] <String> [<CommonParameters>]
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

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

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

### -DestinationName
{{ Fill DestinationName Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: TargetImage, TargetName, DestinationFullName, DestinationImage, DestinationReference, TargetReference

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DestinationTag
{{ Fill DestinationTag Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: Tag

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -FullName
{{ Fill FullName Description }}

```yaml
Type: System.String
Parameter Sets: FullName
Aliases: Reference, SourceReference, SourceFullName, SourceImage, Source

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: True
```

### -Id
{{ Fill Id Description }}

```yaml
Type: System.String
Parameter Sets: Id
Aliases: ImageId

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
{{ Fill PassThru Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
## OUTPUTS

### DockerImage
## NOTES

## RELATED LINKS
