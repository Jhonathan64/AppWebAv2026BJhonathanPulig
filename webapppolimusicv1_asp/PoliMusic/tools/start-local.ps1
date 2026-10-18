$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$iis = Join-Path $env:ProgramFiles 'IIS Express\iisexpress.exe'
$template = Join-Path $env:ProgramFiles 'IIS Express\config\templates\PersonalWebServer\applicationhost.config'
$local = Join-Path $project '.local-iis'
New-Item -ItemType Directory -Force $local | Out-Null
[xml]$config = Get-Content -LiteralPath $template
$site = $config.configuration.'system.applicationHost'.sites.site | Select-Object -First 1
$site.name = 'PoliMusic'
$site.application.virtualDirectory.physicalPath = Join-Path $project 'site'
$site.bindings.binding.bindingInformation = '*:8085:localhost'
$config.configuration.'system.webServer'.asp.SetAttribute('enableParentPaths', 'true')
$configPath = Join-Path $local 'applicationhost.config'
$config.Save($configPath)
& $iis "/config:$configPath" /site:PoliMusic /systray:false
