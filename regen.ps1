#!/usr/bin/env pwsh
param(
    [switch]$Force
)

$CompDir = "$env:LOCALAPPDATA/PwshCompletions"
if (-not (Test-Path $CompDir)) {
    New-Item -ItemType Directory -Path $CompDir | Out-Null
    Write-Host "Created completions directory: $CompDir" -ForegroundColor Green
}

$commands_completioncmd = @{
    "ast-grep" = "ast-grep completions powershell"
    "cargo" = "cargo +nightly"  # Requires CARGO_COMPLETE='powershell' env var
    "gh" = "gh completion -s powershell"
    "gh-copilot" = "gh copilot alias pwsh"
    "golangci-lint" = "golangci-lint completion powershell"
    "pnpm" = "pnpm completion pwsh"
    "ruff" = "ruff generate-shell-completion powershell"
    "rustup" = "rustup completions powershell"
    "ty" = "ty generate-shell-completion powershell"
    "uv" = "uv generate-shell-completion powershell"
    "uvx" = "uvx --generate-shell-completion powershell"
    "volta" = "volta completions powershell"
}

Write-Host "`nRegenerating PowerShell completions..." -ForegroundColor Cyan
Write-Host "Target directory: $CompDir`n" -ForegroundColor Gray

$successCount = 0
$skippedCount = 0
$failedCount = 0

foreach ($cmd in $commands_completioncmd.Keys) {
    $completionCmd = $commands_completioncmd[$cmd]
    $outputFile = "${CompDir}/_${cmd}.ps1"

    # Check if command exists
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "  [SKIP] $cmd - command not found" -ForegroundColor Yellow
        $skippedCount++
        continue
    }

    # Skip if file exists and -Force not specified
    if ((Test-Path $outputFile) -and -not $Force) {
        Write-Host "  [SKIP] $cmd - file exists (use -Force to regenerate)" -ForegroundColor Gray
        $skippedCount++
        continue
    }

    # Generate completion
    try {
        Write-Host "  [GEN]  $cmd..." -ForegroundColor Cyan -NoNewline

        # Special handling for cargo - requires CARGO_COMPLETE env var
        if ($cmd -eq "cargo") {
            $prevCargoComplete = $env:CARGO_COMPLETE
            $env:CARGO_COMPLETE = 'powershell'
            $completionOutput = Invoke-Expression $completionCmd 2>&1
            if ($null -eq $prevCargoComplete) {
                Remove-Item Env:\CARGO_COMPLETE -ErrorAction SilentlyContinue
            } else {
                $env:CARGO_COMPLETE = $prevCargoComplete
            }
        } else {
            $completionOutput = Invoke-Expression $completionCmd 2>&1
        }

        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            throw "Command exited with code $LASTEXITCODE"
        }

        # Write with UTF-8 encoding
        $completionOutput | Out-File -FilePath $outputFile -Encoding UTF8 -Force

        Write-Host " OK" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "         Error: $_" -ForegroundColor Red
        $failedCount++
    }
}

# Summary
Write-Host "`n" + ("=" * 50) -ForegroundColor Gray
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Generated: $successCount" -ForegroundColor Green
Write-Host "  Skipped:   $skippedCount" -ForegroundColor Yellow
Write-Host "  Failed:    $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Gray" })
Write-Host ("=" * 50) -ForegroundColor Gray

if ($successCount -gt 0) {
    Write-Host "`nRestart your PowerShell session to load the new completions." -ForegroundColor Cyan
}
