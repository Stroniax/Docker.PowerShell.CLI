---
external help file: Docker.PowerShell.CLI-help.xml
Module Name: Docker.PowerShell.CLI
online version:
schema: 2.0.0
---

# Install-DockerImage

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### FullName (Default)
```
Install-DockerImage [[-FullName] <String[]>] [-DisableContentTrust] [-Platform <String>] [-PassThru]
 [-Context <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### FullNameJob
```
Install-DockerImage [[-FullName] <String[]>] [-DisableContentTrust] [-Platform <String>] [-PassThru] [-AsJob]
 [-Context <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### NameDigestJob
```
Install-DockerImage [[-Name] <String>] -Digest <String> [-DisableContentTrust] [-Platform <String>] [-PassThru]
 [-AsJob] [-Context <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### NameAllTagsJob
```
Install-DockerImage [[-Name] <String>] [-AllTags] [-DisableContentTrust] [-Platform <String>] [-PassThru]
 [-AsJob] [-Context <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### NameTagJob
```
Install-DockerImage [[-Name] <String>] -Tag <String> [-DisableContentTrust] [-Platform <String>] [-PassThru]
 [-AsJob] [-Context <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### NameDigest
```
Install-DockerImage [[-Name] <String>] -Digest <String> [-DisableContentTrust] [-Platform <String>] [-PassThru]
 [-Context <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### NameAllTags
```
Install-DockerImage [[-Name] <String>] [-AllTags] [-DisableContentTrust] [-Platform <String>] [-PassThru]
 [-Context <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### NameTag
```
Install-DockerImage [[-Name] <String>] -Tag <String> [-DisableContentTrust] [-Platform <String>] [-PassThru]
 [-Context <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -AllTags
{{ Fill AllTags Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: NameAllTagsJob, NameAllTags
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsJob
{{ Fill AsJob Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: FullNameJob, NameDigestJob, NameAllTagsJob, NameTagJob
Aliases:

Required: True
Position: Named
Default value: None
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
Default value: None
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

### -Digest
{{ Fill Digest Description }}

```yaml
Type: System.String
Parameter Sets: NameDigestJob, NameDigest
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FullName
{{ Fill FullName Description }}

```yaml
Type: System.String[]
Parameter Sets: FullName, FullNameJob
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
{{ Fill Name Description }}

```yaml
Type: System.String
Parameter Sets: NameDigestJob, NameAllTagsJob, NameTagJob, NameDigest, NameAllTags, NameTag
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
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
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Platform
{{ Fill Platform Description }}

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

### -Tag
{{ Fill Tag Description }}

```yaml
Type: System.String
Parameter Sets: NameTagJob, NameTag
Aliases:

Required: True
Position: Named
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
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
## OUTPUTS

### DockerImage
### DockerImage
### DockerImage
### DockerImage
### Docker.PowerShell.CLI.DockerPullJob
### NameTagJob
### NameAllTagsJob
### NameDigestJob
## NOTES

## RELATED LINKS
