# Create GitHub labels for Horizon Suite. Requires gh CLI (https://cli.github.com/).
# Alternatively, run the Setup Labels workflow from GitHub Actions tab.

$labels = @(
    @{ name = "bug"; desc = "Defect / broken behavior"; color = "d73a4a" },
    @{ name = "feature"; desc = "New capability"; color = "a2eeef" },
    @{ name = "improvement"; desc = "Enhancement to existing functionality"; color = "84b6eb" },
    @{ name = "idea"; desc = "Speculative / backlog"; color = "fef2c0" },
    @{ name = "module:Focus"; desc = "Focus tracker module"; color = "1d76db" },
    @{ name = "module:Presence"; desc = "Presence notification module"; color = "1d76db" },
    @{ name = "module:Core"; desc = "Core addon / options / general"; color = "1d76db" },
    @{ name = "module:Vista"; desc = "Vista / minimap module"; color = "1d76db" },
    @{ name = "module:Yield"; desc = "Yield / loot module"; color = "1d76db" },
    @{ name = "module:Pulse"; desc = "Pulse / combat module"; color = "1d76db" },
    @{ name = "module:Essence"; desc = "Essence / unit frames module"; color = "1d76db" },
    @{ name = "module:Insight"; desc = "Insight / tooltips module"; color = "1d76db" },
    @{ name = "module:Verse"; desc = "Verse / chat module"; color = "1d76db" },
    @{ name = "priority:P0"; desc = "Major / blocking"; color = "b60205" },
    @{ name = "priority:P1"; desc = "Minor / next"; color = "fbca04" },
    @{ name = "priority:P2"; desc = "Patch / low"; color = "0e8a16" }
)

foreach ($l in $labels) {
    gh label create $l.name --description $l.desc --color $l.color 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Host "Created: $($l.name)" } else { Write-Host "Skipped (exists): $($l.name)" }
}
