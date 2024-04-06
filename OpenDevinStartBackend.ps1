Write-Host @"
###############################################
#          OpenDevin Start Backend            #
#                                             #
#        Created for Windows 10 and 11        #
#                                             #
#        github.com/OpenDevin/OpenDevin       #
#                                             #
# github.com/risingsunomi/OpenDevinPowerShell #
###############################################
"@ -ForegroundColor Cyan
$confirmInstall = Read-Host "Proceed? (yes/no)"
if ($confirmInstall -ne "yes") {
    Write-Host "!! Installation aborted. Exiting." -ForegroundColor Red
    exit
}
Write-Host "`n"

$backendPort = Read-Host "Enter backend port (default: 3000)"
if($null -eq $backendPort -or $backendPort -eq "") {
    $backendPort = "3000"
}

Write-Host "Opening OpenDevin environment" -ForegroundColor Green
$envFolder = "opendevin_env"
if (Test-Path $envFolder) {
    Set-Location $envFolder
} else {
    Write-Host "The $envFolder folder not found. Please run the installation before using this script. Exiting." -ForegroundColor Red
    exit
}

Write-Host "Activating the virtual environment" -ForegroundColor Green
.\Scripts\Activate.ps1

$projFolder = "OpenDevin"
if (Test-Path $projFolder) {
    Set-Location $projFolder
} else {
    Write-Host "The $projFolder folder not found. Please run the installation before using this script. Exiting." -ForegroundColor Red
    exit
}

# Read the config.toml file
Write-Host "Setting Windows environment variables from config.toml" -ForegroundColor Green
$configFile = "config.toml"
$configContent = Get-Content -Path $configFile -Raw
$config = ConvertFrom-StringData -StringData $configContent

# Set the environment variables
$env:LLM_MODEL = $config.LLM_MODEL
$env:LLM_API_KEY = $config.LLM_API_KEY
$env:WORKSPACE_DIR = $config.WORKSPACE_DIR
$env:LLM_EMBEDDING_MODEL = $config.LLM_EMBEDDING_MODEL

# start wsgi backend
Write-Host "Starting OpenDevin backend server" -ForegroundColor Green
poetry run uvicorn opendevin.server.listen:app --port $backendPort

Set-Location $PSScriptRoot