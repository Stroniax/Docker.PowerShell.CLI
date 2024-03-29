---
external help file: Docker.PowerShell.CLI-help.xml
Module Name: Docker.PowerShell.CLI
online version:
schema: 2.0.0
---

# Get-DockerImage

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Search (Default)
```
Get-DockerImage [[-InputObject] <String[]>] [-IncludeIntermediateImages] [-Dangling] [-Context <String>]
 [<CommonParameters>]
```

### FullName
```
Get-DockerImage [-FullName <String[]>] [-IncludeIntermediateImages] [-Dangling] [-Context <String>]
 [<CommonParameters>]
```

### Name
```
Get-DockerImage [[-Name] <String[]>] [[-Tag] <String[]>] [-IncludeIntermediateImages] [-Dangling]
 [-Context <String>] [<CommonParameters>]
```

### Id
```
Get-DockerImage [-Id <String[]>] [-IncludeIntermediateImages] [-Dangling] [-Context <String>]
 [<CommonParameters>]
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

### -Dangling
{{ Fill Dangling Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: Untagged

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FullName
{{ Fill FullName Description }}

```yaml
Type: System.String[]
Parameter Sets: FullName
Aliases: Reference

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: True
```

### -Id
{{ Fill Id Description }}

```yaml
Type: System.String[]
Parameter Sets: Id
Aliases: ImageId

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -IncludeIntermediateImages
{{ Fill IncludeIntermediateImages Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: All

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
{{ Fill InputObject Description }}

```yaml
Type: System.String[]
Parameter Sets: Search
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: True
```

### -Name
{{ Fill Name Description }}

```yaml
Type: System.String[]
Parameter Sets: Name
Aliases: RepositoryName, ImageName

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Tag
{{ Fill Tag Description }}

```yaml
Type: System.String[]
Parameter Sets: Name
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]
## OUTPUTS

### DockerImage
## NOTES

## RELATED LINKS
