Write-Host @"
###############################################
#          OpenDevin Start Frontend           #
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

$backendHost = Read-Host "Enter the backend host (default: 127.0.0.1)"
if($null -eq $backendHost -or $backendHost -eq "") {
    $backendHost = "127.0.0.1"
}
$backendPort = Read-Host "Enter the backend port (default: 3000)"
if($null -eq $backendPort -or $backendPort -eq "") {
    $backendPort = "3000"
}
$frontendPort = Read-Host "Enter frontend port (default: 3001)"
if($null -eq $frontendPort -or $frontendPort -eq "") {
    $frontendPort = "3001"
}

Write-Host "Opening OpenDevin environment" -ForegroundColor Green
$envFolder = "opendevin_env"
if (Test-Path $envFolder) {
    Set-Location $envFolder
} else {
    Write-Host "The $envFolder folder not found. Please run the installation before using this script. Exiting." -ForegroundColor Red
    exit
}

$projFolder = "OpenDevin"
if (Test-Path $projFolder) {
    Set-Location $projFolder
} else {
    Write-Host "The $projFolder folder not found. Please run the installation before using this script. Exiting." -ForegroundColor Red
    exit
}

# Set the environment variables
$env:BACKEND_HOST = $backendHost+":"+$backendPort
$env:FRONTEND_POST = $frontendPort

# Run the command
Write-Host "Starting frontend" -ForegroundColor Green
Set-Location "frontend"
pnpm run start

Set-Location $PSScriptRoot