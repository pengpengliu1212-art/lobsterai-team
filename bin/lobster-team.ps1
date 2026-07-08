# ========================================
# lobsterai-team CLI entry point (Windows PowerShell)
# Delegates to Python core (argparse, zero deps)
# Per ScriptRunner 2026 PowerShell best practice: $ErrorActionPreference
# ========================================

$ErrorActionPreference = "Stop"

# Resolve our actual location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TeamRoot = Split-Path -Parent $ScriptDir
$PythonCore = Join-Path $TeamRoot "bin\lobster_team\__main__.py"

# Pick Python
$Python = $null
foreach ($c in @("python3", "python", "py")) {
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if ($cmd) { $Python = $cmd.Source; break }
}

if (-not $Python) {
    Write-Error "[lobster-team] python3 not found in PATH. Install Python 3.8+ first."
    exit 1
}

# Verify Python core exists
if (-not (Test-Path $PythonCore)) {
    Write-Error "[lobster-team] Python core not found at $PythonCore"
    exit 1
}

# Run (-u = unbuffered; on CI runners Python buffers stderr/stdout,
# so error output may not reach the parent before the wrapper exits.
# Use -u to flush immediately so callers like CI tests can capture output.)
& $Python -u $PythonCore @args
exit $LASTEXITCODE
