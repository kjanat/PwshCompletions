# https://learn.microsoft.com/en-us/windows/package-manager/winget/show?source=recommendations
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# if (Get-Command winget -ErrorAction SilentlyContinue) {
#     Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
#         param(, , )
#         [Console]::InputEncoding = [Console]::OutputEncoding = System.Text.UTF8Encoding = [System.Text.Utf8Encoding]::new()
#          = .Replace('"', '""')
#          = .ToString().Replace('"', '""')
#         winget complete --word="" --commandline "" --position  | ForEach-Object {
#             [System.Management.Automation.CompletionResult]::new(, , 'ParameterValue', )
#         }
#     }
# }
