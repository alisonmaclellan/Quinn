<#
.SYNOPSIS
    Clones a repository and brings Quinn along for the journey!

.DESCRIPTION
    This script does it all in one command:
    1. Ensures Quinn is installed (runs Install-Quinn if needed)
    2. Clones the specified repository to your chosen folder
    3. Runs Bring-Quinn to copy Quinn's copilot instructions to the new repo

.PARAMETER RepoUrl
    The URL of the repository to clone (required).

.PARAMETER TargetFolder
    The folder where the repo should be cloned. Defaults to current directory.
    The repo name will be appended automatically.

.PARAMETER RepoName
    Optional custom name for the cloned folder. Defaults to the repo name from the URL.

.PARAMETER Alias
    Your username/alias for the copilot-instructions folder. Defaults to $env:USERNAME

.PARAMETER QuinnRepoPath
    Where Quinn is installed. Defaults to ~\source\repos\Quinn

.PARAMETER SkipBringQuinn
    If set, only clones the repo without bringing Quinn.

.EXAMPLE
    Clone-Repo -RepoUrl "https://github.com/user/myproject.git"
    
    Clones myproject to current directory and brings Quinn.

.EXAMPLE
    Clone-Repo -RepoUrl "https://github.com/user/myproject.git" -TargetFolder "C:\Projects"
    
    Clones to C:\Projects\myproject and brings Quinn.

.EXAMPLE
    Clone-Repo -RepoUrl "https://github.com/user/myproject.git" -RepoName "my-custom-name"
    
    Clones to .\my-custom-name and brings Quinn.

.NOTES
    This is the all-in-one command - it will install Quinn automatically if needed.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RepoUrl,

    [Parameter(Position = 1)]
    [string]$TargetFolder = (Get-Location).Path,

    [string]$RepoName,

    [string]$Alias = $env:USERNAME,

    [string]$QuinnRepoPath = (Join-Path $env:USERPROFILE "source\repos\Quinn"),

    [switch]$SkipBringQuinn
)

# Friendly greeting
Write-Host "`n🚀 " -NoNewline
Write-Host "Clone-Repo" -ForegroundColor Cyan -NoNewline
Write-Host " 🚀`n"

# Check if git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git is not installed or not in PATH." -ForegroundColor Red
    Write-Host "   Please install Git and try again.`n"
    return
}

# Step 1: Ensure Quinn is installed
Write-Host "📋 Step 1: Checking Quinn installation..." -ForegroundColor Gray

$installQuinnPath = Join-Path $PSScriptRoot "Install-Quinn.ps1"
$bringQuinnPath = Join-Path $QuinnRepoPath "scripts\Bring-Quinn.ps1"

if (-not (Test-Path $QuinnRepoPath) -or -not (Test-Path $bringQuinnPath)) {
    Write-Host "   Quinn not found — installing now...`n" -ForegroundColor Yellow
    
    if (Test-Path $installQuinnPath) {
        # Run Install-Quinn with SkipBringQuinn since we'll do that at the end
        & $installQuinnPath -QuinnRepoPath $QuinnRepoPath -Alias $Alias -SkipBringQuinn
    }
    else {
        # Fallback: clone Quinn directly
        Write-Host "📥 Cloning Quinn repository..." -ForegroundColor Gray
        $quinnRepoUrl = "https://github.com/alisonmaclellan/Quinn.git"
        
        $quinnParentDir = Split-Path $QuinnRepoPath -Parent
        if (-not (Test-Path $quinnParentDir)) {
            New-Item -ItemType Directory -Path $quinnParentDir -Force | Out-Null
        }
        
        git clone $quinnRepoUrl $QuinnRepoPath
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to install Quinn." -ForegroundColor Red
            return
        }
        Write-Host "✅ Quinn installed!`n" -ForegroundColor Green
    }
}
else {
    Write-Host "   ✅ Quinn is installed at: $QuinnRepoPath`n" -ForegroundColor Green
}

# Step 2: Clone the target repository
Write-Host "📋 Step 2: Cloning your repository..." -ForegroundColor Gray

# Extract repo name from URL if not provided
if (-not $RepoName) {
    $RepoName = [System.IO.Path]::GetFileNameWithoutExtension($RepoUrl.TrimEnd('/').Split('/')[-1])
}

# Build full target path
$fullTargetPath = Join-Path $TargetFolder $RepoName

# Check if target already exists
if (Test-Path $fullTargetPath) {
    Write-Host "⚠️  Folder already exists: $fullTargetPath" -ForegroundColor Yellow
    $response = Read-Host "   Continue anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "`n👋 No worries, catch you later!`n" -ForegroundColor Cyan
        return
    }
}

# Create target folder if needed
if (-not (Test-Path $TargetFolder)) {
    Write-Host "📁 Creating folder: $TargetFolder" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
}

# Clone the repository
Write-Host "📥 Cloning repository..." -ForegroundColor Gray
Write-Host "   From: $RepoUrl" -ForegroundColor Gray
Write-Host "   To:   $fullTargetPath`n" -ForegroundColor Gray

try {
    git clone $RepoUrl $fullTargetPath
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed with exit code $LASTEXITCODE"
    }
    Write-Host "`n✅ Repository cloned successfully!`n" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to clone repository: $_" -ForegroundColor Red
    return
}

# Run Bring-Quinn
if (-not $SkipBringQuinn) {
    Write-Host "📋 Step 3: Bringing Quinn to your new repo..." -ForegroundColor Gray
    
    $bringQuinnPath = Join-Path $QuinnRepoPath "scripts\Bring-Quinn.ps1"
    $sourcePath = Join-Path $QuinnRepoPath ".github\copilot-instructions.md"

    if (-not (Test-Path $bringQuinnPath)) {
        Write-Host "⚠️  Bring-Quinn.ps1 not found at: $bringQuinnPath" -ForegroundColor Yellow
        Write-Host "   Your repo is ready at: $fullTargetPath`n" -ForegroundColor White
        return
    }

    Push-Location $fullTargetPath
    & $bringQuinnPath -SourcePath $sourcePath -Alias $Alias
    Pop-Location
}
else {
    Write-Host "ℹ️  Skipped Bring-Quinn`n" -ForegroundColor Gray
}

# Final summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "`n📂 Your repo is ready at:" -ForegroundColor Cyan
Write-Host "   $fullTargetPath`n" -ForegroundColor White
Write-Host "   cd `"$fullTargetPath`"" -ForegroundColor Gray
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray
