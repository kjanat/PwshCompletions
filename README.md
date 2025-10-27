# PwshCompletions

A PowerShell script to automatically generate and manage tab completion files for various command-line tools.

## Features

✨ **Automatic Generation** - Generates completion scripts for all installed tools  
🔄 **Smart Updates** - Only regenerates when needed (use `-Force` to override)  
🌍 **Cross-Platform** - Works on Windows, macOS, and Linux  
🛠️ **Advanced Configuration** - Supports simple and complex command configurations  
📋 **Professional CLI** - Full support for `-WhatIf`, `-Confirm`, `-Verbose`, and `-Debug`  
🎯 **Flexible** - Easy to add new tools to the configuration

## Installation

### 1. Clone or Download

```powershell
# Clone the repository
git clone https://github.com/kjanat/PwshCompletions.git

# Or download and extract to your preferred location
```

### 2. Configure Your Profile

Add the following to your PowerShell profile (`$PROFILE`):

**Windows:**

```powershell
$CompDir = "$env:LOCALAPPDATA\PwshCompletions"

Get-ChildItem $CompDir -Filter '*.ps1' -ErrorAction SilentlyContinue | ForEach-Object {
    $moduleName = $_.BaseName
    if (!(Get-Module -Name $moduleName -ErrorAction SilentlyContinue)) {
        Import-Module -Name $_.FullName -ErrorAction SilentlyContinue
    }
}
```

**macOS/Linux:**

```powershell
$CompDir = "$HOME/.local/share/pwsh/completions"

Get-ChildItem $CompDir -Filter '*.ps1' -ErrorAction SilentlyContinue | ForEach-Object {
    $moduleName = $_.BaseName
    if (!(Get-Module -Name $moduleName -ErrorAction SilentlyContinue)) {
        Import-Module -Name $_.FullName -ErrorAction SilentlyContinue
    }
}
```

### 3. Generate Completions

```powershell
cd PwshCompletions
./regen.ps1
```

### 4. Restart PowerShell

Restart your PowerShell session to load the newly generated completions.

## Usage

### Basic Usage

```powershell
# Generate completions for all available tools
./regen.ps1

# Regenerate all completions (overwrite existing)
./regen.ps1 -Force

# Preview what would be generated without creating files
./regen.ps1 -WhatIf

# Generate with detailed progress information
./regen.ps1 -Verbose

# Generate with comprehensive debugging output
./regen.ps1 -Debug
```

### Getting Help

```powershell
# View full documentation
Get-Help ./regen.ps1 -Full

# View examples only
Get-Help ./regen.ps1 -Examples

# View parameter help
Get-Help ./regen.ps1 -Parameter Force
```

## Supported Tools

Currently configured tools:

- **ast-grep** - Code searching and rewriting tool
- **cargo** - Rust package manager (requires nightly toolchain)
- **gh** - GitHub CLI
- **gh-copilot** - GitHub Copilot CLI
- **golangci-lint** - Go linter aggregator
- **pnpm** - Fast, disk space efficient package manager
- **ruff** - Fast Python linter
- **rustup** - Rust toolchain installer
- **ty** - Typing test tool
- **uv** - Fast Python package installer
- **uvx** - Python tool runner
- **volta** - JavaScript toolchain manager

## Adding New Tools

### Simple Configuration

For tools with straightforward completion generation:

```powershell
$commands_completioncmd = @{
    "tool-name" = "tool-name --generate-completions powershell"
}
```

### Advanced Configuration

For tools requiring special handling:

```powershell
$commands_completioncmd = @{
    "tool-name" = @{
        check = "base-command"              # Command to verify exists
        command = "tool-name --completions" # Command to generate completions
        env = @{ VAR = "value" }            # Environment variables to set
        skipCheck = $false                  # Skip command existence check
    }
}
```

### Examples

**Simple:**

```powershell
"ruff" = "ruff generate-shell-completion powershell"
```

**With environment variable:**

```powershell
"cargo" = @{
    command = "cargo +nightly"
    env = @{ CARGO_COMPLETE = "powershell" }
}
```

**With custom validation:**

```powershell
"gh-copilot" = @{
    check = "gh"                      # Checks if 'gh' exists
    command = "gh copilot alias pwsh" # Runs this command
}
```

## Platform-Specific Paths

### Windows

- Completions: `%LOCALAPPDATA%\PwshCompletions`
- Example: `C:\Users\YourName\AppData\Local\PwshCompletions`

### macOS/Linux

- Completions: `~/.local/share/pwsh/completions`
- Example: `/home/username/.local/share/pwsh/completions`

## How It Works

1. **Detection** - Script checks if each configured command is installed
2. **Validation** - Verifies command existence (can be customized per tool)
3. **Environment Setup** - Sets required environment variables if specified
4. **Generation** - Executes the completion generation command
5. **Cleanup** - Restores original environment state
6. **Output** - Saves completion script to platform-specific directory

## Troubleshooting

### Completions Not Loading

1. **Verify files exist:**

   ```powershell
   # Windows
   ls $env:LOCALAPPDATA\PwshCompletions

   # macOS/Linux
   ls ~/.local/share/pwsh/completions
   ```

2. **Check your profile is loading them:**

   ```powershell
   # View your profile
   code $PROFILE

   # Test profile loading
   . $PROFILE
   ```

3. **Regenerate with verbose output:**

   ```powershell
   ./regen.ps1 -Force -Verbose
   ```

### Command Not Found

If a tool shows as "command not found":

1. **Verify installation:**

   ```powershell
   Get-Command tool-name
   ```

2. **Check PATH:**

   ```powershell
   $env:PATH -split [IO.Path]::PathSeparator
   ```

3. **Install the tool** and regenerate:

   ```powershell
   ./regen.ps1 -Force
   ```

### Debugging Issues

Use the debug flag for comprehensive diagnostics:

```powershell
./regen.ps1 -Debug
```

This shows:

- Configuration parsing details
- Command detection logic
- Environment variable operations
- Execution commands
- Exception details and stack traces

## Requirements

- **PowerShell 7.0+** (recommended)
- **PowerShell 5.1** (Windows only, limited features)
- The actual command-line tools you want completions for

## Contributing

Contributions are welcome! To add a new tool:

1. Fork the repository
2. Add your tool to the `$commands_completioncmd` hashtable in `regen.ps1`
3. Test the completion generation
4. Submit a pull request

### Contribution Guidelines

- Test on multiple platforms if possible (Windows, macOS, Linux)
- Use simple string format when possible
- Use hashtable format only when needed (env vars, custom validation)
- Add a comment if the configuration is non-obvious
- Ensure the completion command is documented by the tool's project

## License

[MIT License](./LICENSE)

## Acknowledgments

- Thanks to all the tool maintainers who provide native completion support
- Inspired by the need for consistent completion management across tools

## FAQ

**Q: Why use this instead of each tool's individual completion setup?**  
A: Centralized management, consistent regeneration, and easier profile setup.

**Q: Does this work with PowerShell 5.1?**  
A: Yes, on Windows. Some features (platform detection) require PowerShell 7+.

**Q: Can I customize the completion directory?**  
A: Currently it uses platform defaults. You can modify `$CompDir` in the script.

**Q: How do I update completions after tool updates?**  
A: Run `./regen.ps1 -Force` to regenerate all completions.

**Q: Why does `-Debug` ask for confirmation?**  
A: PowerShell's `ShouldProcess` behavior. Use `-Confirm:$false` to bypass.

**Q: Can I add custom completions not in the default list?**  
A: Yes! Edit the `$commands_completioncmd` hashtable in `regen.ps1`.

## Support

- **Issues:** [GitHub Issues](https://github.com/kjanat/PwshCompletions/issues)

<!-- - **Discussions:** [GitHub Discussions](https://github.com/kjanat/PwshCompletions/discussions) -->
