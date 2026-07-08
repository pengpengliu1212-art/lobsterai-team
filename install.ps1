# ========================================
# lobsterai-team installer for Windows
# Per ScriptRunner 2026 + ITU 2026 PowerShell best practice:
#   - Idempotent (check state before change)
#   - try-catch-finally for error handling
#   - Test-Path before New-Item
#   - Exit codes meaningful
# ========================================

[CmdletBinding()]
param(
    [string]$WorkspaceRoot = "H:\software-dev-Lob",
    [switch]$SkipDashboard,
    [switch]$SkipSkillLink,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$TEAM_ROOT = Join-Path $WorkspaceRoot "lobsterai-team"
$LOG_DIR = Join-Path $TEAM_ROOT "logs"
$DASHBOARD_DIR = Join-Path $TEAM_ROOT "dashboard"
$OPENCLAW_SKILLS_DIR = Join-Path $env:USERPROFILE ".openclaw\skills"
$BIN_DIR = Join-Path $TEAM_ROOT "bin"

function Step { param($msg) Write-Host "[lobsterai-team] $msg" -ForegroundColor Cyan }
function Ok { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Err { param($msg) Write-Host "[ERR] $msg" -ForegroundColor Red }

# State tracking (per This Is My Demo 2026 Get/Test/Set pattern)
$script:State = @{
    DockerInstalled = $false
    HDriveOK = $false
    TeamRootExists = $false
    SkillLinks = 0
}

# Get: read current state
function Get-LobsteraiTeamState {
    $script:State.DockerInstalled = [bool](Get-Command docker -ErrorAction SilentlyContinue)
    $script:State.HDriveOK = Test-Path $WorkspaceRoot
    $script:State.TeamRootExists = Test-Path $TEAM_ROOT
    $script:State.SkillLinks = 0
    if (Test-Path "$TEAM_ROOT\skills") {
        $script:State.SkillLinks = (Get-ChildItem "$TEAM_ROOT\skills" -Directory -ErrorAction SilentlyContinue).Count
    }
}

# Test: check if state matches desired
function Test-LobsteraiTeamReady {
    if (-not $script:State.DockerInstalled) { return $false }
    if (-not $script:State.HDriveOK) { return $false }
    if (-not $script:State.TeamRootExists) { return $false }
    return $true
}

$failed = $false
try {
    # === Step 1: Get + Test Docker ===
    Step "1/6 [Get] Checking current state..."
    Get-LobsteraiTeamState
    Ok "Docker installed: $($script:State.DockerInstalled)"
    Ok "Workspace exists: $($script:State.HDriveOK)"
    Ok "Team root exists: $($script:State.TeamRootExists)"
    Ok "Skill dirs: $($script:State.SkillLinks)"

    Step "2/6 [Test] Verifying Docker availability..."
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $docker) {
        Err "docker command not found. Install Docker Desktop first (H:\Docker)."
        $failed = $true
    } else {
        $dockerVersion = & docker version --format "{{.Server.Version}}" 2>$null
        if ([string]::IsNullOrEmpty($dockerVersion)) {
            Warn "Docker installed but daemon not running. Start Docker Desktop first."
        } else {
            Ok "Docker $dockerVersion"
        }
    }

    # === Step 3: Verify H drive space ===
    Step "3/6 Verifying H drive space..."
    if (Test-Path $WorkspaceRoot) {
        $h = Get-PSDrive (Split-Path $WorkspaceRoot -Qualifier).TrimEnd(':') -ErrorAction SilentlyContinue
        if ($h) {
            $freeGB = [math]::Round($h.Free / 1GB, 2)
            if ($freeGB -lt 5) {
                Warn "H drive has only $freeGB GB free (recommended: 5+ GB)"
            } else {
                Ok "H drive $freeGB GB free"
            }
        }
    } else {
        Err "Workspace root $WorkspaceRoot does not exist. Use -WorkspaceRoot to override."
        $failed = $true
    }

    # === Step 4: Set team root (idempotent) ===
    Step "4/6 [Set] Ensuring team root at $TEAM_ROOT..."
    if (-not (Test-Path $TEAM_ROOT)) {
        New-Item -ItemType Directory -Force -Path $TEAM_ROOT | Out-Null
        Ok "created $TEAM_ROOT"
    } else {
        Ok "team root already exists (no change needed)"
    }
    Get-LobsteraiTeamState  # refresh state

    # === Step 5: Ensure sub-directories ===
    Step "5/6 Ensuring lobsterai-team sub-directories..."
    foreach ($sub in @("skills", "dashboard", "bin", "playbooks", "logs")) {
        $path = Join-Path $TEAM_ROOT $sub
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Force -Path $path | Out-Null
            Ok "created $sub/"
        } else {
            Ok "$sub/ exists (no change needed)"
        }
    }

    # === Step 6: Link skills + start dashboard ===
    if (-not $SkipSkillLink) {
        Step "6/6 Linking skills to $OPENCLAW_SKILLS_DIR..."
        if (-not (Test-Path $OPENCLAW_SKILLS_DIR)) {
            try {
                New-Item -ItemType Directory -Force -Path $OPENCLAW_SKILLS_DIR | Out-Null
                Ok "created OpenClaw skills dir"
            } catch {
                Warn "could not create OpenClaw skills dir: $_"
            }
        }
        if (Test-Path "$TEAM_ROOT\skills") {
            Get-ChildItem "$TEAM_ROOT\skills" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $skillName = $_.Name
                $link = Join-Path $OPENCLAW_SKILLS_DIR $skillName
                if ((Test-Path $link) -and -not $Force) {
                    Ok "skill $skillName already linked (use -Force to re-link)"
                } else {
                    if (Test-Path $link) { Remove-Item $link -Force -Recurse -ErrorAction SilentlyContinue }
                    try {
                        New-Item -ItemType SymbolicLink -Path $link -Target $_.FullName | Out-Null
                        Ok "linked $skillName -> $link"
                    } catch {
                        Warn "could not link $skillName (run as admin or check permissions): $_"
                    }
                }
            }
        }
    } else {
        Step "6/6 Skipping skill linking (-SkipSkillLink)"
    }

    # === Final Test (post-install) ===
    Get-LobsteraiTeamState
    if (Test-LobsteraiTeamReady) {
        Ok "install verification: PASS"
    } else {
        Warn "install verification: PARTIAL (some steps failed or skipped)"
    }

    # === Summary ===
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "lobsterai-team install complete" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Team root: $TEAM_ROOT"
    Write-Host "OpenClaw skills: $OPENCLAW_SKILLS_DIR"
    Write-Host "Dashboard: http://127.0.0.1:8080"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  lobster-team version" -ForegroundColor Gray
    Write-Host "  lobster-team status" -ForegroundColor Gray
    Write-Host "  lobster-team run lobster-pm python3 --version" -ForegroundColor Gray
    Write-Host ""
} catch {
    Err "install failed: $_"
    $failed = $true
} finally {
    if ($failed) { exit 1 } else { exit 0 }
}
