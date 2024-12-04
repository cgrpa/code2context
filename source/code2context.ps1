# Define the ignore file path
$IGNORE_FILE = "$HOME\.code2contextignore"

function Read-IgnorePatterns {
    if (Test-Path $IGNORE_FILE) {
        # Read the ignore patterns, ignoring comments
        Get-Content $IGNORE_FILE | Where-Object { -not ($_ -match '^#') -and ($_ -ne '') }
    } else {
        @()
    }
}

function Output-FileContent {
    param (
        [string]$FilePath,
        [string[]]$IgnorePatterns
    )

    # Get the relative path of the file
    $RelativePath = $FilePath -replace '^\./', ''

    # Check if the file should be ignored
    foreach ($pattern in $IgnorePatterns) {
        if ($RelativePath -like "$pattern" -or $RelativePath -like "$pattern\*") {
            return # Skip this file if it matches the ignore pattern
        }
    }

    # If not ignored, output the file information in the specified format
    Write-Output "**$RelativePath**"
    Write-Output '```'
    try {
        Get-Content $FilePath | ForEach-Object { Write-Output $_ }
    } catch {
        Write-Output "Error: Unable to read $FilePath"
    }
    Write-Output '```'
    Write-Output ''
}

function Copy-ToClipboard {
    param (
        [string]$Content
    )

    if (Get-Command "Set-Clipboard" -ErrorAction SilentlyContinue) {
        Set-Clipboard -Value $Content
    } else {
        Write-Warning "No clipboard utility found. Outputting to console."
        Write-Output $Content
    }
}

function Main {
    param (
        [string]$Directory = '.'
    )

    $IgnorePatterns = Read-IgnorePatterns

    # Get all files in the directory and process each one
    $Output = Get-ChildItem -Path $Directory -Recurse -File | ForEach-Object {
        Output-FileContent -FilePath $_.FullName -IgnorePatterns $IgnorePatterns
    } | Out-String

    # Copy the content to the clipboard
    Copy-ToClipboard -Content $Output

    Write-Output "Content copied to clipboard. Use Ctrl+V to paste."
}

Main -Directory $args[0]
