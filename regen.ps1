#!/usr/bin/env pwsh
param(
    [switch]$Force
)

$CompDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "PwshCompletions"

if (-not (Test-Path $CompDir)) {
    New-Item -ItemType Directory -Path $CompDir | Out-Null
    Write-Host "Created completions directory: $CompDir" -ForegroundColor Green
}

$commands_completioncmd = @{
    "ast-grep" = "ast-grep completions powershell"
    "cargo" = @{
        command = "cargo +nightly"
        env = @{ CARGO_COMPLETE = "powershell" }
    }
    "gh" = "gh completion -s powershell"
    "gh-copilot" = @{
        check = "gh"
        command = "gh copilot alias pwsh"
    }
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
    $config = $commands_completioncmd[$cmd]
    $outputFile = "${CompDir}/_${cmd}.ps1"

    # Parse config (string or hashtable)
    if ($config -is [string]) {
        $checkCommand = $cmd
        $generateCommand = $config
        $envVars = @{}
        $skipCheck = $false
    } else {
        $checkCommand = if ($config.check) { $config.check } else { $cmd }
        $generateCommand = $config.command
        $envVars = if ($config.env) { $config.env } else { @{} }
        $skipCheck = if ($null -ne $config.skipCheck) { $config.skipCheck } else { $false }
    }

    # Check if command exists
    if (-not $skipCheck -and -not (Get-Command $checkCommand -ErrorAction SilentlyContinue)) {
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

        # Save and set environment variables
        $savedEnvVars = @{}
        foreach ($key in $envVars.Keys) {
            $savedEnvVars[$key] = [System.Environment]::GetEnvironmentVariable($key)
            [System.Environment]::SetEnvironmentVariable($key, $envVars[$key])
        }

        # Execute generation command
        $completionOutput = Invoke-Expression $generateCommand 2>&1

        # Restore environment variables
        foreach ($key in $savedEnvVars.Keys) {
            if ($null -eq $savedEnvVars[$key]) {
                Remove-Item "Env:\$key" -ErrorAction SilentlyContinue
            } else {
                [System.Environment]::SetEnvironmentVariable($key, $savedEnvVars[$key])
            }
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
