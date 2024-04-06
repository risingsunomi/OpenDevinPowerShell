Write-Host @"
###############################################
#          OpenDevin Windows Install          #
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

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "!! Please run this PowerShell script in an administrator PowerShell window to perform needed operations. Exiting." -ForegroundColor Red
    exit
}

# Check Python version
$pythonVersion = python --version
if ($pythonVersion -notmatch "Python 3\.[1-9][1-9]") {
    Write-Host "!! Python version 3.11 or higher is required. Please install the correct version and try again. Exiting." -ForegroundColor Red
    exit
}

# Create a Python virtual environment
Write-Host "Creating and activating a Python virtual environment called 'opendevin_env'" -ForegroundColor Green
$envFolder = "opendevin_env"
if (Test-Path $envFolder) {
    Write-Host "The 'opendevin_env' folder already exists. Skipping virtual environment creation."
    Set-Location $envFolder
} else {
    python -m venv opendevin_env
    Set-Location $envFolder
}

Write-Host "Activating the virtual environment`n" -ForegroundColor Green
.\Scripts\Activate.ps1
Write-Host "`n"

# Clone the project in the virtual environment folder
Write-Host "Cloning the OpenDevin project from github.com/OpenDevin/OpenDevin via HTTPS`n" -ForegroundColor Green
git clone https://github.com/OpenDevin/OpenDevin.git
Set-Location OpenDevin
Write-Host "`n"

# setup configuration toml
Write-Host "Setting up config.toml`n" -ForegroundColor Green

$defaultModel = "text-davinci-003"
$llmModel = Read-Host "Enter your LLM Model name (see https://docs.litellm.ai/docs/providers for full list) [default: $defaultModel]"
$llmModel = ($llmModel | Where-Object { $_ -eq "" })
if ($null -eq $llmModel -or $llmModel -eq "") {
    $llmModel = $defaultModel
}

$llmApiKey = Read-Host "Enter your LLM API key, if any"

Write-Host "Enter your LLM Embedding Model"
Write-Host "Choices are openai, azureopenai, llama2 or leave blank to default to 'BAAI/bge-small-en-v1.5' via huggingface"
$llmEmbeddingModel = Read-Host "> "

if ($llmEmbeddingModel -eq "llama2") {
    $llmBaseUrl = Read-Host "Enter the local model URL"
}
elseif ($llmEmbeddingModel -eq "azureopenai") {
    $llmBaseUrl = Read-Host "Enter the Azure endpoint URL"
    $llmDeploymentName = Read-Host "Enter the Azure LLM Deployment Name"
    $llmApiVersion = Read-Host "Enter the Azure API Version"
}

Write-Host "Enter your workspace directory or leave blank"
Write-Host "For windows, please specify the full path"
$workspaceDir = Read-Host "> "

$configFile = "config.toml"
@"
LLM_MODEL="$llmModel"
LLM_API_KEY="$llmApiKey"
LLM_EMBEDDING_MODEL="$llmEmbeddingModel"
$(if($workspaceDir -ne "" -or $null -ne $workspaceDir) {
    "WORKSPACE_DIR=`"$workspaceDir`""
})
$(if ($llmEmbeddingModel -eq "llama2" -or $llmEmbeddingModel -eq "azureopenai") {
    "LLM_BASE_URL=`"$llmBaseUrl`""
})
$(if ($llmEmbeddingModel -eq "azureopenai") {
    "LLM_DEPLOYMENT_NAME=`"$llmDeploymentName`"
LLM_API_VERSION=`"$llmApiVersion`"
LLM_BASE_URL=`"$llmBaseUrl`""
})

"@ | Out-File -FilePath $configFile -Encoding UTF8NoBOM

Write-Host "`n"

# Pull the Docker image
Write-Host "Pulling docker image ghcr.io/opendevin/sandbox`n" -ForegroundColor Green
docker pull ghcr.io/opendevin/sandbox
Write-Host "`n"

# Install Poetry
Write-Host "Installing poetry with pip" -ForegroundColor Green
pip install poetry
Write-Host "`n"

# Install dependencies using Poetry (without evaluation)
Write-Host "Starting poetry install of dependencies`n" -ForegroundColor Green
poetry install --without evaluation
Write-Host "`n"

# Install pre-commit hooks
Write-Host "Installing git pre-commit hooks via poetry`n" -ForegroundColor Green
poetry run pre-commit install --config ./dev_config/python/.pre-commit-config.yaml

# Change to the frontend directory
Write-Host "Setting up frontend" -ForegroundColor Green
Set-Location frontend

# Check if package-lock.json exists
if (Test-Path -Path "package-lock.json") {
    Write-Host "`nThis project currently uses 'pnpm' for dependency management. It has detected that dependencies were previously installed using 'npm' and has automatically deleted the 'node_modules' directory to prevent unnecessary conflicts.`n" -ForegroundColor DarkYellow
    if (Test-Path -Path "node_modules") {
        Remove-Item -Path "node_modules" -Recurse -Force
    }
}

# Check if npm corepack is installed
Write-Host "Enabling corepack" -ForegroundColor Green
if (-not (Get-Command -Name "corepack" -ErrorAction SilentlyContinue)) {
    # Install npm corepack globally
    Write-Host "corepack not found, installing corepack via npm" -ForegroundColor DarkYellow
    npm install -g corepack
}

# Enable corepack (requires administrator privileges)
corepack enable

# Change the execution policy to allow running pnpm
Write-Host "Setting ExecutionPolicy to RemoteSigned for pnpm install" -ForegroundColor Green
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

# Install dependencies using pnpm and run make-i18n
Write-Host "Running pnpm install and run make-i18n`n" -ForegroundColor Green
npm install
npm run make-i18n
Write-Host "`n"

Write-Host "Installation of OpenDevin Completed" -ForegroundColor Green
Set-Location $PSScriptRoot