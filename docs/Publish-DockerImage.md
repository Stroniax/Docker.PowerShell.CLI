---
external help file: Docker.PowerShell.CLI-help.xml
Module Name: Docker.PowerShell.CLI
online version:
schema: 2.0.0
---

# Publish-DockerImage

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### FullName (Default)
```
Publish-DockerImage [-FullName] <String[]> [-DisableContentTrust] [-PassThru] [-Context <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### FullNameJob
```
Publish-DockerImage [-FullName] <String[]> [-DisableContentTrust] [-AsJob] [-Context <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### AllTagsJob
```
Publish-DockerImage [-Name] <String> [-AllTags] [-DisableContentTrust] [-AsJob] [-Context <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### AllTags
```
Publish-DockerImage [-Name] <String> [-AllTags] [-DisableContentTrust] [-PassThru] [-Context <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### NameJob
```
Publish-DockerImage [-Name] <String> [-Tag] <String> [-DisableContentTrust] [-AsJob] [-Context <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Name
```
Publish-DockerImage [-Name] <String> [-Tag] <String> [-DisableContentTrust] [-PassThru] [-Context <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdJob
```
Publish-DockerImage -Id <String> [-DisableContentTrust] [-AsJob] [-Context <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Id
```
Publish-DockerImage -Id <String> [-DisableContentTrust] [-PassThru] [-Context <String>] [-WhatIf] [-Confirm]
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

### -AllTags
{{ Fill AllTags Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: AllTagsJob, AllTags
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsJob
{{ Fill AsJob Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: FullNameJob, AllTagsJob, NameJob, IdJob
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

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

### -DisableContentTrust
{{ Fill DisableContentTrust Description }}

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

### -FullName
{{ Fill FullName Description }}

```yaml
Type: System.String[]
Parameter Sets: FullName, FullNameJob
Aliases: Reference

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Id
{{ Fill Id Description }}

```yaml
Type: System.String
Parameter Sets: IdJob, Id
Aliases: ImageId

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
{{ Fill Name Description }}

```yaml
Type: System.String
Parameter Sets: AllTagsJob, AllTags, NameJob, Name
Aliases: ImageName, RepositoryName

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PassThru
{{ Fill PassThru Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: FullName, AllTags, Name, Id
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tag
{{ Fill Tag Description }}

```yaml
Type: System.String
Parameter Sets: NameJob, Name
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### System.String[]
### System.String
## OUTPUTS

### DockerImage
### Docker.PowerShell.CLI.DockerPushJob
## NOTES

## RELATED LINKS
