$ErrorActionPreference='Stop'
$destination=Join-Path $env:USERPROFILE '.codex\pets\voira-chatgpt'
if(Test-Path -LiteralPath $destination){Write-Output 'The pet directory already exists; no files were overwritten.';exit 0}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets\pet.json') -Destination (Join-Path $destination 'pet.json')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets\spritesheet.webp') -Destination (Join-Path $destination 'spritesheet.webp')
Write-Output "Pet files installed: $destination. Select the pet in the application's pet settings if desired."
