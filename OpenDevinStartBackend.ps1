###############################################
#          OpenDevin Start Backend            #
#                                             #
#        Created for Windows 10 and 11        #
#                                             #
#        github.com/OpenDevin/OpenDevin       #
#                                             #
# github.com/risingsunomi/OpenDevinPowerShell #
###############################################


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

# Check if Docker daemon is running
# backend controller will crash if docker is not running
try {
    docker info > $null 2>&1
} catch {
    Write-Host "Docker daemon is not running. Please start the Docker daemon or check your Docker installation. Exiting" -ForegroundColor Red
    exit
}

# start wsgi backend
Write-Host "Starting OpenDevin backend server" -ForegroundColor Green
poetry run uvicorn opendevin.server.listen:app --port $backendPort

Set-Location $PSScriptRoot