#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Generates PowerShell completion scripts for various command-line tools.

.DESCRIPTION
    Regenerates PowerShell tab completion files for installed command-line tools
    and saves them to the local completions directory. The script automatically
    detects which tools are available and generates completions only for installed
    commands.

    Supports both simple command configurations (string) and advanced configurations
    (hashtable) that allow custom command validation, environment variables, and
    special handling.

    Generated completion files are saved to a platform-specific directory and
    can be loaded automatically in your PowerShell profile:
    - Windows: $env:LOCALAPPDATA\PwshCompletions
    - macOS/Linux: ~/.local/share/pwsh/completions

.PARAMETER Force
    Regenerates completion files even if they already exist. By default, the script
    skips commands that already have completion files to avoid unnecessary regeneration.

.EXAMPLE
    .\regen.ps1

    Generates completion files for all available commands that don't already have
    completion files.

.EXAMPLE
    .\regen.ps1 -Force

    Regenerates all completion files, overwriting existing ones.

.EXAMPLE
    .\regen.ps1 -Verbose

    Generates completions with detailed progress information about each command
    being processed.

.EXAMPLE
    .\regen.ps1 -WhatIf

    Shows what completion files would be generated without actually creating them.

.EXAMPLE
    .\regen.ps1 -Debug

    Generates completions with comprehensive debugging information including
    configuration parsing, environment variable handling, and command execution.

.EXAMPLE
    .\regen.ps1 -Force -Verbose

    Regenerates all completion files with detailed progress output.

.NOTES
    File Name      : regen.ps1
    Prerequisite   : PowerShell 7.0+

    Completion directory locations:
    - Windows:     $env:LOCALAPPDATA\PwshCompletions
    - macOS/Linux: ~/.local/share/pwsh/completions

    The script supports two configuration formats:

    Simple (string):
        "command-name" = "command --generate-completions"

    Advanced (hashtable):
        "command-name" = @{
            check = "base-command"              # Command to verify exists
            command = "command --completions"   # Command to generate completions
            env = @{ VAR = "value" }            # Environment variables to set
            skipCheck = $false                  # Skip command existence check
        }

.LINK
    https://github.com/kjanat/PwshCompletions

.OUTPUTS
    Completion files are written to platform-specific locations:
    - Windows:     $env:LOCALAPPDATA\PwshCompletions\_<command>.ps1
    - macOS/Linux: ~/.local/share/pwsh/completions/_<command>.ps1
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Force
)

# Determine completion directory based on platform
if ($IsWindows -or $null -eq $IsWindows) {
    # Windows or PowerShell < 6.0 (assumes Windows)
    $CompDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "PwshCompletions"
} elseif ($IsMacOS) {
    # macOS
    $CompDir = Join-Path -Path $HOME -ChildPath ".local/share/pwsh/completions"
} else {
    # Linux and other Unix-like systems
    $CompDir = Join-Path -Path $HOME -ChildPath ".local/share/pwsh/completions"
}

Write-Verbose "Platform: $($PSVersionTable.Platform ?? 'Windows (legacy)')"
Write-Verbose "Completion directory: $CompDir"

if (-not (Test-Path $CompDir)) {
    if ($PSCmdlet.ShouldProcess($CompDir, "Create completions directory")) {
        New-Item -ItemType Directory -Path $CompDir | Out-Null
        Write-Host "Created completions directory: $CompDir" -ForegroundColor Green
        Write-Verbose "Successfully created directory"
    }
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
    $outputFile = Join-Path -Path $CompDir -ChildPath "_${cmd}.ps1"

    Write-Debug "Processing command: $cmd"

    # Parse config (string or hashtable)
    if ($config -is [string]) {
        $checkCommand = $cmd
        $generateCommand = $config
        $envVars = @{}
        $skipCheck = $false
        Write-Debug "  Config type: string"
        Write-Debug "  Check command: $checkCommand"
        Write-Debug "  Generate command: $generateCommand"
    } else {
        $checkCommand = if ($config.check) { $config.check } else { $cmd }
        $generateCommand = $config.command
        $envVars = if ($config.env) { $config.env } else { @{} }
        $skipCheck = if ($null -ne $config.skipCheck) { $config.skipCheck } else { $false }
        Write-Debug "  Config type: hashtable"
        Write-Debug "  Check command: $checkCommand"
        Write-Debug "  Generate command: $generateCommand"
        Write-Debug "  Environment variables: $($envVars.Count)"
        Write-Debug "  Skip check: $skipCheck"
    }

    # Check if command exists
    if (-not $skipCheck -and -not (Get-Command $checkCommand -ErrorAction SilentlyContinue)) {
        Write-Host "  [SKIP] $cmd - command not found" -ForegroundColor Yellow
        Write-Verbose "Skipping $cmd - command '$checkCommand' not found"
        $skippedCount++
        continue
    }

    # Skip if file exists and -Force not specified
    if ((Test-Path $outputFile) -and -not $Force) {
        Write-Host "  [SKIP] $cmd - file exists (use -Force to regenerate)" -ForegroundColor Gray
        Write-Verbose "Skipping $cmd - file exists at $outputFile"
        $skippedCount++
        continue
    }

    # Generate completion
    if ($PSCmdlet.ShouldProcess($outputFile, "Generate completion for '$cmd'")) {
        try {
            Write-Host "  [GEN]  $cmd..." -ForegroundColor Cyan -NoNewline
            Write-Verbose "Generating completion for $cmd to $outputFile"

            # Save and set environment variables
            $savedEnvVars = @{}
            foreach ($key in $envVars.Keys) {
                $savedEnvVars[$key] = [System.Environment]::GetEnvironmentVariable($key)
                Write-Debug "  Setting env var: $key = $($envVars[$key])"
                [System.Environment]::SetEnvironmentVariable($key, $envVars[$key])
            }

            # Execute generation command
            Write-Debug "  Executing: $generateCommand"
            $completionOutput = Invoke-Expression $generateCommand 2>&1

            # Restore environment variables
            foreach ($key in $savedEnvVars.Keys) {
                if ($null -eq $savedEnvVars[$key]) {
                    Write-Debug "  Removing env var: $key"
                    Remove-Item "Env:\$key" -ErrorAction SilentlyContinue
                } else {
                    Write-Debug "  Restoring env var: $key = $($savedEnvVars[$key])"
                    [System.Environment]::SetEnvironmentVariable($key, $savedEnvVars[$key])
                }
            }

            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                throw "Command exited with code $LASTEXITCODE"
            }

            # Write with UTF-8 encoding
            Write-Verbose "Writing completion output to file"
            $completionOutput | Out-File -FilePath $outputFile -Encoding UTF8 -Force

            Write-Host " OK" -ForegroundColor Green
            Write-Verbose "Successfully generated completion for $cmd"
            $successCount++
        }
        catch {
            Write-Host " FAILED" -ForegroundColor Red
            Write-Host "         Error: $_" -ForegroundColor Red
            Write-Verbose "Failed to generate completion for $cmd : $_"
            Write-Debug "Exception: $($_.Exception.GetType().FullName)"
            Write-Debug "Stack trace: $($_.ScriptStackTrace)"
            $failedCount++
        }
    } else {
        Write-Verbose "Skipped $cmd due to -WhatIf"
        $skippedCount++
    }
}

# Summary
Write-Host "`n" + ("=" * 50) -ForegroundColor Gray
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Generated: $successCount" -ForegroundColor Green
Write-Host "  Skipped:   $skippedCount" -ForegroundColor Yellow
Write-Host "  Failed:    $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Gray" })
Write-Host ("=" * 50) -ForegroundColor Gray

Write-Verbose "Total commands processed: $($commands_completioncmd.Count)"
Write-Verbose "Generation complete - Generated: $successCount, Skipped: $skippedCount, Failed: $failedCount"

if ($successCount -gt 0) {
    Write-Host "`nRestart your PowerShell session to load the new completions." -ForegroundColor Cyan
}
