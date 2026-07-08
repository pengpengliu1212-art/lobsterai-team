# Start lobsterai-team dashboard in background
$ErrorActionPreference = "Stop"
$dashboardDir = "H:\software-dev-Lob\lobsterai-team\dashboard"
$pythonExe = "python"  # Assumes python on PATH

# Check if already running
$pidFile = "$dashboardDir\dashboard.pid"
if (Test-Path $pidFile) {
    $oldPid = [int](Get-Content $pidFile -Raw -ErrorAction SilentlyContinue)
    if ($oldPid -gt 0) {
        $proc = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "Dashboard already running with PID $oldPid"
            Write-Host "  Stop with: .\stop-dashboard.ps1"
            exit 0
        }
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

# Start Python server
Set-Location $dashboardDir
$logFile = "$dashboardDir\dashboard.log"
Write-Host "Starting lobsterai-team dashboard..."
Write-Host "  Log: $logFile"
Write-Host "  URL: http://127.0.0.1:8080/"

$proc = Start-Process -FilePath $pythonExe -ArgumentList "server.py" `
    -WorkingDirectory $dashboardDir `
    -RedirectStandardOutput $logFile `
    -RedirectStandardError "$logFile.err" `
    -WindowStyle Hidden `
    -PassThru

Start-Sleep -Seconds 2
$running = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "  Started: PID $($proc.Id)"
    Write-Host "  Open in browser: http://127.0.0.1:8080/"
} else {
    Write-Host "  FAILED to start. Check log:"
    Get-Content $logFile | Select-Object -First 20
    exit 1
}
