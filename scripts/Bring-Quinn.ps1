<#
.SYNOPSIS
    Brings Quinn (your AI partner) to any repository!

.DESCRIPTION
    Copies the copilot-instructions.md file from your learnings repo
    to the current repository's .github folder.

.EXAMPLE
    Bring-Quinn
    
    Run this in any cloned repo to bring Quinn along for the journey.

.NOTES
    Add this to your PowerShell profile for easy access everywhere:
    Set-Alias -Name Bring-Quinn -Value "c:\Repos\learnings\scripts\Bring-Quinn.ps1"
#>

[CmdletBinding()]
param(
    [string]$SourcePath = "c:\Repos\learnings\.github\copilot-instructions.md",
    [string]$Alias = $env:USERNAME,
    [string]$TargetDir = ".github\copilot-instructions\$Alias"
)

# Friendly greeting
Write-Host "`n✨ " -NoNewline
Write-Host "Bring-Quinn" -ForegroundColor Cyan -NoNewline
Write-Host " ✨`n"

# Check if we're in a git repo
if (-not (Test-Path ".git")) {
    Write-Host "⚠️  This doesn't look like a git repository." -ForegroundColor Yellow
    Write-Host "   Run this from the root of a cloned repo.`n"
    return
}

# Check if source file exists
if (-not (Test-Path $SourcePath)) {
    Write-Host "❌ Can't find Quinn's instructions at:" -ForegroundColor Red
    Write-Host "   $SourcePath"
    Write-Host "`n   Make sure your learnings repo is cloned to c:\Repos\learnings`n"
    return
}

# Create .github/copilot-instructions/alisonm folder if it doesn't exist
$targetPath = Join-Path $TargetDir "quinn.md"

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Write-Host "📁 Created $TargetDir folder" -ForegroundColor Gray
}

# Check if file already exists
if (Test-Path $targetPath) {
    Write-Host "🤔 Quinn is already here! " -ForegroundColor Yellow -NoNewline
    
    $response = Read-Host "Overwrite with latest? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "`n👋 Keeping the existing file. See you around!`n" -ForegroundColor Cyan
        return
    }
}

# Copy the file
try {
    Copy-Item -Path $SourcePath -Destination $targetPath -Force
    Write-Host "✅ Quinn has arrived! " -ForegroundColor Green
    Write-Host "   Copied to: $targetPath`n"
    Write-Host "👋 Hi $Alias! Ready to think together whenever you are.`n" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Something went wrong: $_" -ForegroundColor Red
}
