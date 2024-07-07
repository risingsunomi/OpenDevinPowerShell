###############################################
#          OpenDevin Windows Install          #
#                                             #
#        Created for Windows 10 and 11        #
#                                             #
#        github.com/OpenDevin/OpenDevin       #
#                                             #
# github.com/risingsunomi/OpenDevinPowerShell #
###############################################

# --- helper functions ---- #

# Get-FullPath
# return full path to folder relative to powershell script
function Get-FullPath {
    param (
        [string]$relativePath
    )

    if ([System.IO.Path]::IsPathRooted($relativePath)) {
        $fullPath = $relativePath
    } else {
        $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $relativePath
    }

    # Escape backslashes
    $escapedPath = $fullPath -replace '\\', '\\'

    Write-Output $escapedPath
}

# --- script variables --- #

$defaultModel = "gpt-4o"
$pythonVersion = python --version
$envFolder = Get-FullPath -relativePath "opendevin_env"
$defaultWorkspaceDir = Get-FullPath -relativePath "opendevin_env/OpenDevin/workspace"
$defaultCache = Get-FullPath -relativePath "opendevin_env/OpenDevin/opendevin/.cache"
$configFile = Get-FullPath -relativePath "opendevin_env/OpenDevin/config.toml"


# --- script --- #

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

#############################
# check if running as admin #
#############################

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "!! Please run this PowerShell script in an administrator PowerShell window to perform needed operations. Exiting." -ForegroundColor Red
    exit
}

########################
# check python version #
########################

if ($pythonVersion -notmatch "Python 3\.[1-9][1-9]") {
    Write-Host "!! Python version 3.11 or higher is required. Please install the correct version and try again. Exiting." -ForegroundColor Red
    exit
}

##########################
# create opendevin pyenv #
##########################

Write-Host "Creating and activating a Python virtual environment called 'opendevin_env'" -ForegroundColor Green
if (Test-Path $envFolder) {
    Write-Host "The 'opendevin_env' folder already exists. Skipping virtual environment creation."
} else {
    python -m venv opendevin_env
}
Set-Location $envFolder

Write-Host "Activating the virtual environment" -ForegroundColor Green
.\Scripts\Activate.ps1


##########################
# clone opendevin github #
##########################

Write-Host "Cloning the OpenDevin project from github.com/OpenDevin/OpenDevin via HTTPS" -ForegroundColor Green
if (Test-Path "$envFolder/OpenDevin") {
    Write-Host "OpenDevin project already cloned. Skipping."
} else {
    git clone https://github.com/OpenDevin/OpenDevin.git
}
Set-Location OpenDevin

##############
# setup toml #
##############

Write-Host "Setting up config.toml" -ForegroundColor Green

###############
# core config #
###############

$workspaceBase = Read-Host "Enter your workspace directory (as absolute path) or press enter for default [default: $defaultWorkspaceDir]"
if($workspaceBase -eq "") {
    $workspaceBase = $defaultWorkspaceDir;
} else {
    $workspaceBase = Get-FullPath -relativePath $workspaceBase;
}

# create workspace folder if needed
if($null -eq $workspaceBase -or $workspaceBase -eq "") {
    if (!(Test-Path -Path $workspaceBase)) {
        # Create the folder if it doesn't exist
        Write-Host "Creating workspace directory at $workspaceBase" -ForegroundColor DarkYellow
        New-Item -ItemType Directory -Path $workspaceBase | Out-Null
    }
}

$presistSandbox = Read-Host "Do you want to persist the sandbox container? [true/false] [default: false]"
try {
    $presistSandbox = [System.Convert]::ToBoolean($presistSandbox)
    if ($presistSandbox -eq $true) {
        $sshPassword = Read-Host "Enter a password for the sandbox container"
        $presistSandbox = "true"
    } else {
        $sshPassword = ""
        $presistSandbox = "false"
    }
} catch [System.FormatException] {
    $presistSandbox = "false"
}

##############
# llm config #
##############

$llmModel = Read-Host "Enter your LLM Model name (see https://docs.litellm.ai/docs/providers for full list) [default: $defaultModel]"
$llmModel = ($llmModel | Where-Object { $_ -eq "" })
if ($null -eq $llmModel -or $llmModel -eq "") {
    $llmModel = $defaultModel
}

$llmAPIKey = Read-Host "Enter your LLM API key, press enter if none"

$llmBaseUrl = Read-Host "Enter your LLM base URL (mostly used for local LLMs, press enter if not needed - example: http://localhost:5001/v1/)"

Write-Host "Enter your LLM Embedding Model"
Write-Host "Choices are: 
- openai
- azureopenai
- Embeddings available only with OllamaEmbedding:
    - llama2
    - mxbai-embed-large
    - nomic-embed-text
    - all-minilm
    - stable-code
- Leave blank to default to 'BAAI/bge-small-en-v1.5' via huggingface"
$llmEmbeddingModel = Read-Host "> "

if ($llmEmbeddingModel -eq "llama2" -or $llmEmbeddingModel -eq "mxbai-embed-large" -or $llmEmbeddingModel -eq "nomic-embed-text" -or $llmEmbeddingModel -eq "all-minilm" -or $llmEmbeddingModel -eq "stable-code") {
    $llmEmbeddingBaseUrl = Read-Host "Enter the local model URL for the embedding model (will set llm.embedding_base_url)"
}
elseif ($llmEmbeddingModel -eq "azureopenai") {
    $llmBaseUrl = Read-Host "Enter the Azure endpoint URL"
    $llmDeploymentName = Read-Host "Enter the Azure LLM Deployment Name"
    $llmApiVersion = Read-Host "Enter the Azure API Version"
} else {
    $llmEmbeddingModel = "BAAI/bge-small-en-v1.5"
}

######################
# create config file #
######################


$content = @"
[core]
workspace_dir=`"$workspaceBase`"
persist_sandbox=$presistSandbox
ssh_password=`"$sshPassword`"

[llm]
model=`"$llmModel`"
api_key=`"$llmAPIKey`"
base_url=`"$llmBaseUrl`"
llm_embedding_model=`"$llmEmbeddingModel`"
embedding_base_url=`"$llmEmbeddingBaseUrl`"
embedding_deploment_name=`"$llmDeploymentName`"
api_version=`"$llmApiVersion`"
"@
Write-Host "Saving $configFile"
[System.IO.File]::WriteAllLines($configFile, $content)

#######################
# pull sandbox docker #
#######################

Write-Host "Pulling docker image ghcr.io/opendevin/sandbox" -ForegroundColor Green
docker pull ghcr.io/opendevin/sandbox

##################
# install poetry #
##################

Write-Host "Installing poetry with pip" -ForegroundColor Green
pip install poetry

###############################
# install python dependencies #
###############################

Write-Host "Starting poetry install of dependencies" -ForegroundColor Green
poetry install --without evaluation

############################
# install pre-commit hooks #
############################

Write-Host "Installing git pre-commit hooks via poetry" -ForegroundColor Green
poetry run pre-commit install --config ./dev_config/python/.pre-commit-config.yaml

####################################
# change to the frontend directory #
####################################

Write-Host "Setting up frontend" -ForegroundColor Green
Set-Location frontend

######################################
# check if npm corepack is installed #
######################################

Write-Host "Enabling corepack" -ForegroundColor Green
if (-not (Get-Command -Name "corepack" -ErrorAction SilentlyContinue)) {
    # Install npm corepack globally
    Write-Host "corepack not found, installing corepack via npm" -ForegroundColor DarkYellow
    npm install -g corepack
}

#######################################
# enable corepack                     #
# (requires administrator privileges) #
#######################################

corepack enable

############################
# install NPM dependencies #
############################

# Change the execution policy to allow running npm
Write-Host "Setting ExecutionPolicy to RemoteSigned for npm install" -ForegroundColor Green
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

Write-Host "Running npm install and run make-i18n" -ForegroundColor Green
npm install
npm run make-i18n

###############
# clear cache #
###############

Write-Host "Cleaning cache `"$defaultCache`"" -ForegroundColor DarkYellow
Remove-Item -LiteralPath $defaultCache -Force -Recurse

#######
# end #
#######

Write-Host "Installation of OpenDevin Completed" -ForegroundColor Green
Set-Location $PSScriptRoot