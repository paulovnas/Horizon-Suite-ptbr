# Migrate Open Items from pipeline.md to GitHub Issues.
# Run from repo root. Requires gh CLI (https://cli.github.com/).
# Run the Setup Labels workflow first, or scripts/setup-labels.ps1, to create labels.
# Usage: .\migrate-pipeline-to-issues.ps1 [ -Execute ]
# Without -Execute, prints gh commands. With -Execute, runs them.

param([switch]$Execute)

$pipelinePath = Join-Path $PSScriptRoot "..\pipeline.md"
$content = if (Test-Path $pipelinePath) {
    Get-Content $pipelinePath -Raw
} else {
    # pipeline.md was removed; try to read from git history
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
    Push-Location $repoRoot
    try {
        $c = $null
        foreach ($ref in @("HEAD", "HEAD^", "HEAD~2")) {
            $c = git show "${ref}:pipeline.md" 2>$null | Out-String
            if ($c) { break }
        }
        $c
    } finally {
        Pop-Location
    }
}

$openSection = $content -match '(?s)## Open Items\s*\n(.*?)\n---\s*\n\n## Closed'
if (-not $openSection) { Write-Error "Could not find Open Items section"; exit 1 }

$openBlock = $Matches[1]
$lines = $openBlock -split '\n' | Where-Object { $_.Trim() -match '^- `' }

$count = 0
foreach ($line in $lines) {
    if ($line -notmatch '^- `(BUG|FEAT|IMPR|IDEA|MOD|DOC)` OPEN \d{4}-\d{2}-\d{2} (\[P\d\])? ') { continue }

    $rest = $line -replace '^- `(BUG|FEAT|IMPR|IDEA|MOD|DOC)` OPEN \d{4}-\d{2}-\d{2} (\[P\d\])? ', ''
    $rest = $rest -replace '^`\[(Focus|Presence|Vista)\]` ', ''

    $tag = $Matches[1]
    $priority = if ($Matches[2]) { $Matches[2] -replace '\[|\]' } else { "P2" }
    $module = $null
    if ($line -match '`\[Focus\]`') { $module = "Focus" }
    elseif ($line -match '`\[Presence\]`') { $module = "Presence" }
    elseif ($line -match '`\[Vista\]`') { $module = "Vista" }

    $title = $rest.Trim() -replace '^`|`$', '' -replace '\. →.*$', ''
    if ($title.Length -gt 256) { $title = $title.Substring(0, 253) + "..." }

    # Map tag to GitHub label
    $typeLabel = switch ($tag) {
        "BUG" { "bug" }
        "FEAT" { "feature" }
        "MOD" { "feature" }
        "IMPR" { "improvement" }
        "IDEA" { "idea" }
        "DOC" { "improvement" }
        default { "feature" }
    }

    $labels = @($typeLabel)
    $labels += "priority:$priority"
    if ($module) { $labels += "module:$module" }

    $labelArg = ($labels | ForEach-Object { "--label `"$_`"" }) -join " "
    $body = "Migrated from pipeline.md (GitHub Issues workflow)"
    $titleEscaped = $title -replace '"', '\"'

    $cmd = "gh issue create --title `"$titleEscaped`" --body `"$body`" $labelArg"
    if ($Execute) {
        Invoke-Expression $cmd
        if ($LASTEXITCODE -ne 0) { Write-Warning "Failed: $cmd" }
    } else {
        Write-Host $cmd
    }
    $count++
}

Write-Host ""
if ($Execute) {
    Write-Host "Created $count issues."
} else {
    Write-Host "Total: $count issues. Run with -Execute to create them, or copy the commands above."
}
