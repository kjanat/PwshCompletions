#!/usr/bin/env pwsh

$CompDir = "$env:LOCALAPPDATA/PwshCompletions"
if (-not (Test-Path $CompDir)) {
    New-Item -ItemType Directory -Path $CompDir | Out-Null
}

# $env:CARGO_COMPLETE='powershell'; cargo +nightly | Out-String | Invoke-Expression

$commands_completioncmd = @{
    "ast-grep" = "ast-grep completions powershell"
    "gh" = "gh completion -s powershell"
    "gh-copilot" = "gh copilot alias pwsh"
    "golangci-lint" = "golangci-lint completion powershell"
    "pnpm" = "pnpm completion pwsh"
    "ruff" = "ruff generate-shell-completion powershell"
    "uv" = "uv generate-shell-completion powershell"
    "uvx" = "uvx --generate-shell-completion powershell"
    "volta" = "volta completions powershell"
    # "winget" = "$null" # https://learn.microsoft.com/en-us/windows/package-manager/winget/tab-completion
}

foreach ($cmd in $commands_completioncmd.Keys) {
    $completion_cmd = $commands_completioncmd[$cmd]
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        if ($completion_cmd -ne $null) {
            & $completion_cmd > "${CompDir}/_${cmd}.ps1"
        }
    }
}

foreach ($cmd in $commands_completioncmd.Keys) {
    $completionCommand = $commands_completioncmd[$cmd]
    if ($completionCommand -ne '$null') {
        Invoke-Expression (& $completionCommand)
    }
}

# # gh completions powershell
# gh completion -s powershell > "${CompDir}/_gh.ps1"

# # ast-grep completions
# ast-grep completions > "${CompDir}/_ast-grep.ps1"
# # volta completions powershell
