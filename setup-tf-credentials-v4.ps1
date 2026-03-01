# Terraform AWS Credentials Setup Script V4 (PowerShell Version)
# Reads config from tf-input.txt -> Clears stale credentials -> AWS Login -> STS Assume Role -> Write to ~/.aws/credentials [terraform] profile
# Unlike v1-v3, this version does NOT write credentials into providers.tf or backend.tf.
# Instead, it sets up the [terraform] profile in ~/.aws/credentials so Terraform uses it via AWS_PROFILE or provider profile config.

# --- Step 0: Read Configuration from tf-input.txt ---
$InputFile = Join-Path $PSScriptRoot "tf-input.txt"
$RoleArn = $null
$AwsProfile = "tf"
$AwsRegion = "ap-northeast-1"

if (Test-Path $InputFile) {
    Write-Host "Reading configuration from $InputFile..." -ForegroundColor Cyan
    $lines = Get-Content $InputFile
    foreach ($line in $lines) {
        if ($line -match "^IAMRoleARN=(.*)") {
            $RoleArn = $matches[1].Trim()
            Write-Host "  IAMRoleARN: $RoleArn"
        }
        if ($line -match "^AwsProfile=(.*)") {
            $AwsProfile = $matches[1].Trim()
            Write-Host "  AwsProfile: $AwsProfile"
        }
        if ($line -match "^AwsRegion=(.*)") {
            $AwsRegion = $matches[1].Trim()
            Write-Host "  AwsRegion: $AwsRegion"
        }
    }
} else {
    Write-Warning "tf-input.txt not found. Falling back to manual input."
}

# --- Step 1: Input Validation ---

# Prompt for inputs if not provided (or not found in file)
if ([string]::IsNullOrWhiteSpace($RoleArn)) {
    $RoleArn = Read-Host "Please enter IAM Role ARN (e.g., arn:aws:iam::123456789012:role/YourRoleName)"
}

# Auto-fix ARN if missing 'arn:' prefix
if (-not [string]::IsNullOrWhiteSpace($RoleArn) -and -not $RoleArn.StartsWith("arn:")) {
    $RoleArn = "arn:" + $RoleArn
    Write-Host "Added missing 'arn:' prefix to Role ARN." -ForegroundColor Yellow
}

if ([string]::IsNullOrWhiteSpace($RoleArn)) {
    Write-Error "IAM Role ARN is required."
    exit 1
}

# --- Step 2: Clear Stale Credentials ---
Write-Host "`n--- Step 1: Clearing stale [$AwsProfile] credentials ---"
$credsPath = "$env:USERPROFILE\.aws\credentials"

if (Test-Path $credsPath) {
    $content = Get-Content $credsPath
    $newContent = @()
    $skipping = $false
    $found = $false

    foreach ($line in $content) {
        if ($line -match "^\[$([regex]::Escape($AwsProfile))\]") {
            $skipping = $true
            $found = $true
            Write-Host "Found stale [$AwsProfile] profile. Removing..." -ForegroundColor Yellow
            continue
        }
        if ($skipping -and $line -match "^\[") {
            $skipping = $false
        }
        if (-not $skipping) {
            $newContent += $line
        }
    }

    if ($found) {
        Set-Content $credsPath $newContent
        Write-Host "Successfully removed stale [$AwsProfile] profile." -ForegroundColor Green
    } else {
        Write-Host "No stale [$AwsProfile] profile found." -ForegroundColor Cyan
    }
} else {
    Write-Host "Credentials file not found. It will be created."
}

# --- Step 3: AWS Login ---
Write-Host "`n--- Step 2: Executing AWS Login ---"
aws login --profile $AwsProfile

if ($LASTEXITCODE -ne 0) {
    Write-Error "AWS Login failed. Please check your credentials and try again."
    exit 1
}

# Wait for user confirmation
Read-Host "Login completed? Press Enter to continue to STS Assume Role..."

# --- Step 4: AWS STS Assume Role ---
Write-Host "`n--- Step 3: Assuming IAM Role ---"
try {
    $jsonOutput = aws sts assume-role --profile $AwsProfile --role-arn $RoleArn --role-session-name TerraformSession --output json
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed"
    }
    $credentials = $jsonOutput | ConvertFrom-Json
}
catch {
    Write-Error "Failed to assume role or parse output."
    Write-Error $_
    exit 1
}

$accessKeyId = $credentials.Credentials.AccessKeyId
$secretAccessKey = $credentials.Credentials.SecretAccessKey
$sessionToken = $credentials.Credentials.SessionToken
$expiration = $credentials.Credentials.Expiration

if (-not $accessKeyId) {
    Write-Error "Failed to retrieve AccessKeyId."
    exit 1
}

# --- Step 5: Write session credentials to ~/.aws/credentials ---
Write-Host "`n--- Step 4: Writing session credentials to ~/.aws/credentials [$AwsProfile] profile ---"

# Ensure ~/.aws directory exists
$awsDir = "$env:USERPROFILE\.aws"
if (-not (Test-Path $awsDir)) {
    New-Item -ItemType Directory -Path $awsDir -Force | Out-Null
    Write-Host "Created $awsDir directory." -ForegroundColor Yellow
}

# Build the new profile block
$profileBlock = @(
    "[$AwsProfile]"
    "aws_access_key_id = $accessKeyId"
    "aws_secret_access_key = $secretAccessKey"
    "aws_session_token = $sessionToken"
)

# Append to credentials file
if (Test-Path $credsPath) {
    # Add a blank line before the new profile if the file doesn't end with one
    $existingContent = Get-Content $credsPath -Raw
    if ($existingContent -and -not $existingContent.EndsWith("`n`n")) {
        Add-Content $credsPath ""
    }
    Add-Content $credsPath ($profileBlock -join "`n")
} else {
    Set-Content $credsPath ($profileBlock -join "`n")
}

Write-Host "Session credentials written to ~/.aws/credentials [$AwsProfile] profile." -ForegroundColor Green

# --- Step 6: Write profile config to ~/.aws/config ---
Write-Host "`n--- Step 5: Writing profile config to ~/.aws/config [profile $AwsProfile] ---"
$configPath = "$env:USERPROFILE\.aws\config"
$configProfileHeader = "[profile $AwsProfile]"

# Remove stale profile from config if exists
if (Test-Path $configPath) {
    $configContent = Get-Content $configPath
    $newConfigContent = @()
    $skipping = $false
    $found = $false

    foreach ($line in $configContent) {
        if ($line -match "^\[profile\s+$([regex]::Escape($AwsProfile))\]") {
            $skipping = $true
            $found = $true
            Write-Host "Found stale [profile $AwsProfile] in config. Removing..." -ForegroundColor Yellow
            continue
        }
        if ($skipping -and $line -match "^\[") {
            $skipping = $false
        }
        if (-not $skipping) {
            $newConfigContent += $line
        }
    }

    if ($found) {
        Set-Content $configPath $newConfigContent
    }
}

# Build the new config profile block
$configBlock = @(
    $configProfileHeader
    "region = $AwsRegion"
    "output = json"
)

# Append to config file
if (Test-Path $configPath) {
    $existingConfig = Get-Content $configPath -Raw
    if ($existingConfig -and -not $existingConfig.EndsWith("`n`n")) {
        Add-Content $configPath ""
    }
    Add-Content $configPath ($configBlock -join "`n")
} else {
    Set-Content $configPath ($configBlock -join "`n")
}

Write-Host "Profile config written to ~/.aws/config [profile $AwsProfile]." -ForegroundColor Green

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "AWS Profile: $AwsProfile"
Write-Host "Expiration: $expiration"
Write-Host "Region: $AwsRegion"
Write-Host "Credentials File: $credsPath"
Write-Host "Config File: $configPath"
Write-Host ""
Write-Host "To use with Terraform, set the profile in your provider block:" -ForegroundColor Yellow
Write-Host '  provider "aws" {'
Write-Host "    profile = `"$AwsProfile`""
Write-Host '    region  = "ap-northeast-1"'
Write-Host '  }'
Write-Host ""
Write-Host "Or set the environment variable:" -ForegroundColor Yellow
Write-Host "  `$env:AWS_PROFILE = `"$AwsProfile`""
Write-Host ""
Write-Host "=== IMPORTANT / 重要 ===" -ForegroundColor Red
Write-Host "Please run the following command in your terminal to activate the profile:" -ForegroundColor Yellow
Write-Host "以下のコマンドをターミナルで実行してプロファイルを有効化してください:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  `$env:AWS_PROFILE = `"$AwsProfile`"" -ForegroundColor White
Write-Host ""
Write-Host "(This must be run in each new terminal session / 新しいターミナルを開くたびに実行が必要です)" -ForegroundColor DarkGray
