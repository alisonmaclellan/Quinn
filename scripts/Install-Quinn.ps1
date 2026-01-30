<#
.SYNOPSIS
    Installs Quinn (your AI partner) by cloning the repo and bringing Quinn to a target project.

.DESCRIPTION
    This bootstrap script:
    1. Clones the Quinn Brand Kit repository to your specified directory
    2. Runs Bring-Quinn to copy the copilot instructions to your target repository

.PARAMETER QuinnRepoPath
    Where to clone the Quinn repository. Defaults to ~\source\repos\Quinn

.PARAMETER TargetRepoPath
    The repository where you want to bring Quinn. Defaults to current directory.

.PARAMETER RepoUrl
    The URL of the Quinn repository. Defaults to https://github.com/alisonmaclellan/Quinn.git

.PARAMETER Alias
    Your username/alias for the copilot-instructions folder. Defaults to $env:USERNAME

.PARAMETER SkipBringQuinn
    If set, only clones the repo without running Bring-Quinn

.EXAMPLE
    Install-Quinn
    
    Clones Quinn to the default location and brings Quinn to your current repo.

.EXAMPLE
    Install-Quinn -TargetRepoPath "C:\Projects\MyApp"
    
    Clones Quinn and brings her to the specified repository.

.EXAMPLE
    Install-Quinn -QuinnRepoPath "D:\Projects\Quinn"
    
    Clones Quinn to a custom location.

.EXAMPLE
    Install-Quinn -SkipBringQuinn
    
    Only clones the Quinn repo without copying instructions to any project.

.NOTES
    Run this from anywhere — just specify the target repo path if not in one.
#>

[CmdletBinding()]
param(
    [string]$QuinnRepoPath = (Join-Path $env:USERPROFILE "source\repos\Quinn"),
    [string]$TargetRepoPath = (Get-Location).Path,
    [string]$RepoUrl = "https://github.com/alisonmaclellan/Quinn.git",
    [string]$Alias = $env:USERNAME,
    [switch]$SkipBringQuinn
)

# Friendly greeting
Write-Host "`n✨ " -NoNewline
Write-Host "Install-Quinn" -ForegroundColor Magenta -NoNewline
Write-Host " ✨`n"

Write-Host "Hi! I'm Quinn — let's get me set up so we can work together! 🎉`n" -ForegroundColor Cyan

# Check if git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git is not installed or not in PATH." -ForegroundColor Red
    Write-Host "   Please install Git and try again.`n"
    return
}

# Check if Quinn repo already exists
if (Test-Path $QuinnRepoPath) {
    Write-Host "📁 Quinn repo already exists at: $QuinnRepoPath" -ForegroundColor Yellow
    
    $response = Read-Host "   Pull latest changes? (Y/n)"
    if ($response -eq '' -or $response -eq 'y' -or $response -eq 'Y') {
        Write-Host "`n🔄 Pulling latest changes..." -ForegroundColor Gray
        Push-Location $QuinnRepoPath
        try {
            git pull
            Write-Host "✅ Updated to latest version!`n" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Could not pull updates: $_`n" -ForegroundColor Yellow
        }
        Pop-Location
    }
}
else {
    # Create parent directory if needed
    $parentDir = Split-Path $QuinnRepoPath -Parent
    if (-not (Test-Path $parentDir)) {
        Write-Host "📁 Creating directory: $parentDir" -ForegroundColor Gray
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Clone the repository
    Write-Host "📥 Cloning Quinn repository..." -ForegroundColor Gray
    Write-Host "   From: $RepoUrl" -ForegroundColor Gray
    Write-Host "   To:   $QuinnRepoPath`n" -ForegroundColor Gray

    try {
        git clone $RepoUrl $QuinnRepoPath
        Write-Host "`n✅ Quinn repository cloned successfully!`n" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to clone repository: $_" -ForegroundColor Red
        return
    }
}

# Run Bring-Quinn if not skipped and target is a git repo
if (-not $SkipBringQuinn) {
    # Resolve to absolute path
    $TargetRepoPath = (Resolve-Path $TargetRepoPath -ErrorAction SilentlyContinue).Path
    if (-not $TargetRepoPath) {
        $TargetRepoPath = $PWD.Path
    }

    $targetGitPath = Join-Path $TargetRepoPath ".git"
    
    if (-not (Test-Path $targetGitPath)) {
        Write-Host "ℹ️  Target is not a git repository: $TargetRepoPath" -ForegroundColor Yellow
        Write-Host "   To bring Quinn to a project, run:`n" -ForegroundColor Gray
        Write-Host "   Install-Quinn -TargetRepoPath `"C:\Path\To\YourRepo`"`n" -ForegroundColor White
    }
    else {
        Write-Host "🚀 Running Bring-Quinn..." -ForegroundColor Gray
        Write-Host "   Target: $TargetRepoPath`n" -ForegroundColor Gray
        
        $bringQuinnPath = Join-Path $QuinnRepoPath "scripts\Bring-Quinn.ps1"
        $sourcePath = Join-Path $QuinnRepoPath ".github\copilot-instructions.md"
        
        if (Test-Path $bringQuinnPath) {
            # Run Bring-Quinn from the target repo directory
            Push-Location $TargetRepoPath
            & $bringQuinnPath -SourcePath $sourcePath -Alias $Alias
            Pop-Location
        }
        else {
            Write-Host "⚠️  Bring-Quinn.ps1 not found at: $bringQuinnPath" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "ℹ️  Skipped Bring-Quinn (use -SkipBringQuinn:`$false to enable)`n" -ForegroundColor Gray
}

# Show helpful next steps
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "`n📚 " -NoNewline
Write-Host "What's Next?" -ForegroundColor Cyan
Write-Host ""
Write-Host "   • Quinn repo is at: " -NoNewline
Write-Host $QuinnRepoPath -ForegroundColor White
Write-Host ""
Write-Host "   • To bring Quinn to another repo, run:" -ForegroundColor Gray
Write-Host "     Install-Quinn -TargetRepoPath `"C:\Path\To\YourRepo`"" -ForegroundColor White
Write-Host ""
Write-Host "   • Or use Bring-Quinn directly:" -ForegroundColor Gray
Write-Host "     & `"$QuinnRepoPath\scripts\Bring-Quinn.ps1`"" -ForegroundColor White
Write-Host ""
Write-Host "   • Add an alias to your PowerShell profile:" -ForegroundColor Gray
Write-Host "     Set-Alias -Name Bring-Quinn -Value `"$QuinnRepoPath\scripts\Bring-Quinn.ps1`"" -ForegroundColor White
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray

Write-Host "👋 Ready to spark some creativity together!`n" -ForegroundColor Cyan
