# Stop lobsterai-team dashboard
$pidFile = "H:\software-dev-Lob\lobsterai-team\dashboard\dashboard.pid"
if (-not (Test-Path $pidFile)) {
    Write-Host "No dashboard running (no pid file)"
    exit 0
}
$pid = [int](Get-Content $pidFile -Raw -ErrorAction SilentlyContinue)
if ($pid -gt 0) {
    $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "Stopping dashboard (PID $pid)..."
        Stop-Process -Id $pid -Force
        Start-Sleep -Seconds 1
    }
}
Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
Write-Host "Dashboard stopped"
